{
  # Proxmox node IP/hostname
  node = "10.0.0.122";

  # Resource limits - optimized for small services
  cores = 1; # Most small services don't need more than 1 core
  memory = 512; # 512MB is usually sufficient, can increase if needed

  # Network bridge (network IP/gateway configured in configuration.nix)
  bridge = "vmbr0";

  # LXC-specific options
  unprivileged = true;
  features = [
    "nesting=1"
    "keyctl=1"
  ];
  rootfsSize = "15G";
  storage = "local-lvm";
}
