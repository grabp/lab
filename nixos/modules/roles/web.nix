{ config, ... }:
{
  services.nginx = {
    enable = true;

    virtualHosts."0.0.0.0" = {
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
