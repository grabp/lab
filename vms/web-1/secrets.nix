{ ... }:

{
  sops.secrets.nginx_basic_auth = {
    sopsFile = ../../secrets/vms/web-1.yaml;
    owner = "nginx";
    mode = "0400";
  };

  assertions = [
    {
      assertion = builtins.pathExists ../../secrets/vms/web-1.yaml;
      message = "Missing secrets/vms/web-1.yaml";
    }
  ];
}
