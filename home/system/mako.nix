{ config, pkgs, lib, scale, ... }:

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
      width = scale.container.notification;
      height = scale.container.notificationH;

      # Spacing between notifications (Fibonacci: lg=13, xl=21, xxl=34)
      margin = "${toString scale.gap.lg},${toString scale.gap.lg},${toString scale.gap.lg},${toString scale.gap.lg}";
      padding = "${toString scale.gap.xl},${toString scale.gap.lg},${toString scale.gap.xl},${toString scale.gap.lg}";

      # Distance from screen edges
      outer-margin = "${toString scale.gap.xl},${toString scale.gap.lg},${toString scale.gap.xxl},${toString scale.gap.lg}";

      # Border styling
      border-size = scale.border.normal;
      border-radius = scale.radius.lg;
      border-color = lib.mkForce "#${colors.base0A}"; # Stylix yellow accent

      # Transparency & visual polish
      background-color = lib.mkForce "#${colors.base01}cc"; # Stylix dark base + transparency
      text-color = lib.mkForce "#${colors.base06}"; # Stylix light foreground
      # Font and other colors can still be handled by Stylix
    };
  };
}
