{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.home.hyprland;
in
{
  options.my.home.hyprland.enable =
    lib.mkEnableOption "the Hyprland user config (Lua) and session helpers";

  config = lib.mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      package = null;
      portalPackage = null;
      systemd.enable = false;
      configType = "lua";

#       extraConfig = ''
#         require("conf.monitors")
#       '';
    };

    xdg.configFile."hypr/conf".source = ./conf;

    programs.ghostty = {
      enable = true;
      enableBashIntegration = true;
    };

    programs.rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
      extraConfig = {
        modi = "drun";
        show-icons = true;
        drun-display-format = "{icon} {name}";
        disable-history = false;
        sidebar-mode = true;
      };
    };

    services.hyprpolkitagent.enable = true;

    home.packages = with pkgs; [
      wl-clipboard
      grim
      slurp
      playerctl
    ];
  };
}
