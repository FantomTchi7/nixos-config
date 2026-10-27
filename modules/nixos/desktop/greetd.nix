{
  config,
  lib,
  pkgs,
  vars,
  ...
}:
let
  cfg = config.my.desktop.greetd;
  session = "uwsm start hyprland-uwsm.desktop";
in
{
  options.my.desktop.greetd = {
    enable = lib.mkEnableOption "greetd with tuigreet";

    autologin = lib.mkEnableOption "logging the main user straight into Hyprland once per boot" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.my.desktop.hyprland.enable;
        message = "my.desktop.greetd launches Hyprland, so my.desktop.hyprland must be enabled.";
      }
    ];

    services.greetd = {
      enable = true;
      useTextGreeter = true;
      settings = {
        default_session.command = "${lib.getExe pkgs.tuigreet} --time --remember --cmd '${session}'";
      }
      // lib.optionalAttrs cfg.autologin {
        initial_session = {
          user = vars.username;
          command = session;
        };
      };
    };
  };
}
