{ inputs, ... }:
{
  imports = [
    ./gpu.nix
    ./hardware.nix
  ]
  ++ (with inputs.nixos-hardware.nixosModules; [
    common-pc
    common-pc-ssd
    common-cpu-amd-pstate
    common-gpu-amd
    gigabyte-b550
  ]);

  networking.hostName = "YUV-PC";

  my = {
    kernel.cachyos.enable = true;

    core.ssh.enable = true;

    hardware.zenpower.enable = true;

    performance = {
      scx.enable = true;
      ananicy.enable = true;
      zram.enable = true;
      cachyosSettings.enable = true;
      tuning.enable = true;
    };

    virtualisation.iommu.enable = true;

    desktop = {
      hyprland.enable = true;
      greetd.enable = true;
      fonts.enable = true;
    };

    audio.pipewire.enable = true;

    gaming = {
      steam.enable = true;
      tools.enable = true;
    };
  };

  system.stateVersion = "26.05";
}
