{ config, pkgs, ... }:

{
  programs.ghostty = {
    enable = true;
    settings = {
      # Font (Stylix handles colors)
      font-family = "SauceCodePro Nerd Font";
      font-size = 13;

      # Window
      window-padding-x = 8;
      window-padding-y = 8;
      window-decoration = false; # Wayland — no CSD
      gtk-titlebar = false;

      # Cursor
      cursor-style = "block";
      cursor-style-blink = true;

      # Scrollback
      scrollback-limit = 10000;

      # Mouse
      mouse-hide-while-typing = true;

      # Shell — Fish handles Zellij auto-attach
      # command is not set; uses user's default shell (fish)

      # Performance
      font-thicken = true;

      # Clipboard
      clipboard-read = "allow";
      clipboard-write = "allow";
      clipboard-paste-protection = false;

      # Bell
      #audible-bell = false;
      #visual-bell = false;

      # Confirm close
      confirm-close-surface = false;

      # Pass Ctrl+Tab / Ctrl+Shift+Tab to terminal (Zellij tab switching)
      keybind = [
        "ctrl+tab=unbind"
        "ctrl+shift+tab=unbind"
      ];
    };
  };
}
