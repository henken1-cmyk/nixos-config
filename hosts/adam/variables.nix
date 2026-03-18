{
  # User
  username = "adam";
  fullName = "Adam";
  email = "henken1@gmail.com"; # Set your email
  gitUsername = "henken1-cmyk"; # Set your git username

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

  # Boot
  bootGenerations = 1;
  showFirmwareEntry = false;

  # Theme
  theme = "catppuccin-mocha";
  base16Scheme = "catppuccin-mocha";
  base16SchemeLight = "catppuccin-latte";

  # Hardware monitoring (waybar)
  hwmonPath = "/sys/devices/platform/coretemp.0/hwmon"; # Intel coretemp
  nvidiaMonitoring = false;

  # Boot fonts (768p display)
  grubFontSize = 16;
  consoleFontSize = 16;

  # Waybar auto-hide (laptop only)
  waybarAutohide = true;

  # Zellij
  zellijAutostart = true;

  # Location
  city = "Warsaw";
  latitude = 52.23;
  longitude = 21.01;
}
