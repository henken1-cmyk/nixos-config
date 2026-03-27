{ config, pkgs, lib, vars, ... }:

let
  # Minimal Hyprland config for the greeter — just monitors + regreet launch
  greeterHyprlandConfig = pkgs.writeText "greetd-hyprland.conf" ''
    ${lib.concatMapStringsSep "\n" (m: "monitor = ${m}") vars.monitors}

    # Place regreet login window on the right monitor
    windowrulev2 = monitor ${vars.monitorRight}, class:^(regreet)$

    misc {
      disable_hyprland_logo = true
      disable_splash_rendering = true
      force_default_wallpaper = 0
    }

    cursor {
      no_hardware_cursors = true
    }

    exec-once = ${lib.getExe config.programs.regreet.package}; hyprctl dispatch exit
  '';
in
{
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = lib.mkForce "Hyprland --config ${greeterHyprlandConfig}";
      user = "greeter";
    };
  };

  # Stylix expects cage as regreet compositor, but we use Hyprland — disable its target
  stylix.targets.regreet.enable = false;

  programs.regreet = {
    enable = true;
    settings = {
      background = {
        path = config.stylix.image;
        fit = "Cover";
      };
      GTK = {
        application_prefer_dark_theme = true;
      };
    };
    extraCss = ''
      button.destructive-action {
        background-image: linear-gradient(to top, #4a2475 2px, #5C2D91) !important;
        border-color: #3d1e61 !important;
        color: #ffffff !important;
        box-shadow: 0 1px 2px rgba(0, 0, 0, 0.07) !important;
      }
      button.destructive-action:hover {
        background-image: linear-gradient(to top, #5C2D91 20%, #6e36ad 90%) !important;
        border-color: #5C2D91 !important;
      }
      button.destructive-action:active,
      button.destructive-action:checked {
        background-image: linear-gradient(#4a2475, #4a2475) !important;
        box-shadow: none !important;
      }
    '';
  };

  # Ensure Hyprland is available as a session
  environment.etc."greetd/environments".text = ''
    Hyprland
  '';
}
