{ config, pkgs, ... }:

{
  # swww is installed via packages.nix and started via Hyprland exec-once
  # This module ensures wallpaper directory exists and provides helper scripts

  home.file.".config/swww/.keep".text = "";

  # Create a wallpapers directory
  home.file."wallpapers/.keep".text = "";

  # NOTE: Download a space wallpaper and place it at ~/wallpapers/space-solarized.png
  # Or use swww to set one: swww img ~/wallpapers/your-image.png --transition-type wipe
}
