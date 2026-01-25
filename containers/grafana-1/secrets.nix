{ ... }:

{
  # Example container-specific secret
  # Remove or adapt as needed

  sops.secrets.grafana_admin_password = {
    sopsFile = ../../secrets/vms/grafana-1.yaml;
    owner = "grafana";
    mode = "0400";
  };

  assertions = [
    {
      assertion = builtins.pathExists ../../secrets/vms/grafana-1.yaml;
      message = "Missing secrets/vms/grafana-1.yaml";
    }
  ];
}
