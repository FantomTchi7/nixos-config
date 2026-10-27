{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.performance.ananicy;
in
{
  options.my.performance.ananicy.enable = lib.mkEnableOption "ananicy-cpp with the CachyOS rule set";

  config = lib.mkIf cfg.enable {
    services.ananicy = {
      enable = true;
      package = pkgs.ananicy-cpp;
      rulesProvider = pkgs.ananicy-rules-cachyos;
    };
  };
}
