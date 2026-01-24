{ lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

  # LXC containers don't need GRUB or QEMU guest services
  boot.loader.grub.enable = false;

  # In LXC containers, time synchronization is handled by the host system.
  # Disable systemd-timesyncd to avoid permission errors when trying to adjust time.
  # The container inherits time from the Proxmox host.
  services.timesyncd.enable = false;

  # Ensure time-sync.target doesn't wait for timesyncd
  systemd.targets.time-sync.wantedBy = lib.mkForce [];
}

