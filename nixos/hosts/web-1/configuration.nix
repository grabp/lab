{
  imports = [
    ../../modules/platform/proxmox.nix

    ../../modules/base

    ../../modules/roles/web.nix

    ../../modules/profiles/static-ip.nix
  ];

  my.networking.staticIPv4 = {
    enable = true;
    address = "10.0.0.69";
    gateway = "10.0.0.1";
  };
}
