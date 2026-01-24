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
    ../../modules/roles/pihole.nix

    # Container secrets
    ./secrets.nix
  ];

  ### ---- REQUIRED PER CONTAINER ----

  # Static IP configuration
  my.networking.staticIPv4 = {
    enable = true;
    address = "10.0.0.53";
    gateway = "10.0.0.1";
  };

  # Optional DNS override (if not provided by DHCP/router)
  # my.networking.dns = [ "1.1.1.1" "9.9.9.9" ];

  ### ---- OPTIONAL PER CONTAINER ----

  # Firewall ports are configured in the pi-hole role module
  # DNS: 53 (UDP/TCP), Web: 80, 443

  # Extra system packages
  # environment.systemPackages = with pkgs; [ htop ];
}

