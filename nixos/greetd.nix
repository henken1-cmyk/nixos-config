{ config, pkgs, lib, vars, ... }:

let
  # Minimal Hyprland config for the greeter — just monitors + regreet launch
  greeterHyprlandConfig = pkgs.writeText "greetd-hyprland.conf" ''
    ${lib.concatMapStringsSep "\n" (m: "monitor = ${m}") vars.monitors}

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
  };

  # Ensure Hyprland is available as a session
  environment.etc."greetd/environments".text = ''
    Hyprland
  '';
}
