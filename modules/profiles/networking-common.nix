{ lib, config, ... }:

{
  options.my.networking.interface = lib.mkOption {
    type = lib.types.str;
    default = "eth0";
    description = "Primary network interface";
  };

  options.my.networking.dns = lib.mkOption {
    type = lib.types.nullOr (lib.types.listOf lib.types.str);
    default = null;
    example = [
      "1.1.1.1"
      "9.9.9.9"
    ];
    description = ''
      DNS servers to use.
      null = use DHCP-provided DNS (default)
    '';
  };

  config = lib.mkIf (config.my.networking.dns != null) {
    networking.nameservers = config.my.networking.dns;
  };
}
