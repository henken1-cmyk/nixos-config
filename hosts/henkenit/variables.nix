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
  # Single-monitor setup: HP 727pk on DP-2 only. DP-1 (Samsung Odyssey G80SD)
  # is currently unplugged and its EDID failed on this cable anyway — leave
  # disabled until the cable issue is sorted, otherwise windows spawn on a
  # bogus 1024x768 mode on the disconnected port.
  monitorLeft = "DP-2"; # HP 727pk
  monitorRight = ""; # disabled
  monitors = [
    "DP-2,preferred,auto,1" # HP 727pk
    ",disable" # disable any other connector (DP-1, HDMI-A-1 etc.)
  ];
  # DRM connector names for early boot framebuffer (from /sys/class/drm/)
  monitors_drm = [ "DP-2" ];

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
