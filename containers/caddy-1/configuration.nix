{ lib, ... }:

{
  imports = [
    # Platform
    ../../modules/platform/proxmox-lxc.nix

    # Base system
    ../../modules/base/defaults.nix
    ../../modules/base/firewall.nix
    ../../modules/base/nix.nix
    ../../modules/base/sops-common.nix
    ../../modules/base/ssh.nix
    ../../modules/base/users.nix

    # Networking profile
    ../../modules/profiles/static-ip.nix

    # Roles
    ../../modules/roles/caddy.nix

    # Container secrets
    ./secrets.nix
  ];

  ### ---- REQUIRED PER CONTAINER ----

  # Static IP configuration
  my.networking.staticIPv4 = {
    enable = true;
    address = "10.0.0.80";
    gateway = "10.0.0.1";
  };
}

