{ config, lib, ... }:
let
  cfg = config.my.core.nix;
in
{
  options.my.core.nix.enable = lib.mkEnableOption "flakes, binary caches and garbage collection" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    nix = {
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        auto-optimise-store = true;
        trusted-users = [ "@wheel" ];
        extra-substituters = [ "https://nix-community.cachix.org" ];
        extra-trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };

      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
      };

      channel.enable = false;
    };

    nixpkgs.config.allowUnfree = true;
  };
}
