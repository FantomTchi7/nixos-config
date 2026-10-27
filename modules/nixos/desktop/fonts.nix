{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.desktop.fonts;
in
{
  options.my.desktop.fonts.enable =
    lib.mkEnableOption "a base font set (Noto, CJK, emoji, JetBrains Mono Nerd Font)";

  config = lib.mkIf cfg.enable {
    fonts = {
      packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        nerd-fonts.jetbrains-mono
      ];

      fontconfig.defaultFonts = {
        sansSerif = [ "Noto Sans" ];
        serif = [ "Noto Serif" ];
        monospace = [ "JetBrainsMono Nerd Font" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
