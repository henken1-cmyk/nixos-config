{ config, pkgs, lib, scale, ... }:

let
  colors = config.lib.stylix.colors;
in
{
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = false;
        grace = 3;
        hide_cursor = true;
        no_fade_in = false;
      };

      background = lib.mkForce [{
        path = "screenshot";
        blur_passes = 3;
        blur_size = 8;
        noise = 0.02;
        contrast = 0.9;
        brightness = 0.7;
        vibrancy = 0.17;
      }];

      label = lib.mkForce [
        # Clock
        {
          text = "cmd[update:1000] echo $(date +%H:%M)";
          font_size = scale.font.hero;
          font_family = "SauceCodePro Nerd Font";
          position = "0, 150";
          halign = "center";
          valign = "center";
          color = "rgb(${colors.base05})";
        }
        # Date
        {
          text = "cmd[update:60000] echo $(date '+%A, %B %d')";
          font_size = scale.font.lg;
          font_family = "Noto Sans";
          position = "0, 70";
          halign = "center";
          valign = "center";
          color = "rgb(${colors.base04})";
        }
        # Username
        {
          text = "Hi, $USER";
          font_size = scale.font.md;
          font_family = "Noto Sans";
          position = "0, -30";
          halign = "center";
          valign = "center";
          color = "rgb(${colors.base02})";
        }
      ];

      input-field = lib.mkForce [{
        size = "${toString scale.container.notification}, ${toString scale.size.input}";
        outline_thickness = 2;
        dots_size = 0.25;
        dots_spacing = 0.3;
        dots_center = true;
        fade_on_empty = true;
        fade_timeout = 2000;
        placeholder_text = "<i>Password...</i>";
        hide_input = false;
        position = "0, -100";
        halign = "center";
        valign = "center";
        outer_color = "rgb(${colors.base01})";
        inner_color = "rgb(${colors.base00})";
        font_color = "rgb(${colors.base05})";
        check_color = "rgb(${colors.base0A})";
        fail_color = "rgb(${colors.base08})";
        capslock_color = "rgb(${colors.base09})";
      }];
    };
  };
}
