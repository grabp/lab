{
  services.prometheus = {
    enable = true;

    configText = builtins.readFile ./prometheus.yml;

  };

  environment.etc."prometheus/rules".source = ./rules;

  my.firewall.extraTCPPorts = [
    9090
  ];
}
