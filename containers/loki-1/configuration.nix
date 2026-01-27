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
    ../../modules/base/prometheus-exporter.nix
    ../../modules/base/promtail.nix

    # Networking profile
    ../../modules/profiles/static-ip.nix

    # Roles
    ../../modules/roles/loki

    # Container secrets
    ./secrets.nix
  ];

  ### ---- REQUIRED PER CONTAINER ----

  # Static IP configuration
  my.networking.staticIPv4 = {
    enable = true;
    address = "10.0.0.122";
    gateway = "10.0.0.1";
  };

  # Optional DNS override (if not provided by DHCP/router)
  # my.networking.dns = [ "1.1.1.1" "9.9.9.9" ];

  ### ---- OPTIONAL PER CONTAINER ----

  # Add container-specific firewall ports
  # my.firewall.extraTCPPorts = [ 8080 ];

  # Extra system packages
  # environment.systemPackages = with pkgs; [ htop ];
}
