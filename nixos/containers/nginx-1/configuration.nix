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

    # Container secrets
    ./secrets.nix
  ];

  ### ---- REQUIRED PER CONTAINER ----

  # Static IP configuration
  my.networking.staticIPv4 = {
    enable = true;
    address = "10.0.0.100";
    gateway = "10.0.0.1";
  };

  # Optional DNS override (if not provided by DHCP/router)
  # my.networking.dns = [ "1.1.1.1" "9.9.9.9" ];

  ### ---- OPTIONAL PER CONTAINER ----

  # Add container-specific firewall ports
  my.firewall.extraTCPPorts = [ 80 ];

  # Nginx configuration - listens on 0.0.0.0 (all interfaces)
  services.nginx = {
    enable = true;
    virtualHosts."_" = {
      default = true;
      locations."/" = {
        return = "200 '<html><body><h1>Hello from nginx!</h1><p>It works!</p></body></html>'";
        extraConfig = ''
          default_type text/html;
        '';
      };
    };
  };

  # Extra system packages
  # environment.systemPackages = with pkgs; [ htop ];
}

