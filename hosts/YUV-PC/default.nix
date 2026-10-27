{ inputs, ... }:
{
  imports = [
    ./hardware.nix
    ./disko.nix
    ./gpu.nix
  ]
  ++ (with inputs.nixos-hardware.nixosModules; [
    gigabyte-b550
    common-cpu-amd
    common-cpu-amd-pstate
    common-gpu-amd
    common-pc
    common-pc-ssd
  ]);

  networking.hostName = "YUV-PC";

  my = {
    core.ssh.enable = true;

    kernel.cachyos.enable = true;

    performance = {
      scx.enable = true;
      ananicy.enable = true;
      zram.enable = true;
      cachyosSettings.enable = true;
    };

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
