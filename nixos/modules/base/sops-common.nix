{
  inputs,
  config,
  ...
}:

{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  sops = {
    defaultSopsFile = ../../secrets/common.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";

    secrets = {
      # example
      nginx_basic_auth = {
        owner = "nginx";
        mode = "0400";
      };
    };
  };
}
