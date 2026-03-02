{ config, ... }:

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
      notification-margin-top = 10;
      notification-margin-bottom = 10;
      notification-margin-left = 10;
      notification-margin-right = 10;
      notification-window-width = 360;
      notification-body-image-height = 100;
      notification-body-image-width = 200;
      timeout = 3;
      timeout-critical = 0;
      transition-time = 200;
      max-notifications = 3;
      keyboard-shortcuts = true;
      image-visibility = "when-available";
      summary-visibility = "when-available";
      body-visibility = "when-available";
      scripts = { };
      notification-icon-size = 32;
      control-center-width = 500;
      control-center-height = 600;
      scale = 1;
      margin-top = 18;
      margin-bottom = 18;
      margin-left = 18;
      margin-right = 18;
    };
  };

  # Enable Stylix theming for swaync
  stylix.targets.swaync.enable = true;
}
