{
  config,
  lib,
  ...
}:
let
  cfg = config.my.hardware.zenpower;

  zenpower = config.boot.kernelPackages.zenpower.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace Makefile \
        --replace-fail "-Wimplicit-fallthrough=3" "-Wimplicit-fallthrough"
    '';
  });
in
{
  options.my.hardware.zenpower.enable =
    lib.mkEnableOption "zenpower instead of k10temp for Zen CPU voltage, current and power sensors";

  config = lib.mkIf cfg.enable {
    boot.extraModulePackages = [ zenpower ];
    boot.kernelModules = [ "zenpower" ];
    boot.blacklistedKernelModules = [ "k10temp" ];
  };
}
