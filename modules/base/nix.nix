{ config
, pkgs
, lib
, modulesPath
, ...
}:

{
  environment.systemPackages = with pkgs; [
    vim
    git
    python3
  ];

  security.sudo.wheelNeedsPassword = false;

  # services.avahi = {
  #   enable = true;
  #   nssmdns4 = true;
  #   publish = {
  #     enable = true;
  #     addresses = true;
  #   };
  # };

  nix.settings = {
    trusted-users = [
      "root"
      "@wheel"
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
}
