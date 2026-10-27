{ ... }:
{
  imports = [ ../../modules/home ];

  my.home = {
    hyprland.enable = true;
    quickshell.enable = true;
  };

  programs.home-manager.enable = true;

  home.stateVersion = "26.05";
}
