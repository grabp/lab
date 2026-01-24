{
  # Proxmox node IP/hostname
  node = "10.0.0.50";

  # Resource limits - optimized for pi-hole
  cores = 2; # Pi-hole can benefit from 2 cores for better performance
  memory = 1024; # 1GB RAM recommended for pi-hole with blocklists

  # Network bridge (network IP/gateway configured in configuration.nix)
  bridge = "vmbr0";

  # LXC-specific options
  unprivileged = true;
  features = [ "nesting=1" "keyctl=1" ];
  rootfsSize = "4G"; # Sufficient for pi-hole data and logs
  storage = "local-lvm";
}

