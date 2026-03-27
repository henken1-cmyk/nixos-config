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
  monitorLeft = "DP-1"; # CHANGEME: set your left monitor name
  monitorRight = "DP-2"; # CHANGEME: set your right monitor name
  monitors = [
    "DP-1,preferred,auto,1" # CHANGEME: set resolution, refresh rate, position, scale
    "DP-2,preferred,auto,1" # CHANGEME: set resolution, refresh rate, position, scale
  ];
  # DRM connector names for early boot framebuffer (from /sys/class/drm/)
  monitors_drm = [ "DP-1" "DP-2" ];

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
