{ config, lib, ... }:
let
  cfg = config.my.core.boot;
in
{
  options.my.core.boot.enable = lib.mkEnableOption "UEFI systemd-boot with a systemd initrd" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    boot.loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
        editor = false;
      };
      efi.canTouchEfiVariables = true;
    };

    boot.initrd.systemd.enable = true;
  };
}
