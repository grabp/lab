{
  imports = [
    ../../modules/platform/proxmox.nix

    ../../modules/base/defaults.nix
    ../../modules/base/firewall.nix
    ../../modules/base/nix.nix
    ../../modules/base/sops-common.nix
    ../../modules/base/ssh.nix
    ../../modules/base/users.nix

    ../../modules/roles/web.nix

    ../../modules/profiles/static-ip.nix

    ./secrets.nix
  ];

  my.networking.staticIPv4 = {
    enable = true;
    address = "10.0.0.69";
    gateway = "10.0.0.1";
  };
}
