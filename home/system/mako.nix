{ config, pkgs, lib, ... }:

let
  colors = config.lib.stylix.colors;
in
{
  services.mako = {
    enable = true;
    settings = {
      default-timeout = 3000;
      max-visible = 3;
      anchor = "bottom-left";
      sort = "-time";
      layer = "overlay";
      width = 350;
      height = 120;

      # Spacing between notifications
      margin = "10,10,10,10"; # top, right, bottom, left
      padding = "15,12,15,12"; # top, right, bottom, left

      # Distance from screen edges
      outer-margin = "20,15,25,15"; # top, right, bottom, left

      # Border styling
      border-size = 2;
      border-radius = 10;
      border-color = lib.mkForce "#${colors.base0A}"; # Stylix yellow accent

      # Transparency & visual polish
      background-color = lib.mkForce "#${colors.base01}cc"; # Stylix dark base + transparency
      text-color = lib.mkForce "#${colors.base06}"; # Stylix light foreground
      # Font and other colors can still be handled by Stylix
    };
  };
}
