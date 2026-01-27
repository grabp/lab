{ ... }:

{
  # Example container-specific secret
  # Remove or adapt as needed

  #   sops.secrets.example_secret = {
  #     sopsFile = ../../secrets/vms/CHANGEME.yaml;
  #     owner = "root";
  #     mode = "0400";
  #   };

  assertions = [
    {
      assertion = builtins.pathExists ../../secrets/vms/loki-1.yaml;
      message = "Missing secrets/vms/loki-1.yaml";
    }
  ];
}
