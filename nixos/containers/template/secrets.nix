{ ... }:

{
  # Example container-specific secret
  # Remove or adapt as needed

#   sops.secrets.example_secret = {
#     sopsFile = ../../secrets/hosts/CHANGEME.yaml;
#     owner = "root";
#     mode = "0400";
#   };

  assertions = [
    {
      assertion = builtins.pathExists ../../secrets/hosts/CHANGEME.yaml;
      message = "Missing secrets/hosts/CHANGEME.yaml";
    }
  ];
}

