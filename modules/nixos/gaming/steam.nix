{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.gaming.steam;
in
{
  options.my.gaming.steam.enable = lib.mkEnableOption "Steam with Proton-GE and gamescope";

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;
      gamescopeSession.enable = true;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
    };
  };
}
