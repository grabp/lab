{ lib, config, ... }:

let
  cfg = config.my.networking.staticIPv4;
in
{
  imports = [
    ./networking-common.nix
  ];

  options.my.networking.staticIPv4 = {
    enable = lib.mkEnableOption "static IPv4 networking";

    address = lib.mkOption {
      type = lib.types.str;
      example = "10.0.0.120";
    };

    prefixLength = lib.mkOption {
      type = lib.types.int;
      default = 24;
    };

    gateway = lib.mkOption {
      type = lib.types.str;
      example = "10.0.0.1";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.useDHCP = lib.mkForce false;

    networking.interfaces.${config.my.networking.interface}.ipv4.addresses = [
      {
        address = cfg.address;
        prefixLength = cfg.prefixLength;
      }
    ];

    networking.defaultGateway = {
      address = cfg.gateway;
      interface = config.my.networking.interface;
    };

    # Safety: cannot combine with DHCP
    assertions = [
      {
        assertion = !(config.my.networking.dhcp.enable or false);
        message = "Cannot enable static IPv4 and DHCP at the same time";
      }
    ];
  };
}
