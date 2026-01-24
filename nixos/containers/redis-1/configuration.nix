{ ... }:

{
  imports = [
    ../../modules/platform/proxmox-lxc.nix

    ../../modules/base/defaults.nix
    ../../modules/base/nix.nix
    ../../modules/base/sops-common.nix
    ../../modules/base/ssh.nix
    ../../modules/base/users.nix
  ];

  # Example service
  services.redis.servers.default.enable = true;
}
