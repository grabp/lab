{ config, lib, pkgs, ... }:
let
  hasPasswordSecret = config.sops.secrets ? pihole_admin_password;
  secretPath = if hasPasswordSecret then config.sops.secrets.pihole_admin_password.path else null;
in
{
  imports = [
    ./pihole-adlists.nix
  ];
  services.pihole-ftl = {
    enable = true;
    
    # Blocklists are configured via ./pihole-adlists.nix module
    # If Meta products (Instagram, Facebook) have issues, allowlist domains:
    # - CLI: pihole -w domain.com
    # - Web UI: Allowlist → Add domain
    # Common domains: facebook.com, fbcdn.net, instagram.com, cdninstagram.com
    
    settings = {
      DNS1 = "8.8.8.8";
      DNS2 = "8.8.4.4";
      DHCP_ACTIVE = "false";
      # Password set via FTLCONF_webserver_api_password environment variable
      WEBPASSWORD = "";
      QUERY_LOGGING = "true";
      INSTALL_WEB_SERVER = "true";
      INSTALL_WEB_INTERFACE = "true";
      # Add upstream DNS servers as dnsmasq directives
      # DNS1/DNS2 settings alone don't configure dnsmasq upstream servers
      misc = {
        dnsmasq_lines = [
          "server=8.8.8.8"
          "server=8.8.4.4"
        ];
      };
    };
  };

  services.pihole-web = {
    enable = true;
    ports = [ 80 443 ];
  };

  # Set password via environment variable before service starts
  # More secure than post-start scripts: no timing window, uses native pihole support,
  # password never appears in logs or Nix store
  systemd.services.pihole-password-setup = lib.mkIf hasPasswordSecret {
    description = "Set up Pi-hole admin password from SOPS secret";
    wantedBy = [ "pihole-ftl.service" ];
    before = [ "pihole-ftl.service" ];
    after = [ "run-secrets.d.mount" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.writeShellScriptBin "pihole-password-setup" ''
        if [ -f ${secretPath} ] && [ -s ${secretPath} ]; then
          password=$(cat ${secretPath})
          echo "FTLCONF_webserver_api_password=$password" > /run/pihole-password.env
          chmod 600 /run/pihole-password.env
        else
          # Create empty file if secret doesn't exist to avoid EnvironmentFile error
          touch /run/pihole-password.env
          chmod 600 /run/pihole-password.env
        fi
      ''}/bin/pihole-password-setup";
    };
  };

  # Configure pihole-ftl service
  systemd.services.pihole-ftl = lib.mkMerge [
    {
      # Remove CAP_SYS_TIME capability - LXC containers can't adjust system time
      # Time is inherited from the Proxmox host
      serviceConfig.AmbientCapabilities = lib.mkForce [
        "CAP_NET_BIND_SERVICE"
        "CAP_NET_RAW"
        "CAP_NET_ADMIN"
        "CAP_SYS_NICE"
        "CAP_IPC_LOCK"
        "CAP_CHOWN"
      ];
    }
    (lib.mkIf hasPasswordSecret {
      serviceConfig = {
        # Use - prefix to make EnvironmentFile optional (won't fail if file doesn't exist)
        EnvironmentFile = "-/run/pihole-password.env";
        LogLevelMax = "notice";
      };
      # Wait for password setup and secrets mount
      after = [ "pihole-password-setup.service" "run-secrets.d.mount" ];
      wants = [ "pihole-password-setup.service" "run-secrets.d.mount" ];
    })
  ];

  my.firewall.extraTCPPorts = [ 53 80 443 ];
  my.firewall.extraUDPPorts = [ 53 ];

  # Configure systemd-resolved to work with pihole
  # Disable DNS stub listener to free up port 53 for pihole-FTL
  services.resolved = {
    enable = true;
    # Disable DNS stub listener on port 53 via extraConfig - pihole needs this port
    extraConfig = ''
      DNSStubListener=no
      DNS=8.8.8.8 8.8.4.4
    '';
    # Fallback DNS servers
    fallbackDns = [ "1.1.1.1" "1.0.0.1" ];
    # Don't use LLMNR - let pihole handle DNS
    llmnr = "false";
  };

  # Configure /etc/resolv.conf to point to pihole for client queries
  # systemd-resolved will use the DNS servers above, while applications use pihole
  networking.nameservers = [ "127.0.0.1" ];
}
