{
  config,
  lib,
  env,
  ...
}:
let
  cfg = config.my.core.locale;
in
{
  options.my.core.locale.enable =
    lib.mkEnableOption "time zone, locale and console keymap from .env"
    // {
      default = true;
    };

  config = lib.mkIf cfg.enable {
    time.timeZone = if env.TIMEZONE == "" then null else env.TIMEZONE;
    i18n.defaultLocale = env.LOCALE;
    console.keyMap = env.KEYBOARD_LAYOUT;
  };
}
