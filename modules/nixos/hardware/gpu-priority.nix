{ config, lib, ... }:
let
  cfg = config.my.hardware.gpuPriority;
in
{
  options.my.hardware.gpuPriority = {
    enable = lib.mkEnableOption "pinning the Wayland compositor to one GPU";

    primaryPciAddress = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "0000:0b:00.0";
      description = "PCI address of the GPU the compositor should use (from `lspci -D`).";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf (cfg.primaryPciAddress != null) {
        services.udev.extraRules = ''
          SUBSYSTEM=="drm", KERNEL=="card[0-9]*", ENV{ID_PATH}=="pci-${cfg.primaryPciAddress}", SYMLINK+="dri/primary-gpu"
        '';

        environment.sessionVariables.AQ_DRM_DEVICES = "/dev/dri/primary-gpu";
      })

      {
        warnings = lib.optional (cfg.primaryPciAddress == null) ''
          my.hardware.gpuPriority.primaryPciAddress is unset, so the compositor may pick any GPU.
          Set it from `lspci -D | grep VGA` on the installed system.
        '';
      }
    ]
  );
}
