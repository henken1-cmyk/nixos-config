{ config, pkgs, ... }:

{
  programs.zellij = {
    enable = true;
    # Settings written as raw KDL below to support keybinds syntax
  };

  xdg.configFile."zellij/config.kdl".text = ''
    theme "default"
    default_layout "default"
    pane_frames true
    simplified_ui false

    ui {
      pane_frames {
        rounded_corners true
      }
    }

    keybinds {
      shared {
        bind "Ctrl Tab" { GoToNextTab; }
        bind "Ctrl Shift Tab" { GoToPreviousTab; }
      }
    }
  '';
}
