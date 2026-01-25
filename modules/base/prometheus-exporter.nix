{
  services.prometheus.exporters.node = {
    enable = true;

    port = 9100;
    listenAddress = "0.0.0.0";

    enabledCollectors = [
      "systemd"
      "filesystem"
      "cpu"
      "meminfo"
      "loadavg"
    ];

    disabledCollectors = [
      "textfile"
    ];

    openFirewall = true;
  };

  my.firewall.extraTCPPorts = [ 9100 ];
}
