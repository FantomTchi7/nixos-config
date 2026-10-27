{ config, lib, ... }:
let
  cfg = config.my.audio.pipewire;
in
{
  options.my.audio.pipewire.enable = lib.mkEnableOption "PipeWire with ALSA, PulseAudio and JACK";

  config = lib.mkIf cfg.enable {
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };
}
