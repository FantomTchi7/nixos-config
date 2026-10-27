{ config, lib, ... }:
let
  cfg = config.my.performance.zram;
in
{
  options.my.performance.zram.enable =
    lib.mkEnableOption "zram swap sized like CachyOS (zstd, 100% of RAM)";

  config = lib.mkIf cfg.enable {
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 100;
      priority = 100;
    };

    boot.kernel.sysctl."vm.swappiness" = 150;
    boot.kernelParams = [ "zswap.enabled=0" ];
  };
}
