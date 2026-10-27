{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.gaming.tools;
in
{
  options.my.gaming.tools.enable = lib.mkEnableOption "gaming utilities (MangoHud)";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      mangohud
    ];
  };
}
