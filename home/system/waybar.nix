{ config, pkgs, lib, vars, scale, ... }:

let
  colors = config.lib.stylix.colors;
in
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings = [{
      layer = "top";
      position = "top";
      height = scale.size.bar;
      spacing = scale.gap.sm;
      margin-top = if (vars.waybarAutohide or false) then 0 else scale.gap.md;
      margin-left = if (vars.waybarAutohide or false) then 0 else scale.gap.md;
      margin-right = if (vars.waybarAutohide or false) then 0 else scale.gap.md;

      fixed-center = true;

      # Layout: Fibonacci-balanced (3:3 at rest, 5:3 when media+submap active)
      # Left 3 permanent + 2 contextual | ··· workspaces ··· | 3 right
      modules-left = [
        "custom/logo"
        "tray"
        "group/hardware"
        "custom/media"
        "hyprland/submap"
      ];

      modules-center = [
        "hyprland/workspaces"
      ];

      modules-right = [
        "group/connectivity"
        "idle_inhibitor"
        "group/clock-group"
      ];

      # ── Logo ──────────────────────────────────────────────
      "custom/logo" = {
        format = "󱄅";
        on-click = "fuzzel";
        on-click-right = "swaync-client -t -sw";
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
        all-outputs = false;
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
          "class<com.mitchellh.ghostty>" = " ";
          "class<org.wezfurlong.wezterm>" = " ";
          "class<Warp|warp|dev.warp.Warp|warp-terminal>" = "󰰭 ";
          "class<[Tt]hunderbird|[Tt]hunderbird-esr>" = " ";
          "class<eu.betterbird.Betterbird>" = " ";
          "class<gmail>" = "󰊫 ";
          "title<.*gmail.*>" = "󰊫 ";
          "class<[Tt]elegram-desktop|org.telegram.desktop|io.github.tdesktop_x64.TDesktop>" = " ";
          "class<discord|discord-canary|[Ww]ebcord|[Vv]esktop|com.discordapp.Discord|dev.vencord.Vesktop>" = " ";
          "class<[Ss]ignal|signal-desktop|org.signal.Signal>" = "󰍩 ";
          "title<.*Signal.*>" = "󰍩 ";
          "title<.*whatsapp.*>" = " ";
          "title<.*zapzap.*>" = " ";
          "class<messenger>" = " ";
          "title<.*messenger.*>" = " ";
          "title<.*facebook.*>" = " ";
          "title<.*Discord.*>" = " ";
          "class<claude>" = "󰚩 ";
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
          "class<github>" = " ";
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
          "class<nwg-displays>" = "  ";
          "class<[Pp]avucontrol|org.pulseaudio.pavucontrol>" = "󱡫 ";
          "class<steam>" = " ";
          "class<qbittorrent|org.qbittorrent.qBittorrent>" = " ";
          "class<thunar|nemo>" = "󰝰 ";
          "class<Gparted>" = " ";
          "class<gimp>" = " ";
          "class<emulator>" = "📱";
          "class<android-studio>" = " ";
          "class<org.pipewire.Helvum>" = "󰓃 ";
          "class<localsend>" = " ";
          "class<PrusaSlicer|UltiMaker-Cura|OrcaSlicer>" = "󰹛 ";
          "class<io.github.kolunmi.Bazaar>" = " ";
          "title<^Bazaar$>" = " ";
          "class<com.gabm.satty>" = " ";
          "title<^satty$>" = " ";
          "class<[Bb]ox[Bb]uddy|io.github.dvlv.boxbuddy|io.github.dvlv.BoxBuddy>" = " ";
          "title<.*BoxBuddy.*>" = " ";
          "title<Hyprland Keybinds>" = "  ";
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
          "title<^qs-wlogout$>" = "  ";
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
        format = "{icon} {text}";
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
        icon-size = scale.icon.md;
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
        format-ethernet = "󰈁";
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
        exec = "${pkgs.wttrbar}/bin/wttrbar --location Warsaw";
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
            months = "<span color='#${colors.base05}'><b>{}</b></span>";
            days = "<span color='#${colors.base04}'>{}</span>";
            weeks = "<span color='#${colors.base02}'>W{}</span>";
            weekdays = "<span color='#${colors.base0A}'><b>{}</b></span>";
            today = "<span color='#${colors.base09}'><b><u>{}</u></b></span>";
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
    style = let s = scale; p = s.px; c = colors; in ''
      * {
        font-family: "SauceCodePro Nerd Font", "Noto Sans", monospace;
        font-size: ${p s.font.md};
        min-height: 0;
        border: none;
        border-radius: 0;
      }

      window#waybar {
        background: transparent;
      }

      /* ── Island / Pill base (Fibonacci spacing) ── */
      .modules-left > widget > *,
      .modules-center > widget > *,
      .modules-right > widget > * {
        background-color: alpha(#${c.base01}, 0.85);
        border-radius: ${p s.radius.pill};
        padding: ${p s.gap.xs} ${p s.gap.md};
        margin: ${if (vars.waybarAutohide or false) then "0px" else "${p s.gap.sm}"} ${p s.gap.xs};
        color: #${c.base05};
      }

      /* ── Logo ───────────────────────────────────────────── */
      #custom-logo {
        color: #${c.base0D};
        font-size: ${p s.font.md};
        padding: 0;
        transition: all 0.3s ease;
      }

      #custom-logo:hover {
        color: #${c.base07};
      }

      /* ── Workspaces (centered dock) ──────────────────────── */
      #workspaces {
        padding: ${p s.gap.sm} ${p s.gap.md};
      }

      #workspaces button {
        color: #${c.base05};
        padding: ${p s.gap.sm} ${p s.gap.md};
        margin: ${p s.gap.xs} ${p s.gap.sm};
        border-radius: ${p s.radius.xl};
        background: transparent;
        min-width: ${p s.size.toggle};
        transition: all 0.4s cubic-bezier(.55, -0.68, .48, 1.682);
      }

      #workspaces button label {
        font-family: "SauceCodePro Nerd Font", monospace;
        font-size: ${p s.font.md};
      }

      #workspaces button.active {
        background-color: alpha(#${c.base0D}, 0.3);
        color: #${c.base07};
        padding-left: ${p s.gap.xl};
        padding-right: ${p s.gap.xl};
      }

      #workspaces button.empty {
        color: #${c.base02};
      }

      #workspaces button.urgent {
        background-color: alpha(#${c.base08}, 0.3);
        color: #${c.base08};
        animation: pulse 2s ease-in-out infinite;
      }

      #workspaces button.visible {
        background-color: alpha(#${c.base02}, 0.2);
        color: #${c.base05};
      }

      #workspaces button.hosting-monitor {
        border-bottom: ${p s.border.normal} solid #${c.base0A};
      }

      #workspaces button:hover {
        background-color: alpha(#${c.base02}, 0.3);
        color: #${c.base05};
      }

      /* ── Submap ─────────────────────────────────────────── */
      #submap {
        color: #${c.base09};
        font-weight: bold;
        padding: 0 ${p s.gap.lg};
      }

      /* ── Media ──────────────────────────────────────────── */
      #custom-media {
        color: #${c.base0C};
        padding: 0 ${p s.gap.lg};
        font-style: italic;
      }

      #custom-media.Paused {
        color: #${c.base02};
      }

      /* ── Tray ───────────────────────────────────────────── */
      #tray {
        padding: 0 ${p s.gap.lg};
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      /* ── Hardware drawer ────────────────────────────────── */
      #custom-hw-icon {
        color: #${c.base05};
        padding: 0 ${p s.gap.lg};
        font-size: ${p s.font.md};
      }

      #cpu {
        color: #${c.base0B};
        padding: 0 ${p s.gap.lg};
        border-right: 1px solid alpha(#${c.base02}, 0.4);
      }

      #memory {
        color: #${c.base0D};
        padding: 0 ${p s.gap.lg};
        border-right: 1px solid alpha(#${c.base02}, 0.4);
      }

      #temperature {
        color: #${c.base09};
        padding: 0 ${p s.gap.lg};
        border-right: 1px solid alpha(#${c.base02}, 0.4);
      }

      #temperature.critical {
        color: #${c.base08};
        animation: pulse 2s ease-in-out infinite;
      }

      #disk {
        color: #${c.base0E};
        padding: 0 ${p s.gap.lg};
        border-right: 1px solid alpha(#${c.base02}, 0.4);
      }

      #custom-gpu {
        color: #${c.base0C};
        padding: 0 ${p s.gap.lg};
      }

      /* ── Connectivity pill ──────────────────────────────── */
      #pulseaudio {
        color: #${c.base0F};
        padding: 0 ${p s.gap.lg};
        border-right: 1px solid alpha(#${c.base02}, 0.4);
      }

      #pulseaudio.muted {
        opacity: 0.5;
      }

      #network {
        color: #${c.base0C};
        padding: 0 ${p s.gap.lg};
        border-right: 1px solid alpha(#${c.base02}, 0.4);
      }

      #network.disconnected {
        opacity: 0.5;
      }

      #battery {
        color: #${c.base0B};
        padding: 0 ${p s.gap.lg};
        border-right: 1px solid alpha(#${c.base02}, 0.4);
      }

      #battery.warning {
        color: #${c.base0A};
      }

      #battery.critical {
        color: #${c.base08};
        animation: pulse 2s ease-in-out infinite;
      }

      #battery.charging {
        color: #${c.base0B};
      }

      #bluetooth {
        color: #${c.base0A};
        padding: 0 ${p s.gap.lg};
      }

      /* ── Idle inhibitor ─────────────────────────────────── */
      #idle_inhibitor {
        padding: 0;
        min-width: ${p s.size.toggle};
        min-height: ${p s.size.toggle};
        border-radius: 50%;
        color: #${c.base02};
        transition: all 0.3s ease;
      }

      #idle_inhibitor.activated {
        color: #${c.base0A};
      }

      /* ── Clock group ────────────────────────────────────── */
      #custom-weather {
        color: #${c.base0A};
        padding: 0 ${p s.gap.lg};
        border-right: 1px solid alpha(#${c.base02}, 0.4);
      }

      #custom-theme-toggle {
        color: #${c.base09};
        padding: 0 ${p s.gap.lg};
        font-size: ${p s.font.md};
        border-right: 1px solid alpha(#${c.base02}, 0.4);
        transition: all 0.3s ease;
      }

      #custom-theme-toggle:hover {
        color: #${c.base07};
      }

      #clock {
        color: #${c.base05};
        font-weight: bold;
        padding: 0 ${p s.gap.lg};
        border-right: 1px solid alpha(#${c.base02}, 0.4);
      }

      #custom-power {
        color: #${c.base08};
        padding: 0 ${p s.gap.lg};
        font-size: ${p s.font.md};
        transition: all 0.3s ease;
      }

      #custom-power:hover {
        color: #${c.base07};
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
        background-color: alpha(#${c.base00}, 0.95);
        border: 1px solid #${c.base0D};
        border-radius: ${p s.radius.lg};
        color: #${c.base05};
      }

      tooltip label {
        color: #${c.base05};
        padding: ${p s.gap.sm};
      }
    '';
  };
}
