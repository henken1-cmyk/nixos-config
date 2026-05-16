{
  # User
  username = "henken"; # CHANGEME: set your username
  fullName = "Henken"; # CHANGEME: set your full name
  email = "henken1@gmail.com"; # Set your email
  gitUsername = "henken1-cmyk"; # Set your git username

  # System
  hostname = "henkenit";
  timezone = "Europe/Warsaw";
  locale = "en_US.UTF-8";
  keyboardLayout = "pl";
  keyboardVariant = "";

  # Paths
  configDir = "~/.config/nixos";
  wallpaperPath = "~/wallpapers/space-solarized.png";
  screenshotDir = "~/Pictures/Screenshots";
  screenRecordDir = "~/Videos/Recordings";
  develPath = "/devel";

  # Monitors (from `hyprctl monitors`)
  # CHANGEME: verify with `hyprctl monitors` after first boot
  # Single-monitor setup: HP 727pk on DP-1. `preferred` auto-picks the
  # mode from EDID; if Hyprland ever boots with cached fallback modes
  # (e.g. monitor moved to a different port between boots), swap to
  # `highres` to force the highest available resolution.
  # Catch-all `,disable` keeps any other connector dark so windows don't
  # spawn on a phantom screen.
  monitorLeft = "DP-1"; # HP 727pk
  monitorRight = ""; # disabled
  monitors = [
    "DP-1,preferred,auto,1" # HP 727pk — auto from EDID
    ",disable" # disable DP-2, DP-3, HDMI-A-1, …
  ];
  # DRM connector names for early boot framebuffer (from /sys/class/drm/)
  monitors_drm = [ "DP-1" ];

  # Boot
  gpuInInitrd = false; # ESP too small (196MB) for NVIDIA modules in initrd
  bootGenerations = 2;
  showFirmwareEntry = true;
  windowsEfiDevice = ""; # Shared ESP — Windows Boot Manager already on /boot

  # Theme (adam-style catppuccin)
  theme = "catppuccin-mocha";
  base16Scheme = "catppuccin-mocha";

  # Waybar auto-hide (false for desktop)
  waybarAutohide = false;

  # Zellij
  zellijAutostart = true;

  # Hyprsunset (Warsaw coordinates for auto schedule)
  latitude = 52.23;
  longitude = 21.01;
}
