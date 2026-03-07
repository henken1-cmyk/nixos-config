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
            right = [ "prometheus" "volume" "network" "bluetooth" "systray" "notifications" "clock" ];
          };
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
      };
      menus = {
        transition = "crossfade";
      };
      theme = {
        bar = {
          location = "top";
        };
      };
    };
  };
}
