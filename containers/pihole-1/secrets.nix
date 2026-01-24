{ ... }:

{
  # Pi-hole container-specific secrets
  sops.secrets.pihole_admin_password = {
    sopsFile = ../../secrets/vms/pihole-1.yaml;
    owner = "root";
    mode = "0400";
  };

  assertions = [
    {
      assertion = builtins.pathExists ../../secrets/vms/pihole-1.yaml;
      message = "Missing secrets/vms/pihole-1.yaml";
    }
  ];
}

