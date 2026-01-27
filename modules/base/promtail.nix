{
  services.promtail = {
    enable = true;
    configFile = ./promtail.yaml;
  };

  # Required so Promtail can read the journal
  services.journald.extraConfig = ''
    Storage=persistent
  '';

  users.users.promtail.extraGroups = [ "systemd-journal" ];

  # Optional: expose Promtail metrics (not required)
  my.firewall.extraTCPPorts = [ 9080 ];

  systemd.tmpfiles.rules = [
    "d /run/promtail 0750 promtail promtail -"
  ];
}
