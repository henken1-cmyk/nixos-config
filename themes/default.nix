{ config, pkgs, vars, ... }:

{
  stylix = {
    enable = true;
    autoEnable = true;

    # Per-host theme (set in hosts/<name>/variables.nix)
    base16Scheme = ./biskupi-fiolet.yaml;
    polarity = "dark";

    # Wallpaper (required by Stylix even if swww manages it)
    image = pkgs.fetchurl {
      url = "https://images.unsplash.com/photo-1462331940025-496dfbfc7564?w=3840";
      sha256 = "0viv6dq66in3rw8yp8d5gjp34wcv4nc78rhc1za1dmi08vzh03i2";
      name = "space-solarized-wallpaper.jpg";
    };

    # Fonts
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.sauce-code-pro;
        name = "SauceCodePro Nerd Font";
      };
      sansSerif = {
        package = pkgs.noto-fonts;
        name = "Noto Sans";
      };
      serif = {
        package = pkgs.noto-fonts;
        name = "Noto Serif";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        applications = 11;
        desktop = 11;
        popups = 11;
        terminal = 13;
      };
    };

    # Cursor
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };

    # Opacity
    opacity = {
      applications = 1.0;
      desktop = 0.85;
      popups = 0.95;
      terminal = 0.9;
    };

    # Targets — Stylix auto-applies to most, but we can override
    targets = {
      grub.enable = false; # We use systemd-boot
      console.enable = false; # Disabled — boot.nix sets all-black palette to hide VT during transitions
      gtk.enable = true;
    };
  };
}
