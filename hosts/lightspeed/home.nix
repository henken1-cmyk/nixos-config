{ config, pkgs, inputs, lib, ... }:

let
  vars = import ./variables.nix;
in
{
  imports = [
    inputs.hyprland.homeManagerModules.default
    inputs.nixvim.homeModules.nixvim
    ../../home/packages.nix
    # Programs
    ../../home/programs/browser.nix
    ../../home/programs/pwas.nix
    ../../home/programs/claude-desktop.nix
    ../../home/programs/editor.nix
    ../../home/programs/fish.nix
    ../../home/programs/ghostty.nix
    ../../home/programs/git.nix
    ../../home/programs/neovim.nix
    ../../home/programs/spotify.nix
    ../../home/programs/yazi.nix
    ../../home/programs/vesktop.nix
    ../../home/programs/zellij.nix
    # Desktop environment
    ../../home/system/hyprland.nix
    ../../home/system/hyprpanel.nix
    ../../home/system/fuzzel.nix
    # Notifications handled by HyprPanel's built-in notification daemon
    ../../home/system/hypridle.nix
    ../../home/system/hyprlock.nix
    ../../home/system/swww.nix
    ../../home/system/plasma.nix
  ];

  # Lightspeed-specific packages
  home.packages = with pkgs; [
    # Browser with Wayland decorations + Vulkan ANGLE (lightspeed-only — NVIDIA desktop)
    (google-chrome.override {
      commandLineArgs = [
        "--enable-features=WaylandWindowDecorations,WebGPUService"
        "--use-angle=vulkan"
        "--ignore-gpu-blocklist"
      ];
    })
    headsetcontrol # Logitech headset sidetone/battery control
    easyeffects    # PipeWire EQ/compression for mic & output
    qbittorrent
    obs-studio
    obsidian
    # Gaming
    wineWow64Packages.stagingFull  # Wine 32+64-bit with all features
    winetricks                      # Windows dependency installer (vcredist, .NET, fonts)
    lutris                          # Game manager / launcher for non-Steam games
    mangohud                        # FPS/GPU/CPU performance overlay
    protonup-qt                     # Manage Wine-GE/Proton-GE runners
  ];

  home = {
    username = vars.username;
    homeDirectory = "/home/${vars.username}";
    stateVersion = "24.11";

    # Ensure common directories exist
    file.".local/share/wallpapers/.keep".text = "";

    # Stylix Solarized theme for Vesktop (native nixpkgs, not Flatpak)
    file.".config/vesktop/themes/stylix.theme.css" = {
      text = config.stylix.targets.vesktop.themeBody;
      force = true;
    };

    # KDE rewrites ~/.gtkrc-2.0 on every session; the stale .hm-backup from a
    # prior HM run would otherwise block the next activation. Drop it first.
    activation.cleanGtkrcBackup = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      rm -f $HOME/.gtkrc-2.0.hm-backup
    '';
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Cursor config handled by Stylix (themes/default.nix)
  # Qt theming intentionally NOT configured: stylix.targets.qt is disabled
  # in nixos/plasma6.nix so QT_STYLE_OVERRIDE never gets exported (Plasma 6
  # treats it as a QQC2 QML import and fails on any widget-style name).

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
  stylix.targets.firefox.colorTheme.enable = true;

  # bat (theme set by Stylix, cache rebuild skipped at boot for speed)
  stylix.targets.bat.enable = false;
  home.activation.batCache = lib.mkForce (lib.hm.dag.entryAnywhere "");

  # hyprpaper disabled — awww handles wallpaper (hyprpaper 0.8.3 has crash bug)
  stylix.targets.hyprpaper.enable = lib.mkForce false;
  services.hyprpaper.enable = lib.mkForce false;

  # HyprPanel expects an image at ~/.config/background for its awww integration
  home.file.".config/background".source = config.stylix.image;

  # Daemon services (managed by Home Manager systemd units)
  services.cliphist.enable = true;
  services.udiskie = { enable = true; tray = "always"; };
  services.network-manager-applet.enable = true;
  services.swayosd.enable = true;
  # Prevent swayosd crash loop — tighten restart limits
  systemd.user.services.swayosd = {
    Unit.StartLimitBurst = lib.mkForce 3;
    Unit.StartLimitIntervalSec = lib.mkForce 60;
    Service.RestartSec = lib.mkForce "5s";
  };
  services.gnome-keyring = { enable = true; components = [ "secrets" "ssh" ]; };

  # Hyprsunset (no built-in HM service)
  systemd.user.services.hyprsunset = {
    Unit.Description = "Hyprsunset blue light filter";
    Service = { ExecStart = "${pkgs.hyprsunset}/bin/hyprsunset"; Restart = "on-failure"; };
    Install.WantedBy = [ "hyprland-session.target" ];
  };

  # Gate Hyprland-only HM services to hyprland-session.target so they don't
  # autostart under KDE (where they crash or duplicate KDE's own daemons).
  # hyprland-session.target is provided by the Hyprland HM module.
  #
  # WantedBy alone is not enough: graphical-session.target can transitively pull
  # these in under KDE. ConditionEnvironment is a runtime gate that makes the
  # unit condition-skip whenever XDG_CURRENT_DESKTOP is not "Hyprland".
  systemd.user.services.hyprpanel.Install.WantedBy = lib.mkForce [ "hyprland-session.target" ];
  systemd.user.services.hypridle.Install.WantedBy = lib.mkForce [ "hyprland-session.target" ];
  systemd.user.services.swayosd.Install.WantedBy = lib.mkForce [ "hyprland-session.target" ];
  systemd.user.services.cliphist.Install.WantedBy = lib.mkForce [ "hyprland-session.target" ];
  systemd.user.services.cliphist-images.Install.WantedBy = lib.mkForce [ "hyprland-session.target" ];
  systemd.user.services.network-manager-applet.Install.WantedBy = lib.mkForce [ "hyprland-session.target" ];
  systemd.user.services.udiskie.Install.WantedBy = lib.mkForce [ "hyprland-session.target" ];

  # XDG_CURRENT_DESKTOP=Hyprland is strictly stronger than the HM modules'
  # default WAYLAND_DISPLAY check (only set in Hyprland; implies Wayland).
  systemd.user.services.hyprpanel.Unit.ConditionEnvironment = lib.mkForce "XDG_CURRENT_DESKTOP=Hyprland";
  systemd.user.services.hypridle.Unit.ConditionEnvironment = lib.mkForce "XDG_CURRENT_DESKTOP=Hyprland";
  systemd.user.services.swayosd.Unit.ConditionEnvironment = lib.mkForce "XDG_CURRENT_DESKTOP=Hyprland";
  systemd.user.services.cliphist.Unit.ConditionEnvironment = lib.mkForce "XDG_CURRENT_DESKTOP=Hyprland";
  systemd.user.services.cliphist-images.Unit.ConditionEnvironment = lib.mkForce "XDG_CURRENT_DESKTOP=Hyprland";
  systemd.user.services.network-manager-applet.Unit.ConditionEnvironment = lib.mkForce "XDG_CURRENT_DESKTOP=Hyprland";
  systemd.user.services.udiskie.Unit.ConditionEnvironment = lib.mkForce "XDG_CURRENT_DESKTOP=Hyprland";

  # bat (theme set by Stylix)
  programs.bat.enable = true;

  # bottom (btm)
  programs.bottom.enable = true;
}
