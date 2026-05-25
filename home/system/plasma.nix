{ inputs, ... }:
{
  imports = [
    inputs.plasma-manager.homeModules.plasma-manager
  ];

  programs.plasma = {
    enable = true;

    # Mixing mode: plasma-manager writes only declared keys, GUI changes survive.
    # KDE System Settings stays a live editor; rc2nix snapshots what we promote.
    overrideConfig = false;

    # KWin compositor tunings for NVIDIA Wayland — reduce latency, keep
    # compositor engaged through fullscreen/DPMS, hold previews live so
    # Krohnkite re-tile after wake doesn't re-render from scratch.
    configFile.kwinrc.Compositing = {
      LatencyPolicy = "Low";
      WindowsBlockCompositing = false;
      HiddenPreviews = 5;
    };

    # Krohnkite auto-tiler (KWin script — pkgs.kdePackages.krohnkite in home/packages.nix)
    configFile.kwinrc.Plugins.krohnkiteEnabled = true;

    configFile.kwinrc."Script-krohnkite" = {
      screenGapTop = 8;
      screenGapBottom = 8;
      screenGapLeft = 8;
      screenGapRight = 8;
      screenGapBetween = 8;
      soleWindowNoBorders = true;
      soleWindowNoGaps = true;
      notificationDuration = 3000;
      floatedWindowsLayer = 2;
      tiledWindowsLayer = 1;
    };

    # Hyprland muscle memory ported to KDE. Krohnkite owns tiling; KWin owns
    # windowing/desktops. HJKL for tile navigation, Arrow keys stay on KWin
    # quick-tile (snap-to-edge).
    shortcuts = {
      # ---- Krohnkite: HJKL focus + shift, float, monocle ----
      kwin.KrohnkiteFocusLeft  = "Meta+H";
      kwin.KrohnkiteFocusDown  = "Meta+J";
      kwin.KrohnkiteFocusUp    = "Meta+K";
      kwin.KrohnkiteFocusRight = "Meta+L";

      kwin.KrohnkiteShiftLeft  = "Meta+Shift+H";
      kwin.KrohnkiteShiftDown  = "Meta+Shift+J";
      kwin.KrohnkiteShiftUp    = "Meta+Shift+K";
      kwin.KrohnkiteShiftRight = "Meta+Shift+L";

      # Hyprland: Meta+Space = togglefloating. Float lives here now, not on Meta+F.
      kwin.KrohnkiteToggleFloat = "Meta+Space";
      kwin.KrohnkiteFloatAll    = "Meta+Shift+Space";

      kwin.KrohnkiteMonocleLayout = "Meta+M";
      kwin.KrohnkiteFocusPrev     = "Meta+\\";

      # ---- Window state (Hyprland fullscreen) ----
      kwin."Window Maximize"   = "Meta+F";        # Hyprland: fullscreen 0
      kwin."Window Fullscreen" = "Meta+Shift+F";  # Hyprland: fullscreen 1
      kwin."Window Close"      = [ "Meta+Q" "Alt+F4" ];

      # KDE's Show Desktop on Meta+D collides with the app launcher; Hyprland has
      # no Show Desktop equivalent — vacate the chord.
      kwin."Show Desktop" = [ ];

      # ---- Virtual desktops Meta+1..9 (Hyprland workspaces) ----
      kwin."Switch to Desktop 1" = "Meta+1";
      kwin."Switch to Desktop 2" = "Meta+2";
      kwin."Switch to Desktop 3" = "Meta+3";
      kwin."Switch to Desktop 4" = "Meta+4";
      kwin."Switch to Desktop 5" = "Meta+5";
      kwin."Switch to Desktop 6" = "Meta+6";
      kwin."Switch to Desktop 7" = "Meta+7";
      kwin."Switch to Desktop 8" = "Meta+8";
      kwin."Switch to Desktop 9" = "Meta+9";

      kwin."Window to Desktop 1" = "Meta+Shift+1";
      kwin."Window to Desktop 2" = "Meta+Shift+2";
      kwin."Window to Desktop 3" = "Meta+Shift+3";
      kwin."Window to Desktop 4" = "Meta+Shift+4";
      kwin."Window to Desktop 5" = "Meta+Shift+5";
      kwin."Window to Desktop 6" = "Meta+Shift+6";
      kwin."Window to Desktop 7" = "Meta+Shift+7";
      kwin."Window to Desktop 8" = "Meta+Shift+8";
      kwin."Window to Desktop 9" = "Meta+Shift+9";

      kwin."Switch to Next Desktop"     = "Meta+Tab";
      kwin."Switch to Previous Desktop" = "Meta+Shift+Tab";

      # Hyprland: Meta+Shift+Left/Right = movetoworkspace ±1 (relative)
      kwin."Window to Previous Desktop" = "Meta+Shift+Left";
      kwin."Window to Next Desktop"     = "Meta+Shift+Right";

      # ---- Multi-monitor (comma = left, semicolon = right) ----
      kwin."Switch to Screen to the Left"  = "Meta+,";
      kwin."Switch to Screen to the Right" = "Meta+;";
      kwin."Window to Previous Screen"     = "Meta+Shift+,";
      kwin."Window to Next Screen"         = "Meta+Shift+;";

      # ---- Free up Meta+1..9 from taskbar-entry launches (collides with desktop switch) ----
      plasmashell."activate task manager entry 1" = [ ];
      plasmashell."activate task manager entry 2" = [ ];
      plasmashell."activate task manager entry 3" = [ ];
      plasmashell."activate task manager entry 4" = [ ];
      plasmashell."activate task manager entry 5" = [ ];
      plasmashell."activate task manager entry 6" = [ ];
      plasmashell."activate task manager entry 7" = [ ];
      plasmashell."activate task manager entry 8" = [ ];
      plasmashell."activate task manager entry 9" = [ ];

      # ---- App launcher (Hyprland: Meta+D → fuzzel; KDE: Kickoff) ----
      plasmashell."activate application launcher" = [ "Meta" "Alt+F1" "Meta+D" ];

      # ---- Session ----
      ksmserver."Log Out" = "Meta+BackSpace";  # Hyprland: power-menu.sh

      # ---- Free Meta+B from power profile (now Firefox) ----
      org_kde_powerdevil.powerProfile = [ ];

      # ---- App launches via .desktop (KDE-native stack) ----
      "services/org.kde.konsole.desktop"._launch = "Meta+Return";
      "services/org.kde.dolphin.desktop"._launch = "Meta+E";
      "services/firefox.desktop"._launch         = "Meta+B";

      # Vacate previous Hyprland-stack chord owners
      "services/com.mitchellh.ghostty.desktop"._launch = [ ];
      "services/thunar.desktop"._launch                 = [ ];

      # ---- Screenshots ----
      "services/org.kde.spectacle.desktop".RectangularRegionScreenShot = "Meta+Shift+S";
    };
  };
}
