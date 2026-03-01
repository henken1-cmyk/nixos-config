{ config, pkgs, lib, vars, ... }:

{
  programs.waybar = {
    enable = true;

    settings = [{
      layer = "top";
      position = "top";
      height = 38;
      spacing = 4;
      margin-top = if (vars.waybarAutohide or false) then 0 else 6;
      margin-left = if (vars.waybarAutohide or false) then 0 else 8;
      margin-right = if (vars.waybarAutohide or false) then 0 else 8;

      fixed-center = true;

      # Layout: logo | media | submap | ··· workspaces ··· | hw-drawer | connectivity | idle | clock-group
      modules-left = [
        "custom/logo"
        "custom/media"
        "hyprland/submap"
      ];

      modules-center = [
        "hyprland/workspaces"
      ];

      modules-right = [
        "tray"
        "group/hardware"
        "group/connectivity"
        "idle_inhibitor"
        "group/clock-group"
      ];

      # ── Logo ──────────────────────────────────────────────
      "custom/logo" = {
        format = "󱄅";
        on-click = "fuzzel";
        tooltip = false;
      };

      # ── Workspaces (centered, with app icons) ─────────────
      "hyprland/workspaces" = {
        format = "{id} {windows}";
        format-window-separator = " ";
        window-rewrite-default = " ";
        on-click = "activate";
        on-scroll-up = "hyprctl dispatch workspace e+1";
        on-scroll-down = "hyprctl dispatch workspace e-1";
        sort-by-number = true;
        all-outputs = true;
        show-special = false;
        persistent-workspaces = {
          "*" = 5;
        };
        window-rewrite = {
          "title<.*amazon.*>" = " ";
          "title<.*reddit.*>" = " ";
          "class<firefox|org.mozilla.firefox|librewolf|floorp|mercury-browser|[Cc]achy-browser>" = " ";
          "class<zen>" = "󰰷 ";
          "class<waterfox|waterfox-bin>" = " ";
          "class<microsoft-edge>" = " ";
          "class<Chromium|Thorium|[Cc]hrome>" = " ";
          "class<brave-browser>" = "🦁 ";
          "class<tor browser>" = " ";
          "class<firefox-developer-edition>" = "🦊 ";
          "class<kitty|konsole|[Aa]lacritty>" = " ";
          "class<kitty-dropterm>" = " ";
          "class<com.mitchellh.ghostty>" = " ";
          "class<org.wezfurlong.wezterm>" = " ";
          "class<Warp|warp|dev.warp.Warp|warp-terminal>" = "󰰭 ";
          "class<[Tt]hunderbird|[Tt]hunderbird-esr>" = " ";
          "class<eu.betterbird.Betterbird>" = " ";
          "title<.*gmail.*>" = "󰊫 ";
          "class<[Tt]elegram-desktop|org.telegram.desktop|io.github.tdesktop_x64.TDesktop>" = " ";
          "class<discord|discord-canary|[Ww]ebcord|[Vv]esktop|com.discordapp.Discord|dev.vencord.Vesktop>" = " ";
          "class<[Ss]ignal|signal-desktop|org.signal.Signal>" = "󰍩 ";
          "title<.*Signal.*>" = "󰍩 ";
          "title<.*whatsapp.*>" = " ";
          "title<.*zapzap.*>" = " ";
          "title<.*messenger.*>" = " ";
          "title<.*facebook.*>" = " ";
          "title<.*Discord.*>" = " ";
          "title<.*ChatGPT.*>" = "󰚩 ";
          "title<.*deepseek.*>" = "󰚩 ";
          "title<.*qwen.*>" = "󰚩 ";
          "class<subl>" = "󰅳 ";
          "class<slack>" = " ";
          "class<mpv>" = " ";
          "class<celluloid|Zoom>" = " ";
          "class<Cider>" = "󰎆 ";
          "title<.*Picture-in-Picture.*>" = " ";
          "title<.*youtube.*>" = " ";
          "class<vlc>" = "󰕼 ";
          "class<[Kk]denlive|org.kde.kdenlive>" = "🎬 ";
          "title<.*Kdenlive.*>" = "🎬 ";
          "title<.*cmus.*>" = " ";
          "class<[Ss]potify>" = " ";
          "class<Plex>" = "󰚺 ";
          "class<virt-manager>" = " ";
          "class<.virt-manager-wrapped>" = " ";
          "class<remote-viewer|virt-viewer>" = " ";
          "class<virtualbox manager>" = "💽 ";
          "title<virtualbox>" = "💽 ";
          "class<remmina|org.remmina.Remmina>" = "🖥️ ";
          "class<VSCode|code|code-url-handler|code-oss|codium|codium-url-handler|VSCodium>" = "󰨞 ";
          "class<dev.zed.Zed>" = "󰵁";
          "class<codeblocks>" = "󰅩 ";
          "title<.*github.*>" = " ";
          "class<mousepad>" = " ";
          "class<libreoffice-writer>" = " ";
          "class<libreoffice-startcenter>" = "󰏆 ";
          "class<libreoffice-calc>" = " ";
          "title<.*nvim ~.*>" = " ";
          "title<.*vim.*>" = " ";
          "title<.*nvim.*>" = " ";
          "title<.*figma.*>" = " ";
          "title<.*jira.*>" = " ";
          "class<jetbrains-idea>" = " ";
          "class<obs|com.obsproject.Studio>" = " ";
          "class<polkit-gnome-authentication-agent-1>" = "󰒃 ";
          "class<nwg-look>" = " ";
          "class<nwg-displays>" = " ";
          "class<[Pp]avucontrol|org.pulseaudio.pavucontrol>" = "󱡫 ";
          "class<steam>" = " ";
          "class<thunar|nemo>" = "󰝰 ";
          "class<Gparted>" = "";
          "class<gimp>" = " ";
          "class<emulator>" = "📱 ";
          "class<android-studio>" = " ";
          "class<org.pipewire.Helvum>" = "󰓃";
          "class<localsend>" = "";
          "class<PrusaSlicer|UltiMaker-Cura|OrcaSlicer>" = "󰹛";
          "class<io.github.kolunmi.Bazaar>" = " ";
          "title<^Bazaar$>" = " ";
          "class<com.gabm.satty>" = " ";
          "title<^satty$>" = " ";
          "class<[Bb]ox[Bb]uddy|io.github.dvlv.boxbuddy|io.github.dvlv.BoxBuddy>" = " ";
          "title<.*BoxBuddy.*>" = " ";
          "title<Hyprland Keybinds>" = " ";
          "title<Niri Keybinds>" = " ";
          "title<BSPWM Keybinds>" = " ";
          "title<DWM Keybinds>" = " ";
          "title<Emacs Leader Keybinds>" = " ";
          "title<Kitty Configuration>" = " ";
          "title<WezTerm Configuration>" = " ";
          "title<Yazi Configuration>" = " ";
          "title<Cheatsheets Viewer>" = " ";
          "title<Documentation Viewer>" = " ";
          "title<^Wallpapers$>" = " ";
          "title<^Video Wallpapers$>" = " ";
          "title<^qs-wlogout$>" = " ";
        };
      };

      # ── Submap indicator ──────────────────────────────────
      "hyprland/submap" = {
        format = "  {}";
        max-length = 20;
        tooltip = false;
      };

      # ── Media (MPRIS) ────────────────────────────────────
      "custom/media" = {
        format = "{icon} {}";
        return-type = "json";
        max-length = 40;
        format-icons = {
          Playing = "󰏤";
          Paused = "󰐊";
        };
        exec = ''${pkgs.playerctl}/bin/playerctl -a metadata --format '{"text": "{{artist}} - {{title}}", "tooltip": "{{playerName}}: {{artist}} - {{title}}", "alt": "{{status}}", "class": "{{status}}"}' -F'';
        on-click = "${pkgs.playerctl}/bin/playerctl play-pause";
        on-scroll-up = "${pkgs.playerctl}/bin/playerctl next";
        on-scroll-down = "${pkgs.playerctl}/bin/playerctl previous";
      };

      # ── Tray ──────────────────────────────────────────────
      tray = {
        spacing = 8;
        icon-size = 16;
      };

      # ── Hardware drawer ───────────────────────────────────
      "group/hardware" = {
        orientation = "inherit";
        drawer = {
          transition-duration = 500;
          transition-left-to-right = true;
        };
        modules = [ "custom/hw-icon" "cpu" "memory" "temperature" "disk" "custom/gpu" ];
      };

      "custom/hw-icon" = {
        format = "󰒓";
        tooltip = false;
      };

      cpu = {
        format = " {usage}%";
        interval = 5;
        tooltip = true;
      };

      memory = {
        format = " {percentage}%";
        interval = 5;
        tooltip-format = "{used:0.1f}G / {total:0.1f}G";
      };

      temperature = {
        hwmon-path-abs = "/sys/devices/pci0000:00/0000:00:18.3/hwmon";
        input-filename = "temp1_input";
        critical-threshold = 80;
        format = " {temperatureC}°C";
        format-critical = " {temperatureC}°C";
        interval = 5;
      };

      disk = {
        format = "󰋊 {percentage_used}%";
        path = "/";
        interval = 30;
        tooltip-format = "{path}: {used} / {total}";
      };

      "custom/gpu" = {
        format = "󰢮 {}";
        exec = ''nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits 2>/dev/null | awk -F", " "{printf \"%s%% %s°C\", \$1, \$2}"'';
        interval = 5;
        tooltip = false;
      };

      # ── Connectivity pill ─────────────────────────────────
      "group/connectivity" = {
        orientation = "inherit";
        modules = [ "pulseaudio" "battery" "network" "bluetooth" ];
      };

      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = "󰝟 muted";
        format-icons = {
          default = [ "󰕿" "󰖀" "󰕾" ];
        };
        on-click = "pavucontrol";
        on-click-right = "swayosd-client --output-volume mute-toggle";
      };

      network = {
        format-wifi = "󰖩 {signalStrength}%";
        format-ethernet = "󰈁 {ipaddr}";
        format-disconnected = "󰖪 off";
        tooltip-format-wifi = "{essid} ({signalStrength}%)\n{ipaddr}/{cidr}";
        tooltip-format-ethernet = "{ifname}\n{ipaddr}/{cidr}";
        on-click = "nm-connection-editor";
      };

      battery = {
        states = { warning = 30; critical = 15; };
        format = "{icon} {capacity}%";
        format-charging = "󰂄 {capacity}%";
        format-plugged = "󰚥 {capacity}%";
        format-icons = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
        tooltip-format = "{timeTo}, {power:.1f}W";
        interval = 30;
      };

      bluetooth = {
        format = "󰂯";
        format-connected = "󰂱 {device_alias}";
        format-disabled = "󰂲";
        on-click = "blueman-manager";
        tooltip-format-connected = "{device_enumerate}";
      };

      # ── Idle inhibitor ────────────────────────────────────
      idle_inhibitor = {
        format = "{icon}";
        format-icons = {
          activated = "󰅶";
          deactivated = "󰾪";
        };
        tooltip-format-activated = "Idle inhibitor: ON";
        tooltip-format-deactivated = "Idle inhibitor: OFF";
      };

      # ── Clock group ───────────────────────────────────────
      "group/clock-group" = {
        orientation = "inherit";
        modules = [ "custom/weather" "custom/theme-toggle" "clock" "custom/power" ];
      };

      "custom/weather" = {
        format = "{}";
        exec = "${pkgs.wttrbar}/bin/wttrbar --location Warsaw --fahrenheit false";
        return-type = "json";
        interval = 3600;
        tooltip = true;
      };

      "custom/theme-toggle" = {
        format = "󰖨";
        on-click = "$HOME/.config/nixos/home/scripts/theme-toggle.sh";
        tooltip-format = "Toggle Solarized Dark/Light";
      };

      clock = {
        format = "{:%H:%M}";
        format-alt = "{:%A, %B %d, %Y}";
        tooltip-format = "<tt><small>{calendar}</small></tt>";
        calendar = {
          mode = "year";
          mode-mon-col = 3;
          weeks-pos = "right";
          on-scroll = 1;
          format = {
            months = "<span color='#93a1a1'><b>{}</b></span>";
            days = "<span color='#839496'>{}</span>";
            weeks = "<span color='#586e75'>W{}</span>";
            weekdays = "<span color='#b58900'><b>{}</b></span>";
            today = "<span color='#cb4b16'><b><u>{}</u></b></span>";
          };
        };
      };

      "custom/power" = {
        format = "⏻";
        tooltip = false;
        on-click = "$HOME/.config/nixos/home/scripts/power-menu.sh";
      };
      "exclusive-zone" = lib.mkIf (vars.waybarAutohide or false) (-1);
    }];

    # ── Custom CSS — Floating Islands with Solarized accent colors ──
    style = ''
      * {
        font-family: "SauceCodePro Nerd Font", "Noto Sans", monospace;
        font-size: 13px;
        min-height: 0;
        border: none;
        border-radius: 0;
      }

      window#waybar {
        background: transparent;
      }

      /* ── Island / Pill base ─────────────────────────────── */
      .modules-left > widget > *,
      .modules-center > widget > *,
      .modules-right > widget > * {
        background-color: rgba(7, 54, 66, 0.85);
        border-radius: 20px;
        padding: 2px 4px;
        margin: ${if (vars.waybarAutohide or false) then "0px" else "4px"} 3px;
        color: #93a1a1;
      }

      /* ── Logo ───────────────────────────────────────────── */
      #custom-logo {
        color: #268bd2;
        font-size: 18px;
        padding: 0 14px;
        transition: all 0.3s ease;
      }

      #custom-logo:hover {
        color: #fdf6e3;
      }

      /* ── Workspaces (centered dock) ──────────────────────── */
      #workspaces {
        padding: 2px 6px;
      }

      #workspaces button {
        color: #93a1a1;
        padding: 4px 10px;
        margin: 2px 3px;
        border-radius: 12px;
        background: transparent;
        min-width: 20px;
        transition: all 0.4s cubic-bezier(.55, -0.68, .48, 1.682);
      }

      #workspaces button label {
        font-family: "SauceCodePro Nerd Font", monospace;
        font-size: 13px;
      }

      #workspaces button.active {
        background-color: rgba(38, 139, 210, 0.3);
        color: #fdf6e3;
        padding-left: 12px;
        padding-right: 12px;
      }

      #workspaces button.empty {
        color: #586e75;
      }

      #workspaces button:hover {
        background-color: rgba(88, 110, 117, 0.3);
        color: #93a1a1;
      }

      /* ── Submap ─────────────────────────────────────────── */
      #submap {
        color: #cb4b16;
        font-weight: bold;
        padding: 0 10px;
      }

      /* ── Media ──────────────────────────────────────────── */
      #custom-media {
        color: #2aa198;
        padding: 0 12px;
        font-style: italic;
      }

      #custom-media.Paused {
        color: #586e75;
      }

      /* ── Tray ───────────────────────────────────────────── */
      #tray {
        padding: 0 8px;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      /* ── Hardware drawer ────────────────────────────────── */
      #custom-hw-icon {
        color: #93a1a1;
        padding: 0 10px;
        font-size: 15px;
      }

      #cpu {
        color: #859900;
        padding: 0 8px;
        border-right: 1px solid rgba(88, 110, 117, 0.4);
      }

      #memory {
        color: #268bd2;
        padding: 0 8px;
        border-right: 1px solid rgba(88, 110, 117, 0.4);
      }

      #temperature {
        color: #cb4b16;
        padding: 0 8px;
        border-right: 1px solid rgba(88, 110, 117, 0.4);
      }

      #temperature.critical {
        color: #dc322f;
        animation: pulse 2s ease-in-out infinite;
      }

      #disk {
        color: #6c71c4;
        padding: 0 8px;
        border-right: 1px solid rgba(88, 110, 117, 0.4);
      }

      #custom-gpu {
        color: #2aa198;
        padding: 0 8px;
      }

      /* ── Connectivity pill ──────────────────────────────── */
      #pulseaudio {
        color: #d33682;
        padding: 0 8px;
        border-right: 1px solid rgba(88, 110, 117, 0.4);
      }

      #pulseaudio.muted {
        opacity: 0.5;
      }

      #network {
        color: #2aa198;
        padding: 0 8px;
        border-right: 1px solid rgba(88, 110, 117, 0.4);
      }

      #network.disconnected {
        opacity: 0.5;
      }

      #battery {
        color: #859900;
        padding: 0 8px;
        border-right: 1px solid rgba(88, 110, 117, 0.4);
      }

      #battery.warning {
        color: #e5c07b;
      }

      #battery.critical {
        color: #dc322f;
        animation: pulse 2s ease-in-out infinite;
      }

      #battery.charging {
        color: #859900;
      }

      #bluetooth {
        color: #b58900;
        padding: 0 8px;
      }

      /* ── Idle inhibitor ─────────────────────────────────── */
      #idle_inhibitor {
        padding: 0 10px;
        color: #586e75;
        transition: all 0.3s ease;
      }

      #idle_inhibitor.activated {
        color: #b58900;
      }

      /* ── Clock group ────────────────────────────────────── */
      #custom-weather {
        color: #b58900;
        padding: 0 8px;
        border-right: 1px solid rgba(88, 110, 117, 0.4);
      }

      #custom-theme-toggle {
        color: #cb4b16;
        padding: 0 8px;
        font-size: 15px;
        border-right: 1px solid rgba(88, 110, 117, 0.4);
        transition: all 0.3s ease;
      }

      #custom-theme-toggle:hover {
        color: #fdf6e3;
      }

      #clock {
        color: #93a1a1;
        font-weight: bold;
        padding: 0 10px;
        min-width: 70px;
        border-right: 1px solid rgba(88, 110, 117, 0.4);
      }

      #custom-power {
        color: #dc322f;
        padding: 0 10px;
        font-size: 15px;
        transition: all 0.3s ease;
      }

      #custom-power:hover {
        color: #fdf6e3;
      }

      /* ── Animations ─────────────────────────────────────── */
      @keyframes pulse {
        0% {
          opacity: 1;
        }
        50% {
          opacity: 0.5;
        }
        100% {
          opacity: 1;
        }
      }

      /* ── Tooltip styling ────────────────────────────────── */
      tooltip {
        background-color: rgba(0, 43, 54, 0.95);
        border: 1px solid #268bd2;
        border-radius: 8px;
        color: #93a1a1;
      }

      tooltip label {
        color: #93a1a1;
        padding: 4px;
      }
    '';
  };
}
