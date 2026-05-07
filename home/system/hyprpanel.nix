{ config, pkgs, vars, ... }:

{
  programs.hyprpanel = {
    enable = true;
    settings = {
      bar = {
        layouts = {
          "*" = {
            left = [ "dashboard" "workspaces" "windowtitle" ];
            middle = [ "media" ];
            right = [ "prometheus" "volume" "battery" "network" "bluetooth" "systray" "notifications" "clock" ];
          };
        };
        clock = {
          format = "%a %b %d  %H:%M:%S";
        };
        weather = {
          unit = "metric";
        };
        customModules = {
          prometheus = {
            icon = "󰔏";
            label = true;
            pollingInterval = 5000;
            historyInterval = 30000;
            localUrl = "http://localhost:9090";
            remoteUrl = "http://100.71.144.104:9090";
          };
        };
        systray = {
          ignore = [ "nm-applet" "blueman" "blueman-tray" ];
        };
      };
      menus = {
        transition = "crossfade";
        clock = {
          time = {
            military = true;
          };
          weather = {
            unit = "metric";
            location = "Warsaw";
          };
        };
      };
      theme = {
        bar = {
          location = "top";
          label_spacing = "0.8em";
          scaling = 80;
          menus = {
            menu = {
              dashboard = {
                scaling = 65;
              };
              clock = {
                scaling = 70;
              };
            };
          };
        };
        font = {
          size = "1.0rem";
        };
      };
    };
  };
}
