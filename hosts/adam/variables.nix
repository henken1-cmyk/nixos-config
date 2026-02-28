{
  # User
  username = "adam";
  fullName = "Adam";
  email = "henken1@gmail.com"; # CHANGEME: Set your email
  gitUsername = "henken"; # CHANGEME: Set your git username

  # System
  hostname = "adam";
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
  # ThinkPad T480s built-in display 14" 1366x768
  # CHANGEME: verify with `hyprctl monitors` after first boot
  monitorLeft = "eDP-1";
  monitorRight = "";
  monitors = [
    "eDP-1,1366x768@60,0x0,1"
  ];

  # Theme
  theme = "solarized-dark"; # or "solarized-light"

  # Hyprsunset (Warsaw coordinates for auto schedule)
  latitude = 52.23;
  longitude = 21.01;
}
