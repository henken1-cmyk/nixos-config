{ ... }:

{
  services.swaync = {
    enable = true;
    settings = {
      positionX = "left";
      positionY = "top";
      layer = "overlay";
      control-center-layer = "overlay";
      control-center-margin-top = 10;
      control-center-margin-bottom = 10;
      control-center-margin-left = 10;
      control-center-margin-right = 10;
      notification-window-width = 360;
      timeout = 3;
      timeout-critical = 0;
      transition-time = 200;
      max-notifications = 3;
      image-visibility = "when-available";
      control-center-width = 500;
      control-center-height = 600;
    };
  };

  # Enable Stylix theming for swaync
  stylix.targets.swaync.enable = true;
}
