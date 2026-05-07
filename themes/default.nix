{ config, pkgs, lib, vars, scale, ... }:

let
  lightScheme = vars.base16SchemeLight or "solarized-light";

  resolveScheme = name:
    let local = ./. + "/${name}.yaml";
    in if builtins.pathExists local
       then local
       else "${pkgs.base16-schemes}/share/themes/${name}.yaml";

  theme-switch = pkgs.writeShellScriptBin "theme-switch" ''
    set -euo pipefail
    PROFILE="/nix/var/nix/profiles/system"
    case "''${1:-}" in
      light)
        [ -d "$PROFILE/specialisation/light" ] || { echo "No light specialisation" >&2; exit 1; }
        "$PROFILE/specialisation/light/bin/switch-to-configuration" switch
        ;;
      dark)
        "$PROFILE/bin/switch-to-configuration" switch
        ;;
      *)
        echo "Usage: theme-switch <dark|light>" >&2; exit 1
        ;;
    esac
  '';
in
{
  stylix = {
    enable = true;
    autoEnable = true;

    # Per-host theme (set in hosts/<name>/variables.nix). Falls back from local
    # ./<scheme>.yaml to pkgs.base16-schemes for upstream schemes.
    base16Scheme = resolveScheme vars.base16Scheme;
    polarity = "dark";

    # Wallpaper (required by Stylix even if swww/awww manages it)
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
        applications = scale.font.sm;
        desktop = scale.font.sm;
        popups = scale.font.sm;
        terminal = scale.font.sm;
      };
    };

    # Cursor
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = scale.size.cursor;
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
      grub.enable = true;
      console.enable = true;
      gtk.enable = true;
    };
  };

  # Light theme specialisation — pre-built at switch time, instant activation
  specialisation.light.configuration = {
    stylix.base16Scheme = lib.mkForce (resolveScheme lightScheme);
    stylix.polarity = lib.mkForce "light";
  };

  # Theme switcher (passwordless sudo for instant toggle)
  environment.systemPackages = [ theme-switch ];

  security.sudo.extraRules = [{
    users = [ vars.username ];
    commands = [{
      command = "/run/current-system/sw/bin/theme-switch";
      options = [ "NOPASSWD" ];
    }];
  }];
}
