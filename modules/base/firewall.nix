{ lib, config, ... }:

let
  cfg = config.my.firewall;
in
{
  options.my.firewall.extraTCPPorts = lib.mkOption {
    type = lib.types.listOf lib.types.port;
    default = [ ];
    description = "Extra TCP ports to open in the firewall";
  };

  options.my.firewall.extraUDPPorts = lib.mkOption {
    type = lib.types.listOf lib.types.port;
    default = [ ];
    description = "Extra UDP ports to open in the firewall";
  };

  config.networking.firewall.allowedTCPPorts = [ 22 ] ++ cfg.extraTCPPorts;
  config.networking.firewall.allowedUDPPorts = cfg.extraUDPPorts;
}
