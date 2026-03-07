{ config, pkgs, scale, ... }:

{
  programs.ghostty = {
    enable = true;
    settings = {
      # Font (Stylix handles colors)
      font-family = "SauceCodePro Nerd Font";
      font-size = scale.font.sm;

      # Window
      window-padding-x = scale.gap.md;
      window-padding-y = scale.gap.md;
      window-decoration = false; # Wayland — no CSD
      gtk-titlebar = false;

      # Cursor
      cursor-style = "block";
      cursor-style-blink = true;

      # Scrollback
      scrollback-limit = 100000;

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
    };
  };
}
