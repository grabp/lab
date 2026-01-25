{
  # Proxmox node IP/hostname
  node = "10.0.0.50";

  # Resource limits - Caddy reverse proxy
  cores = 1;
  memory = 512;

  # Network bridge (network IP/gateway configured in configuration.nix)
  bridge = "vmbr0";

  # LXC-specific options
  unprivileged = true;
  features = [ "nesting=1" "keyctl=1" ];
  rootfsSize = "4G";
  storage = "local-lvm";
}

