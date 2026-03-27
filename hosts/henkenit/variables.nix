{
  # User
  username = "henken"; # CHANGEME: set your username
  fullName = "Henken"; # CHANGEME: set your full name
  email = "henken1@gmail.com"; # CHANGEME: set your email
  gitUsername = "henken1-cmyk"; # CHANGEME: set your git username

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
  monitorLeft = "DP-1"; # CHANGEME: set your monitor name
  monitorRight = "";
  monitors = [
    "DP-1,preferred,auto,1" # CHANGEME: set resolution, refresh rate, position, scale
  ];

  # Boot
  bootGenerations = 10;
  showFirmwareEntry = true;

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
