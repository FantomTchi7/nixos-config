{ config, lib, ... }:
let
  cfg = config.my.performance.zram;
in
{
  options.my.performance.zram.enable =
    lib.mkEnableOption "zram swap sized like CachyOS (zstd, 100% of RAM)";

  config = lib.mkIf cfg.enable {
    # CachyOS-Settings: systemd/zram-generator.conf
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 100;
      priority = 100;
    };

    # CachyOS-Settings: udev/rules.d/30-zram.rules raises swappiness and turns
    # zswap off once zram0 is initialised; with zram always on we set both statically.
    boot.kernel.sysctl."vm.swappiness" = 150;
    boot.kernelParams = [ "zswap.enabled=0" ];
  };
}
