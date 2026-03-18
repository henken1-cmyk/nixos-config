#!/usr/bin/env bash
# Toggle between dark and light Stylix theme (NixOS specialisation)
# Both themes are pre-built at `nh os switch` time — switching is instant

PROFILE="/nix/var/nix/profiles/system"

# Detect current state by comparing system closures
CURRENT_SYSTEM=$(readlink -f /run/current-system)
LIGHT_SYSTEM=$(readlink -f "$PROFILE/specialisation/light" 2>/dev/null || echo "")

if [ "$CURRENT_SYSTEM" = "$LIGHT_SYSTEM" ]; then
  TARGET="dark"
else
  TARGET="light"
fi

if sudo /run/current-system/sw/bin/theme-switch "$TARGET"; then
  # Help GTK apps adapt immediately
  if [ "$TARGET" = "light" ]; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' 2>/dev/null
  else
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null
  fi

  # Reload Hyprland to pick up new border colors
  hyprctl reload 2>/dev/null

  notify-send "Theme" "Switched to $TARGET" --icon=preferences-desktop-theme
else
  notify-send "Theme" "Failed to switch theme" --icon=dialog-error
fi
