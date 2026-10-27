{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.my.kernel.cachyos;
in
{
  options.my.kernel.cachyos = {
    enable = lib.mkEnableOption "the CachyOS kernel from xddxdd/nix-cachyos-kernel";

    variant = lib.mkOption {
      type = lib.types.str;
      default = "linuxPackages-cachyos-latest-lto-x86_64-v3";
      description = "Attribute name of the kernel package set under `pkgs.cachyosKernels`.";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ];

    boot.kernelPackages = pkgs.cachyosKernels.${cfg.variant};

    nix.settings = {
      extra-substituters = [ "https://cache.lantian.pub/lantian" ];
      extra-trusted-public-keys = [ "lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ=" ];
    };
  };
}
