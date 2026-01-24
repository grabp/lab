{
  system.stateVersion = "25.11";
  time.timeZone = "Europe/Warsaw";

  imports = [
    ../../modules/base/sops-common.nix
    ../../modules/base/firewall.nix
    ../../modules/base/nix.nix
    ../../modules/base/ssh.nix
    ../../modules/base/users.nix
  ];
}
