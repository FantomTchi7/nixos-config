{ config, lib, ... }:
let
  cfg = config.my.performance.scx;
in
{
  options.my.performance.scx = {
    enable = lib.mkEnableOption "a sched-ext BPF CPU scheduler";

    scheduler = lib.mkOption {
      type = lib.types.str;
      default = "scx_lavd";
      description = "sched-ext scheduler to run (must be provided by `services.scx.package`).";
    };
  };

  config = lib.mkIf cfg.enable {
    services.scx = {
      enable = true;
      inherit (cfg) scheduler;
    };
  };
}
