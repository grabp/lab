{ config, ... }:
{
  services.nginx = {
    enable = true;

    virtualHosts."0.0.0.0" = {
      basicAuthFile = config.sops.secrets.nginx_basic_auth.path;

      locations."/" = {
        return = "200 '<html><body>It works fine af babyyyyy!</body></html>'";
        extraConfig = ''
          default_type text/html;
        '';
      };
    };
  };

  my.firewall.extraTCPPorts = [
    80
    443
  ];
}
