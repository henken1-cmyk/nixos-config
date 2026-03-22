{ config, pkgs, inputs, lib, ... }:

let
  vars = import ./variables.nix;
in
{
  imports = [
    inputs.nixvim.homeModules.nixvim
    ../../home/packages.nix
    # Programs
    ../../home/programs/browser.nix
    ../../home/programs/editor.nix
    ../../home/programs/fish.nix
    ../../home/programs/ghostty.nix
    ../../home/programs/git.nix
    ../../home/programs/neovim.nix
    ../../home/programs/yazi.nix
    ../../home/programs/zellij.nix
    # Desktop environment
    ../../home/system/hyprland.nix
    ../../home/system/hyprpanel.nix     # Wariant A: HyprPanel
    # ../../home/system/ags-bar.nix    # Wariant B: AGS bar
    ../../home/system/fuzzel.nix
    # ../../home/system/mako.nix  # AGS bar handles notifications via notifd
    ../../home/system/hypridle.nix
    ../../home/system/hyprlock.nix
    ../../home/system/swww.nix
  ];

  # Adam-specific packages
  home.packages = with pkgs; [
    google-chrome
    parsec-bin
    remmina    # RDP/VNC client (GUI)
    freerdp    # RDP library used by Remmina
    v4l-utils  # Camera/video device tools (laptop only)
  ];

  home = {
    username = vars.username;
    homeDirectory = "/home/${vars.username}";
    stateVersion = "24.11";

    # Ensure common directories exist
    file.".local/share/wallpapers/.keep".text = "";
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Qt theming
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";
  };

  # GTK
  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  # XDG
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "${config.home.homeDirectory}/Desktop";
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      videos = "${config.home.homeDirectory}/Videos";
    };
    mimeApps.enable = true;
  };

  # Direnv + nix-direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Zoxide
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  # fzf
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  # Stylix: tell it which Firefox profile to theme
  stylix.targets.firefox.profileNames = [ "default" ];
  # stylix.targets.waybar.enable = false; # Waybar replaced by HyprPanel

  # bat (theme set by Stylix, cache rebuild disabled for faster boot)
  programs.bat.enable = true;
  stylix.targets.bat.enable = false;

  # bottom (btm)
  programs.bottom.enable = true;
}
