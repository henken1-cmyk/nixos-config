{ pkgs, scale, ... }:

let
  focus-window = pkgs.writeShellScript "swaync-focus-window" ''
    # Focus the Hyprland window that sent the notification.
    # For apps with multiple windows (e.g. Ghostty), match by title from
    # the notification summary; fall back to class match.
    window_class="''${SWAYNC_DESKTOP_ENTRY:-$SWAYNC_APP_NAME}"
    summary="$SWAYNC_SUMMARY"

    if [ -n "$summary" ]; then
      # Try title match first (handles multi-window apps like Ghostty)
      addr=$(hyprctl clients -j | ${pkgs.jq}/bin/jq -r \
        --arg title "$summary" \
        '[.[] | select(.title | test($title; "i"))] | first | .address // empty' 2>/dev/null)
      if [ -n "$addr" ]; then
        hyprctl dispatch focuswindow "address:$addr" 2>/dev/null
        exit 0
      fi
    fi
    [ -n "$window_class" ] && hyprctl dispatch focuswindow "class:(?i)$window_class" 2>/dev/null
  '';
in
{
  services.swaync = {
    enable = true;
    settings = {
      positionX = "left";
      positionY = "bottom";
      layer = "overlay";
      control-center-layer = "overlay";
      control-center-margin-top = scale.gap.lg;
      control-center-margin-bottom = scale.gap.lg;
      control-center-margin-left = scale.gap.lg;
      control-center-margin-right = scale.gap.lg;
      notification-window-width = scale.container.notification;
      timeout = 10;
      timeout-critical = 0;
      transition-time = 200;
      max-notifications = 3;
      image-visibility = "when-available";
      control-center-width = scale.container.panel;
      control-center-height = scale.container.panelHeight;
      scripts = {
        focus-window = {
          exec = "${focus-window}";
          run-on = "action";
        };
      };
    };
  };

  # Enable Stylix theming for swaync (override double border)
  stylix.targets.swaync.enable = true;
  services.swaync.style = ''
    .notification-content {
      border: none;
    }
  '';
}
