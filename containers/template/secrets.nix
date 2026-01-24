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
      assertion = builtins.pathExists ../../secrets/vms/CHANGEME.yaml;
      message = "Missing secrets/vms/CHANGEME.yaml";
    }
  ];
}

