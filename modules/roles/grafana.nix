{
  ...
}:

{
  services.grafana = {
    enable = true;

    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3000;
        domain = "grafana.grab-lab.gg";
        root_url = "http://grafana.grab-lab.gg";
        serve_from_sub_path = false;
      };

      security = {
        admin_user = "admin";
        admin_password = "$__file{/run/secrets/grafana_admin_password}";
        disable_gravatar = true;
      };

      analytics = {
        reporting_enabled = false;
        check_for_updates = false;
      };

      auth = {
        disable_login_form = false;
      };
    };

    # Provision datasources declaratively
    provision = {
      enable = true;

      datasources.settings = {
        datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://10.0.0.120:9090";
            isDefault = true;
          }
        ];
      };
    };
  };

  # Firewall: Grafana UI
  my.firewall.extraTCPPorts = [ 3000 ];
}
