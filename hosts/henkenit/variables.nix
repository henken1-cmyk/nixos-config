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
  monitorLeft = "DP-2"; # HP 727pk (left)
  monitorRight = "DP-1"; # Samsung Odyssey G80SD (right)
  monitors = [
    "DP-2,preferred,0x0,1" # HP 727pk — left
    "DP-1,preferred,3840x0,1.5" # Samsung Odyssey G80SD — right
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
