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

  # Monitors — identified by description so they survive DP port reshuffles
  # (from `hyprctl monitors` → "description" field)
  # Left: HP 727pk 27" 4K 60Hz, Right: Samsung Odyssey G80SD 32" 4K 240Hz (primary)
  monitorLeft = "desc:HP Inc. HP 727pk CN44272390";
  monitorRight = "desc:Samsung Electric Company Odyssey G80SD H1AK500000";
  monitors = [
    "desc:HP Inc. HP 727pk CN44272390,3840x2160@60,0x0,1,bitdepth,10"
    "desc:Samsung Electric Company Odyssey G80SD H1AK500000,3840x2160@240,3840x0,1,bitdepth,10"
  ];

  # Boot
  bootloader = "grub";
  bootGenerations = 10;
  showFirmwareEntry = true;
  windowsBootEntry = "Windows Boot Manager (on /dev/nvme1n1p1)"; # from grub.cfg, null on NixOS-only hosts
  use4kBootFont = true;
  kernelPackages = "cachyos-lto-v3";
  disableUsbWake = true; # prevent immediate wake on hibernate

  # GPU
  nvidiaOpen = true;             # RTX 3090 Ti (Ampere) supports open modules
  nvidiaHibernatePatch = true;   # apply hibernate-resume patch (NVIDIA 5xx pre-575)

  # Theme
  theme = "solarized-dark";
  base16Scheme = "solarized-dark";
  base16SchemeLight = "solarized-light";

  # Hardware monitoring (waybar)
  hwmonPath = "/sys/devices/pci0000:00/0000:00:18.3/hwmon"; # AMD Ryzen k10temp
  nvidiaMonitoring = true;

  # Audio
  spdifNodeName = "alsa_output.pci-0000_0d_00.4.iec958-stereo"; # ALC1220 S/PDIF

  # Boot fonts (4K displays)
  grubFontSize = 48;
  consoleFontSize = 48;

  # Zellij
  zellijAutostart = false;

  # Location
  city = "Warsaw";
  latitude = 52.23;
  longitude = 21.01;
}
