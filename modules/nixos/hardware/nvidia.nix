{ config, lib, ... }:
let
  cfg = config.my.hardware.nvidia;
in
{
  options.my.hardware.nvidia.enable =
    lib.mkEnableOption "the secondary NVIDIA GPU (Pascal, NVENC only, no displays)";

  config = lib.mkIf cfg.enable {
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
      modesetting.enable = true;
      nvidiaSettings = false;
      powerManagement.enable = false;
    };

    boot.extraModprobeConfig = ''
      options nvidia NVreg_InitializeSystemMemoryAllocations=0
    '';

    services.udev.extraRules = ''
      ACTION=="add|bind", SUBSYSTEM=="pci", DRIVERS=="nvidia", ATTR{vendor}=="0x10de", ATTR{class}=="0x03[0-9]*", TEST=="power/control", ATTR{power/control}="auto"
      ACTION=="remove|unbind", SUBSYSTEM=="pci", DRIVERS=="nvidia", ATTR{vendor}=="0x10de", ATTR{class}=="0x03[0-9]*", TEST=="power/control", ATTR{power/control}="on"
    '';
  };
}
