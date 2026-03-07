{ config, pkgs, lib, vars, scale, ... }:

let
  colors = config.lib.stylix.colors;
  # Hyprland config for the greeter — monitors, blur, animations, regreet launch
  greeterHyprlandConfig = pkgs.writeText "greetd-hyprland.conf" ''
    ${lib.concatMapStringsSep "\n" (m: "monitor = ${m}") vars.monitors}

    misc {
      disable_hyprland_logo = true
      disable_splash_rendering = true
      force_default_wallpaper = 0
      disable_watchdog_warning = true
    }

    cursor {
      no_hardware_cursors = true
    }

    decoration {
      rounding = ${toString scale.radius.lg}

      blur {
        enabled = true
        size = ${toString scale.gap.md}
        passes = 3
        new_optimizations = true
        noise = 0.02
        brightness = 0.8
      }

      shadow {
        enabled = true
        range = 20
        render_power = 3
      }

      active_opacity = 0.95
      inactive_opacity = 0.95
    }

    animations {
      enabled = true
      bezier = ease, 0.25, 0.1, 0.25, 1.0
      animation = windows, 1, 5, ease, slide
      animation = fade, 1, 4, ease
    }

    windowrule = match:class ^(regreet)$, float on
    windowrule = match:class ^(regreet)$, size ${toString scale.container.window} ${toString scale.container.panel}
    windowrule = match:class ^(regreet)$, center on

    exec-once = ${lib.getExe config.programs.regreet.package}; hyprctl dispatch exit
  '';
in
{
  # Stylix auto-applies Solarized Dark colors, fonts, cursor to ReGreet
  stylix.targets.regreet.enable = true;

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "Hyprland --config ${greeterHyprlandConfig}";
      user = "greeter";
    };
  };

  programs.regreet = {
    enable = true;
    extraCss = lib.mkForce ''
      /* Base16 color definitions (from Stylix) */
      @define-color window_bg_color #${colors.base00};
      @define-color window_fg_color #${colors.base04};
      @define-color view_bg_color #${colors.base01};
      @define-color view_fg_color #${colors.base05};
      @define-color headerbar_bg_color #${colors.base01};
      @define-color headerbar_fg_color #${colors.base05};
      @define-color headerbar_border_color #${colors.base02};
      @define-color accent_bg_color #${colors.base0D};
      @define-color accent_fg_color #${colors.base07};
      @define-color accent_color #${colors.base0D};
      @define-color destructive_bg_color #${colors.base08};
      @define-color destructive_fg_color #${colors.base07};
      @define-color success_bg_color #${colors.base0B};
      @define-color success_fg_color #${colors.base07};
      @define-color warning_bg_color #${colors.base0A};
      @define-color warning_fg_color #${colors.base07};
      @define-color error_bg_color #${colors.base08};
      @define-color error_fg_color #${colors.base07};
      @define-color card_bg_color #${colors.base01};
      @define-color card_fg_color #${colors.base05};
      @define-color borders alpha(#${colors.base02}, 0.5);

      /* Semi-transparent login card over wallpaper */
      frame.background {
        border-radius: ${scale.px scale.radius.xl};
        padding: ${scale.px scale.gap.xxl};
        box-shadow: 0 ${scale.px scale.gap.md} ${scale.px scale.gap.xxl} rgba(0, 0, 0, 0.5);
        background-color: alpha(@window_bg_color, 0.82);
        border: 1px solid alpha(@headerbar_border_color, 0.15);
      }

      /* Refined input fields */
      entry, passwordentry {
        border-radius: ${scale.px scale.radius.md};
        padding: ${scale.px scale.gap.md} ${scale.px scale.gap.lg};
        min-height: ${scale.px scale.size.input};
        background-color: @view_bg_color;
        color: @view_fg_color;
        border: 1px solid alpha(@borders, 0.5);
        transition: border-color 200ms ease, box-shadow 200ms ease;
      }
      entry:focus, passwordentry:focus {
        border-color: @accent_bg_color;
        box-shadow: 0 0 0 ${scale.px scale.border.normal} alpha(@accent_bg_color, 0.25);
      }

      /* Polished login button */
      button.suggested-action {
        border-radius: ${scale.px scale.radius.md};
        padding: ${scale.px scale.gap.md} ${scale.px scale.gap.xxl};
        min-height: ${scale.px scale.size.input};
        font-weight: bold;
        background-color: @accent_bg_color;
        color: @accent_fg_color;
      }

      /* Subtle power buttons */
      button.destructive-action {
        border-radius: ${scale.px scale.radius.md};
        opacity: 0.7;
        transition: opacity 150ms ease;
      }
      button.destructive-action:hover {
        opacity: 1.0;
      }

      /* Welcome text */
      #message_label {
        font-size: ${scale.px scale.font.lg};
        font-weight: bold;
        margin-bottom: ${scale.px scale.gap.lg};
        color: @headerbar_fg_color;
      }

      /* Labels */
      label {
        color: @window_fg_color;
      }

      combobox button {
        border-radius: 8px;
      }
    '';
    settings = {
      background = {
        path = config.stylix.image;
        fit = "Cover";
      };
      GTK = {
        application_prefer_dark_theme = true;
      };
      appearance.greeting_msg = "Welcome back!";
      widget.clock = {
        format = "%A, %B %e   %H:%M";
        resolution = "500ms";
      };
    };
  };

  # Ensure Hyprland is available as a session
  environment.etc."greetd/environments".text = ''
    Hyprland
  '';
}
