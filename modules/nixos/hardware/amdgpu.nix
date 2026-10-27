{ config, lib, ... }:
let
  cfg = config.my.hardware.amdgpu;
in
{
  options.my.hardware.amdgpu.enable =
    lib.mkEnableOption "the primary AMD GPU (Mesa, early KMS, overdrive, LACT)";

  config = lib.mkIf cfg.enable {
    hardware.amdgpu.overdrive.enable = true;

    services.lact.enable = true;

    services.xserver.videoDrivers = lib.mkBefore [ "amdgpu" ];
  };
}
