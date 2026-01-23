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

      # Helper to read proxmox.nix data file
      readProxmox =
        name:
        let
          path = ./hosts/${name}/proxmox.nix;
        in
        if builtins.pathExists path then import path else { };

    in
    {
      # ---- NixOS configurations (nixos-rebuild, remote updates)
      nixosConfigurations = lib.genAttrs hostNames mkHost;

      # ---- Proxmox images (nixos-generators)
      packages.${system} = lib.genAttrs hostNames (
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
      );

      # ---- deploy-rs definitions
      deploy.nodes = lib.genAttrs hostNames (
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
      );

      # ---- proxmox VM metadata
      proxmox = lib.genAttrs hostNames (name: readProxmox name);
    };
}
