{ pkgs, ... }:
{
  # LXC constraints
  boot.isContainer = true;
  services.resolved.enable = false;

  networking.useNetworkd = true;

  # Containers do NOT have VTs
  systemd.services."systemd-logind".enable = false;

  # Kill everything that could pull in agetty
  systemd.targets.getty.enable = false;

  # Safety: explicitly mask the known offenders
  systemd.services."autovt@tty1".unitConfig.Mask = true;
  systemd.services."console-getty".unitConfig.Mask = true;
  systemd.services."container-getty@".unitConfig.Mask = true;

  # Disable mounts that are illegal in LXC
  systemd.services."dev-mqueue.mount".enable = false;
  systemd.services."sys-kernel-debug.mount".enable = false;
  systemd.services."sys-kernel-tracing.mount".enable = false;

  # Core IPC — REQUIRED
  services.dbus.enable = true;
}
