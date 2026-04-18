{ config, pkgs, lib, vars, ... }:

let
  # Loading screen shown immediately when Hyprland starts, before the wallpaper.
  # Matches theme background with subtle centered text.
  loadingScreen = pkgs.runCommand "loading-screen.png" {
    nativeBuildInputs = [ pkgs.imagemagick pkgs.dejavu_fonts ];
  } ''
    magick -size 1920x1080 xc:'#1c0e2e' \
      -font '${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSans.ttf' \
      -fill '#8878a0' -gravity center -pointsize 32 \
      -annotate 0 "Loading..." \
      png:$out
  '';
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;

    settings = {
      # ── Monitors ──────────────────────────────────────────
      # CHANGEME: update monitor names after first boot with `hyprctl monitors`
      monitor = vars.monitors;

      # ── Input ─────────────────────────────────────────────
      input = {
        kb_layout = vars.keyboardLayout;
        kb_variant = vars.keyboardVariant;
        follow_mouse = 1;
        sensitivity = 0;
        accel_profile = "flat";

        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
          disable_while_typing = true;
        };
      };

      # ── General ───────────────────────────────────────────
      general = {
        gaps_in = 4;
        gaps_out = if (vars.waybarAutohide or false) then 0 else 8;
        border_size = 2;
        layout = "dwindle";
        allow_tearing = false;
        # Colors handled by Stylix
      };

      # ── Decoration ────────────────────────────────────────
      decoration = {
        rounding = 5;

        blur = {
          enabled = true;
          size = 6;
          passes = 3;
          new_optimizations = true;
          xray = false;
          noise = 0.02;
        };

        # Opacity
        active_opacity = 1.0;
        inactive_opacity = 0.85;
        fullscreen_opacity = 1.0;

        shadow = {
          enabled = true;
          range = 12;
          render_power = 3;
        };
      };

      # ── Animations ────────────────────────────────────────
      animations = {
        enabled = true;
        bezier = [
          "ease, 0.25, 0.1, 0.25, 1.0"
          "easeOut, 0, 0, 0.58, 1.0"
          "easeInOut, 0.42, 0, 0.58, 1.0"
        ];
        animation = [
          "windows, 1, 4, ease, slide"
          "windowsOut, 1, 4, easeOut, slide"
          "fade, 1, 3, ease"
          "workspaces, 1, 4, easeInOut, slide"
          "border, 1, 5, ease"
        ];
      };

      # ── Layout ────────────────────────────────────────────
      dwindle = {
        pseudotile = true;
        preserve_split = true;
        force_split = 2; # Always split to the right/bottom
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = true;
        vfr = true;
      };

      # ── NVIDIA / Multi-monitor ──────────────────────────────
      cursor = {
        no_hardware_cursors = true; # Replaces deprecated WLR_NO_HARDWARE_CURSORS
      };

      render = {
        direct_scanout = false; # Prevents page-flip errors on mixed refresh rate monitors
      };

      # ── XWayland ──────────────────────────────────────────
      xwayland = {
        force_zero_scaling = true;
      };

      # ── Workspaces ────────────────────────────────────────
      # 1-9 across both monitors, Hyprland decides placement
      # No explicit workspace-to-monitor binding

      # ── Layer Rules ────────────────────────────────────────
      layerrule = [
        # HyprPanel blur rules
        "match:namespace = bar-0, blur 1"
        "match:namespace = bar-0, ignore_alpha 0.6"
      ];

      # ── Window Rules (v3 syntax, Hyprland 0.53+) ─────────
      windowrule = [
        # Float utility windows
        "match:class ^(thunar)$, float on"
        "match:class ^(thunar)$, size 1000 700"
        "match:class ^(pavucontrol)$, float on"
        "match:class ^(pavucontrol)$, size 800 600"
        "match:class ^(blueman-manager)$, float on"
        "match:class ^(blueman-manager)$, size 700 500"
        "match:class ^(nm-connection-editor)$, float on"
        "match:class ^(.blueman-manager-wrapped)$, float on"
        "match:class ^(system-config-printer)$, float on"

        # Float file dialogs
        "match:title ^(Open File)$, float on"
        "match:title ^(Open File)$, size 1000 700"
        "match:title ^(Open File)$, center 1"
        "match:title ^(Save File)$, float on"
        "match:title ^(Save File)$, size 1000 700"
        "match:title ^(Save File)$, center 1"
        "match:title ^(Open Folder)$, float on"
        "match:title ^(Open Folder)$, size 1000 700"
        "match:title ^(Open Folder)$, center 1"
        "match:title ^(Save As)$, float on"
        "match:title ^(Save As)$, size 1000 700"
        "match:title ^(Save As)$, center 1"
        "match:title ^(File Upload)$, float on"
        "match:title ^(File Upload)$, size 1000 700"
        "match:title ^(File Upload)$, center 1"

        # xdg-desktop-portal file dialogs (catch-all for portal-based pickers)
        "match:class ^(xdg-desktop-portal-gtk)$, float on"
        "match:class ^(xdg-desktop-portal-gtk)$, size 1000 700"
        "match:class ^(xdg-desktop-portal-gtk)$, center 1"

        # Float polkit
        "match:class ^(polkit-gnome-authentication-agent-1)$, float on"

        # Float KeePassXC
        "match:class ^(org.keepassxc.KeePassXC)$, float on"
        "match:class ^(org.keepassxc.KeePassXC)$, size 1000 700"

        # Picture-in-picture
        "match:title ^(Picture-in-Picture)$, float on"
        "match:title ^(Picture-in-Picture)$, pin on"
        "match:title ^(Picture-in-Picture)$, size 480 270"

        # Satty screenshot editor
        "match:class ^(satty)$, float on"

        # Immediate focus for dialogs
        "match:class ^(polkit-gnome-authentication-agent-1)$, stay_focused on"
      ];

      # ── Keybinds ──────────────────────────────────────────
      "$mod" = "SUPER";

      bind = [
        # ─ Core ─
        "$mod, Return, exec, ghostty"
        "$mod, Q, killactive"
        "$mod SHIFT, Q, exec, hyprctl kill" # Force kill (click to select)
        "$mod, D, exec, fuzzel"
        "$mod, L, exec, hyprlock"
        "$mod, Space, togglefloating"

        # ─ Apps ─
        "$mod, E, exec, thunar"
        "$mod SHIFT, E, exec, ghostty -e yazi"
        "$mod, B, exec, firefox"

        # ─ Window focus (arrows) ─
        "$mod, Left, movefocus, l"
        "$mod, Right, movefocus, r"
        "$mod, Up, movefocus, u"
        "$mod, Down, movefocus, d"

        # ─ Window swap (Ctrl+arrows) ─
        "$mod CTRL, Left, swapwindow, l"
        "$mod CTRL, Right, swapwindow, r"
        "$mod CTRL, Up, swapwindow, u"
        "$mod CTRL, Down, swapwindow, d"

        # ─ Move window to workspace (Shift+number) ─
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"

        # ─ Move window to workspace (Shift+arrows, spatial) ─
        "$mod SHIFT, Left, movetoworkspace, -1"
        "$mod SHIFT, Right, movetoworkspace, +1"

        # ─ Workspace switch ─
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"

        # ─ Workspace cycling ─
        "$mod, Tab, workspace, e+1"
        "$mod SHIFT, Tab, workspace, e-1"
        "ALT, Tab, workspace, previous"

        # ─ Layout ─
        "$mod, F, fullscreen, 0"
        "$mod SHIFT, F, fullscreen, 1" # Fake fullscreen / monocle
        "$mod, P, pseudo" # Pseudo-tile

        # ─ Resize mode ─
        "$mod, R, submap, resize"

        # ─ Screenshots ─
        ", Print, exec, grim - | satty --filename -"
        "$mod SHIFT, S, exec, grim -g \"$(slurp)\" - | wl-copy"

        # ─ Clipboard ─
        "$mod, V, exec, cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"

        # ─ Power menu ─
        "$mod, BackSpace, exec, $HOME/.config/nixos/home/scripts/power-menu.sh"

        # ─ Emoji picker ─
        "$mod, period, exec, bemoji -t"

        # ─ Screen recording toggle ─
        "$mod SHIFT, R, exec, $HOME/.config/nixos/home/scripts/screen-record.sh"

        # ─ Monitor focus ─
        "$mod, comma, focusmonitor, l"
        "$mod SHIFT, comma, movewindow, mon:l"
        "$mod CTRL, comma, movecurrentworkspacetomonitor, l"

        "$mod, semicolon, focusmonitor, r"
        "$mod SHIFT, semicolon, movewindow, mon:r"
        "$mod CTRL, semicolon, movecurrentworkspacetomonitor, r"

        # ─ Special workspace (scratchpad) ─
        "$mod, grave, togglespecialworkspace, magic"
        "$mod SHIFT, grave, movetoworkspace, special:magic"
      ];

      # ─ Resize submap ─
      # (defined via extraConfig below)

      # ─ Mouse binds ─
      bindm = [
        "$mod, mouse:272, movewindow" # Super + left click drag
        "$mod, mouse:273, resizewindow" # Super + right click drag
      ];

      # ─ Volume (repeat on hold) ─
      bindel = [
        ", XF86AudioRaiseVolume, exec, swayosd-client --output-volume raise"
        ", XF86AudioLowerVolume, exec, swayosd-client --output-volume lower"
        ", XF86MonBrightnessUp, exec, swayosd-client --brightness raise"
        ", XF86MonBrightnessDown, exec, swayosd-client --brightness lower"
      ];

      bindl = [
        ", XF86AudioMute, exec, swayosd-client --output-volume mute-toggle"
        ", XF86AudioMicMute, exec, swayosd-client --input-volume mute-toggle"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86AudioStop, exec, playerctl stop"
      ];

      # ── Exec Once ─────────────────────────────────────────
      exec-once = [
        "hyprpanel"
        "awww-daemon && awww img ${loadingScreen} --transition-type none && sleep 2 && awww img ${config.stylix.image} --transition-type wipe --transition-duration 2"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        "udiskie --tray"
        "blueman-applet"
        "nm-applet --indicator"
        "hypridle"
        "hyprsunset"
        "swayosd-server"
        "gnome-keyring-daemon --start --components=secrets,ssh"
      ];
    };

    # Resize submap (can't be expressed in settings attrset easily)
    extraConfig = ''
      submap = resize
      binde = , Right, resizeactive, 30 0
      binde = , Left, resizeactive, -30 0
      binde = , Up, resizeactive, 0 -30
      binde = , Down, resizeactive, 0 30
      bind = , Escape, submap, reset
      bind = , Return, submap, reset
      submap = reset
    '';
  };
}
