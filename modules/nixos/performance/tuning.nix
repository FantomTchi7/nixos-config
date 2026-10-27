{
  config,
  lib,
  ...
}:
let
  cfg = config.my.performance.tuning;
in
{
  options.my.performance.tuning = {
    enable = lib.mkEnableOption "latency and throughput kernel parameters beyond the CachyOS defaults";

    pcieAspmPerformance = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Pin PCIe ASPM to the `performance` policy, so links never enter L0s/L1.";
    };

    nvmeNoApst = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Disable NVMe Autonomous Power State Transitions (`default_ps_max_latency_us=0`).";
    };

    disableMitigations = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Boot with `mitigations=off`. Largest CPU win here, and removes real protection.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernelParams =
      lib.optional cfg.pcieAspmPerformance "pcie_aspm.policy=performance"
      ++ lib.optional cfg.nvmeNoApst "nvme_core.default_ps_max_latency_us=0"
      ++ lib.optional cfg.disableMitigations "mitigations=off";

    warnings = lib.optional cfg.disableMitigations ''
      my.performance.tuning.disableMitigations is on, so this kernel boots with
      `mitigations=off`. Speculative-execution attacks are not mitigated, including
      the vmscape VM-exit path that matters once a guest runs untrusted code.
    '';
  };
}
