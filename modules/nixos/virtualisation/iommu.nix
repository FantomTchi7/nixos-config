{
  config,
  lib,
  ...
}:
let
  cfg = config.my.virtualisation.iommu;
in
{
  options.my.virtualisation.iommu = {
    enable = lib.mkEnableOption "AMD IOMMU kernel parameters for KVM and VFIO";

    avic = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable AMD AVIC, hardware APIC virtualisation for the guest. Mutually
        exclusive with nested virtualisation, so it also passes `kvm_amd.nested=0`,
        which stops Windows 11 VBS working inside the guest.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernelParams = [
      "amd_iommu=on"
    ]
    ++ lib.optionals cfg.avic [
      "kvm_amd.avic=1"
      "kvm_amd.nested=0"
    ];
  };
}
