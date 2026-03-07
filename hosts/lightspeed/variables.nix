{
  # User
  username = "kiper";
  fullName = "Kacper";
  email = "kiperz@gmail.com"; # Set your email
  gitUsername = "kiperz"; # Set your git username

  # System
  hostname = "lightspeed";
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
  # Left: HP 727pk 27" 4K 60Hz, Right: Samsung Odyssey G80SD 32" 4K 240Hz (primary)
  monitorLeft = "DP-2";
  monitorRight = "DP-1";
  monitors = [
    "DP-2,3840x2160@60,0x0,1,bitdepth,10"
    "DP-1,3840x2160@240,3840x0,1,bitdepth,10"
  ];

  # Boot
  bootGenerations = 10;
  showFirmwareEntry = true;
  windowsBootEntry = "Windows Boot Manager (on /dev/nvme1n1p1)"; # from grub.cfg, null on NixOS-only hosts

  # Theme
  theme = "solarized-dark";
  base16Scheme = "solarized-dark";

  # Zellij
  zellijAutostart = false;

  # Hyprsunset (Warsaw coordinates for auto schedule)
  latitude = 52.23;
  longitude = 21.01;
}
