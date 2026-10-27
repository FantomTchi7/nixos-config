{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.desktop.hyprland;
in
{
  options.my.desktop.hyprland.enable = lib.mkEnableOption "Hyprland started through UWSM";

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
    };

    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

    security.polkit.enable = true;
    security.pam.services.hyprlock = { };
    programs.dconf.enable = true;

    environment.sessionVariables.NIXOS_OZONE_WL = "1";
  };
}
