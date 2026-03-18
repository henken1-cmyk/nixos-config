#!/usr/bin/env bash
# Power menu via fuzzel dmenu

OPTIONS="🔒 Lock\n🚪 Logout\n🔄 Reboot\n⏻ Shutdown\n💤 Hibernate"
LINES=5

# Add Windows reboot option if GRUB entry exists
WINDOWS_ENTRY_ID="${POWER_MENU_WINDOWS_BOOT_ENTRY:-}"
if [[ -n "$WINDOWS_ENTRY_ID" ]]; then
  OPTIONS+="\n🪟 Reboot to Windows"
  LINES=6
fi

CHOICE=$(echo -e "$OPTIONS" | fuzzel --dmenu --prompt="Power ❯ " --width=20 --lines=$LINES)

case "$CHOICE" in
  "🔒 Lock")
    grim /tmp/hyprlock-screenshot.png && hyprlock
    ;;
  "🚪 Logout")
    hyprctl dispatch exit
    ;;
  "🔄 Reboot")
    systemctl reboot
    ;;
  "⏻ Shutdown")
    systemctl poweroff
    ;;
  "💤 Hibernate")
    systemctl hibernate
    ;;
  "🪟 Reboot to Windows")
    sudo grub-reboot "$WINDOWS_ENTRY_ID"
    systemctl reboot
    ;;
esac
