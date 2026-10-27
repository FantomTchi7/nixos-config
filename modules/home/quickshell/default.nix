{ config, lib, ... }:
let
  cfg = config.my.home.quickshell;
in
{
  options.my.home.quickshell.enable =
    lib.mkEnableOption "the Quickshell desktop shell (nixpkgs build)";

  config = lib.mkIf cfg.enable {
    programs.quickshell = {
      enable = true;
      configs.default = ./config;
      activeConfig = "default";
      systemd = {
        enable = true;
        target = "graphical-session.target";
      };
    };
  };
}
