{
  services.prometheus = {
    enable = true;

    listenAddress = "0.0.0.0";
    port = 9090;

    globalConfig = {
      scrape_interval = "15s";
      evaluation_interval = "15s";
    };

    # Basic self-scrape (sanity check)
    scrapeConfigs = [
      {
        job_name = "prometheus";
        static_configs = [
          {
            targets = [ "localhost:9090" ];
          }
        ];
      }
      {
        job_name = "nodes";
        static_configs = [
          # {
          #   targets = [ "10.0.0.50:9100" ];
          #   labels = {
          #     role = "proxmox";
          #     site = "home";
          #   };
          # }
        ];
      }

    ];
  };

  my.firewall.extraTCPPorts = [
    9090
  ];
}
