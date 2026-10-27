{ config, lib, ... }:
let
  cfg = config.my.hardware.amdgpu;
in
{
  options.my.hardware.amdgpu.enable =
    lib.mkEnableOption "the primary AMD GPU (Mesa, early KMS, overdrive, LACT)";

  config = lib.mkIf cfg.enable {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    hardware.amdgpu = {
      initrd.enable = true;
      overdrive.enable = true;
    };

    services.lact.enable = true;

    services.xserver.videoDrivers = lib.mkBefore [ "amdgpu" ];
  };
}
