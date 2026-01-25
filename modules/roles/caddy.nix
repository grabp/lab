{
  config,
  pkgs,
  ...
}:

{
  services.caddy = {
    enable = true;

    package = pkgs.caddy.withPlugins {
      plugins = [
        "github.com/caddy-dns/cloudflare@v0.2.2"
      ];
      hash = "sha256-dnhEjopeA0UiI+XVYHYpsjcEI6Y1Hacbi28hVKYQURg=";
    };

    # Expose CF_API_TOKEN to Caddy securely
    environmentFile = config.sops.secrets.cloudflare_api_token.path;

    globalConfig = ''
      email grabowskip@icloud.com
      acme_dns cloudflare {env.CF_API_TOKEN}
    '';

    virtualHosts = {
      "pihole.grab-lab.gg" = {
        extraConfig = ''
          tls {
            dns cloudflare {env.CF_API_TOKEN}
            resolvers 1.1.1.1 1.0.0.1
          }

          reverse_proxy 10.0.0.53:80
        '';
      };
      "prometheus.grab-lab.gg" = {
        extraConfig = ''
          tls {
            dns cloudflare {env.CF_API_TOKEN}
            resolvers 1.1.1.1 1.0.0.1
          }

          reverse_proxy 10.0.0.20:9090
        '';
      };

      "*.grab-lab.gg" = {
        extraConfig = ''
          respond "Service not found" 404
        '';
      };
    };
  };

  # Only HTTPS is required for DNS-01
  networking.firewall.allowedTCPPorts = [ 443 ];
}
