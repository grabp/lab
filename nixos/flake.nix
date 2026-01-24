{
  description = "Composable NixOS Proxmox VMs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs.url = "github:serokell/deploy-rs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-generators,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;

      # ------ Hosts (VMs)

      # Read ./hosts directory
      hostsDir = builtins.readDir ./hosts;

      # Keep only directories except for template/
      hostNames = lib.attrNames (
        lib.filterAttrs (name: type: type == "directory" && name != "template") hostsDir
      );

      # Helper to build a nixosSystem for a host
      mkHost =
        name:
        lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };

          modules = [
            ./hosts/${name}/configuration.nix
          ];
        };

      readHostProxmoxMeta =
        name:
        let
          path = ./hosts/${name}/proxmox.nix;
        in
        if builtins.pathExists path then import path else { };

      # ------ Containers (LXC)

      containersDir = builtins.readDir ./containers;

      containerNames = lib.attrNames (lib.filterAttrs (name: type: type == "directory") containersDir);

      # Helper to build a nixosSystem for a host
      mkContainer =
        name:
        lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };

          modules = [
            ./containers/${name}/configuration.nix
          ];
        };

      readContainerProxmoxMeta =
        name:
        let
          path = ./containers/${name}/proxmox.nix;
        in
        if builtins.pathExists path then import path else { };

    in
    {
      # ---- NixOS configurations (nixos-rebuild, remote updates)
      nixosConfigurations = (lib.genAttrs hostNames mkHost) // (lib.genAttrs containerNames mkContainer);

      # ---- Proxmox images (nixos-generators)
      packages.${system} =
        lib.genAttrs hostNames (
          name:
          nixos-generators.nixosGenerate {
            inherit system;
            specialArgs = { inherit inputs; };
            format = "proxmox";
            modules = [
              {
                networking.hostName = name;
              }
              ./hosts/${name}/configuration.nix
            ];
          }
        )
        // lib.genAttrs containerNames (
          name:
          nixos-generators.nixosGenerate {
            inherit system;
            format = "proxmox-lxc";
            specialArgs = { inherit inputs; };
            modules = [
              {
                networking.hostName = name;
              }
              ./containers/${name}/configuration.nix
            ];
          }
        );

      # ---- deploy-rs definitions
      deploy.nodes =
        lib.genAttrs hostNames (
          name:
          let
            cfg = self.nixosConfigurations.${name}.config;
            ip = cfg.my.networking.staticIPv4.address or name; # fallback (DHCP / DNS)
          in
          {
            hostname = ip;
            sshUser = "ops";

            profiles.system = {
              user = "root";
              path = inputs.deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.${name};
            };
          }
        )
        // lib.genAttrs containerNames (
          name:
          let
            px = self.proxmox.${name};
            ip = px.net0.ip or (throw "Container ${name} has no net0.ip defined");
            toplevel = self.nixosConfigurations.${name}.config.system.build.toplevel;
          in
          {
            hostname = ip;
            sshUser = "ops";

            profiles.system = {
              user = "root";
              path =
                inputs.deploy-rs.lib.${system}.activate.custom toplevel
                  "${toplevel}/bin/switch-to-configuration switch";
              activation.wait = false;
            };
          }
        );

      # ---- proxmox VM metadata
      proxmox =
        lib.genAttrs hostNames (name: readHostProxmoxMeta name)
        // lib.genAttrs containerNames (name: readContainerProxmoxMeta name);
    };
}
