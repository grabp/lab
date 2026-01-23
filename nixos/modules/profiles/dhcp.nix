{ lib, config, ... }:

{
  imports = [
    ./networking-common.nix
  ];

  options.my.networking.dhcp.enable = lib.mkEnableOption "DHCP networking";

  config = lib.mkIf config.my.networking.dhcp.enable {
    networking.useDHCP = lib.mkForce true;

    networking.interfaces.${config.my.networking.interface}.useDHCP = lib.mkForce true;

    assertions = [
      {
        assertion = !(config.my.networking.staticIPv4.enable or false);
        message = "Cannot enable DHCP and static IPv4 at the same time";
      }
    ];
  };
}
