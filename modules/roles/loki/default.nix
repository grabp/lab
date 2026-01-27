{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.loki = {
    enable = true;
    configFile = ./loki.yaml;
  };

  # Firewall: Loki HTTP API
  my.firewall.extraTCPPorts = [ 3100 ];
}
