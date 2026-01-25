{
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;

    enabledCollectors = [
      "systemd"
      "logind"
    ];

    disabledCollectors = [
      "textfile"
    ];

    listenAddress = "0.0.0.0";

    openFirewall = true;
  };

  my.firewall.extraTCPPorts = [ 9100 ];
}
