{ config, lib, pkgs, ... }:
let
  hasPasswordSecret = config.sops.secrets ? pihole_admin_password;
  secretPath = if hasPasswordSecret then config.sops.secrets.pihole_admin_password.path else null;
in
{
  services.pihole-ftl = {
    enable = true;
    settings = {
      DNS1 = "8.8.8.8";
      DNS2 = "8.8.4.4";
      DHCP_ACTIVE = "false";
      # Password set via FTLCONF_webserver_api_password environment variable
      WEBPASSWORD = "";
      QUERY_LOGGING = "true";
      INSTALL_WEB_SERVER = "true";
      INSTALL_WEB_INTERFACE = "true";
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

  systemd.services.pihole-ftl = lib.mkIf hasPasswordSecret {
    serviceConfig = {
      # Use - prefix to make EnvironmentFile optional (won't fail if file doesn't exist)
      EnvironmentFile = "-/run/pihole-password.env";
      LogLevelMax = "notice";
    };
    # Wait for password setup and secrets mount
    after = [ "pihole-password-setup.service" "run-secrets.d.mount" ];
    wants = [ "pihole-password-setup.service" "run-secrets.d.mount" ];
  };

  my.firewall.extraTCPPorts = [ 53 80 443 ];
  my.firewall.extraUDPPorts = [ 53 ];

  # Configure systemd-resolved to work with pihole
  # Disable DNS stub listener to free up port 53 for pihole-FTL
  # Configure systemd-resolved to use pihole as upstream DNS
  services.resolved = {
    enable = true;
    # Disable DNS stub listener on port 53 via extraConfig - pihole needs this port
    extraConfig = ''
      DNSStubListener=no
    '';
    # Fallback DNS servers for systemd-resolved itself (in case pihole isn't ready)
    fallbackDns = [ "8.8.8.8" "8.8.4.4" ];
    # Don't use LLMNR - let pihole handle DNS
    llmnr = "false";
  };

  # Configure /etc/resolv.conf to point to pihole
  # When DNSStubListener is no, systemd-resolved will create resolv.conf pointing to the DNS servers we configured
  networking.nameservers = [ "127.0.0.1" ];
}

