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
    ../../home/system/waybar.nix
    ../../home/system/fuzzel.nix
    ../../home/system/mako.nix
    ../../home/system/hypridle.nix
    ../../home/system/hyprlock.nix
    ../../home/system/swww.nix
  ];

  # Lightspeed-specific packages
  home.packages = with pkgs; [
    headsetcontrol # Logitech headset sidetone/battery control
    easyeffects    # PipeWire EQ/compression for mic & output
  ];

  home = {
    username = vars.username;
    homeDirectory = "/home/${vars.username}";
    stateVersion = "24.11";

    # Ensure common directories exist
    file.".local/share/wallpapers/.keep".text = "";

    # Stylix Solarized theme for Flatpak Vesktop
    file.".var/app/dev.vencord.Vesktop/config/vesktop/themes/stylix.theme.css".text =
      config.stylix.targets.vesktop.themeBody;
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Cursor config handled by Stylix (themes/default.nix)

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
      setSessionVariables = true;
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
  stylix.targets.firefox.colorTheme.enable = true;
  stylix.targets.waybar.enable = false; # Custom CSS in waybar.nix

  # bat (theme set by Stylix, cache rebuild skipped at boot for speed)
  programs.bat.enable = true;
  stylix.targets.bat.enable = false;
  home.activation.batCache = lib.mkForce (lib.hm.dag.entryAnywhere ""); # skip ~3s bat cache --build

  # hyprpaper disabled — swww handles wallpaper (hyprpaper 0.8.3 has crash bug)
  stylix.targets.hyprpaper.enable = lib.mkForce false;
  services.hyprpaper.enable = lib.mkForce false;

  # HyprPanel expects an image at ~/.config/background for its swww integration
  home.file.".config/background".source = config.stylix.image;

  # bottom (btm)
  programs.bottom.enable = true;
}
