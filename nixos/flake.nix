{
  description = "Composable NixOS Proxmox VMs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixos-generators.url = "github:nix-community/nixos-generators";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-generators,
      sops-nix,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;

      # Read ./hosts directory
      hostsDir = builtins.readDir ./hosts;

      # Keep only directories
      hostNames = builtins.attrNames (lib.filterAttrs (_: type: type == "directory") hostsDir);

      defaultProxmox = {
        cores = 1;
        memory = 1024;
        diskSize = 10 * 1024;
        tags = [ "nixos" ];
        net = {
          model = "virtio";
          bridge = "vmbr0";
        };
      };

      readProxmoxMeta =
        name:
        let
          path = ./hosts/${name}/proxmox.nix;
        in
        if builtins.pathExists path then defaultProxmox // import path else defaultProxmox;

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

    in
    {
      # ---- NixOS configurations (nixos-rebuild, remote updates)
      nixosConfigurations = lib.genAttrs hostNames mkHost;

      # ---- Proxmox images (nixos-generators)
      packages.${system} = lib.genAttrs hostNames (
        name:
        let
          meta = readProxmoxMeta name;
        in
        nixos-generators.nixosGenerate {
          inherit system;
          specialArgs = { inherit inputs; };
          format = "proxmox";
          modules = [
            {
              networking.hostName = name;
              virtualisation.diskSize = meta.diskSize;
            }
            ./hosts/${name}/configuration.nix
          ];

          # proxmox = {
          #   inherit (meta) cores memory;
          #   name = meta.name or name;
          #   net0 = "model=${meta.net.model},bridge=${meta.net.bridge}";
          #   tags = lib.concatStringsSep ";" meta.tags;
          # };
        }
      );
    };
}
