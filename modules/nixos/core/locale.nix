{
  config,
  lib,
  vars,
  ...
}:
let
  cfg = config.my.core.locale;
in
{
  options.my.core.locale.enable =
    lib.mkEnableOption "time zone, locale and keyboard layout from lib/vars.nix"
    // {
      default = true;
    };

  config = lib.mkIf cfg.enable {
    time.timeZone = vars.timeZone;
    i18n.defaultLocale = vars.locale;
    console.keyMap = vars.keyboardLayout;
    services.xserver.xkb.layout = vars.keyboardLayout;
  };
}
