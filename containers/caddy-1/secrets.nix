{ ... }:

{
  # Caddy container secrets
  # Cloudflare API token stored in env file for DNS-01 ACME challenge (future TLS)
  sops.secrets.cloudflare_api_token = {
    sopsFile = ../../secrets/vms/caddy-1.env;
    format = "dotenv";
    owner = "caddy";
    mode = "0400";
  };

  assertions = [
    {
      assertion = builtins.pathExists ../../secrets/vms/caddy-1.env;
      message = "Missing secrets/vms/caddy-1.env";
    }
  ];
}
