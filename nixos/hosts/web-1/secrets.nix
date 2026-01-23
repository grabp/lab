{ ... }:

{
  sops.secrets.nginx_basic_auth = {
    sopsFile = ../../secrets/hosts/web-1.yaml;
    owner = "nginx";
    mode = "0400";
  };

  assertions = [
    {
      assertion = builtins.pathExists ../../secrets/hosts/web-1.yaml;
      message = "Missing secrets/hosts/web-1.yaml";
    }
  ];
}
