{
  config,
  lib,
  pkgs,
  vars,
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
      # Hyprland and its portal come from the NixOS module.
      package = null;
      portalPackage = null;
      # UWSM manages the systemd session.
      systemd.enable = false;
      configType = "lua";

      settings = {
        config.input.kb_layout = vars.keyboardLayout;
      };

      extraConfig = ''
        require("conf.monitors")
        require("conf.looks")
        require("conf.input")
        require("conf.binds")
        require("conf.rules")
      '';
    };

    xdg.configFile."hypr/conf".source = ./conf;

    programs.kitty.enable = true;
    programs.fuzzel.enable = true;
    services.hyprpolkitagent.enable = true;

    home.packages = with pkgs; [
      wl-clipboard
      grim
      slurp
      playerctl
    ];
  };
}
