{ lib, ... }:

{
  imports = [
    # Platform
    ../../modules/platform/proxmox.nix

    # Base system
    ../../modules/base/defaults.nix
    ../../modules/base/firewall.nix
    ../../modules/base/nix.nix
    ../../modules/base/sops-common.nix
    ../../modules/base/ssh.nix
    ../../modules/base/users.nix

    # Networking profile (choose ONE)
    ../../modules/profiles/static-ip.nix
    # ../../modules/profiles/dhcp.nix

    # Host secrets
    ./secrets.nix
  ];

  ### ---- REQUIRED PER HOST ----

  # Static IP example
  my.networking.staticIPv4 = {
    enable = true;
    address = "CHANGEME";
    gateway = "CHANGEME";
  };

  # Optional DNS override
  # my.networking.dns = [ "1.1.1.1" "9.9.9.9" ];

  ### ---- OPTIONAL PER HOST ----

  # Add host-specific firewall ports
  # my.firewall.extraTCPPorts = [ 8080 ];

  # Extra system packages
  # environment.systemPackages = with pkgs; [ htop ];
}
