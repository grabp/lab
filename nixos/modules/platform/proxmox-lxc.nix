{ lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

  # LXC containers don't need GRUB or QEMU guest services
  boot.loader.grub.enable = false;
}

