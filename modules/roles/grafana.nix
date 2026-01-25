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
        root_url = "https://grafana.grab-lab.gg";
        serve_from_sub_path = false;
        enable_gzip = true;
      };

      users = {
        allow_sign_up = false;
        allow_org_create = false;
        auto_assign_org = true;
        auto_assign_org_role = "Viewer";
        viewers_can_edit = false;
        verify_email_enabled = false;
      };

      security = {
        admin_user = "admin";
        admin_password = "$__file{/run/secrets/grafana_admin_password}";
        disable_initial_admin_creation = true;
        disable_gravatar = true;

        cookie_secure = true;
        cookie_samesite = "lax";
        allow_embedding = false;
      };

      analytics = {
        reporting_enabled = false;
        feedback_links_enabled = false;
        check_for_updates = false;
        check_for_plugin_updates = false;
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
            editable = false;
          }
        ];
      };

      dashboards = {
        settings = {
          apiVersion = 1;

          providers = [
            {
              name = "infrastructure";
              type = "file";
              options = {
                path = "/etc/grafana/dashboards";
              };
            }
          ];
        };
      };

    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/grafana/dashboards 0750 grafana grafana -"
  ];

  environment.etc."grafana/dashboards".source = ./grafana-dashboards;

  # Firewall: Grafana UI
  my.firewall.extraTCPPorts = [ 3000 ];
}
