{ lib, ... }:

{
  imports = [
    # Platform
    ../../modules/platform/proxmox-vm.nix

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
    address = "10.0.0.70";
    gateway = "10.0.0.1";
  };

  # Optional DNS override
  # my.networking.dns = [ "1.1.1.1" "9.9.9.9" ];

  ### ---- OPTIONAL PER HOST ----

  # Add host-specific firewall ports
  my.firewall.extraTCPPorts = [
    80
    443
  ];

  services.caddy = {
    enable = true;
    virtualHosts."0.0.0.0".extraConfig = ''
      respond "Hello, world!"
    '';
  };

  # Extra system packages
  # environment.systemPackages = with pkgs; [ htop ];
}
