{ config, pkgs, inputs, lib, ... }:

let
  vars = import ./variables.nix;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../nixos/audio.nix
    ../../nixos/bluetooth.nix
    ../../nixos/boot.nix
    # No btrfs.nix — laptop has no @devel subvolume, btrfs config is below
    ../../nixos/docker.nix
    ../../nixos/flatpak.nix
    ../../nixos/greetd.nix
    ../../nixos/locale.nix
    ../../nixos/networking.nix
    ../../nixos/nix.nix
    ../../nixos/printing.nix
    ../../nixos/sysctl.nix
    ../../nixos/users.nix
    ../../themes
  ];

  networking.hostName = vars.hostname;

  # ── GPU: Intel UHD 620 (primary) + NVIDIA MX150 (PRIME offload) ──
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true; # Laptop — save battery
    powerManagement.finegrained = true; # Turn off MX150 when not in use
    open = false; # MX150 (GP108) — open kernel modules not supported (pre-Turing)
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true; # Provides `nvidia-offload` wrapper
      };
      # CHANGEME: verify bus IDs with `lspci | grep -E 'VGA|3D'`
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:2:0:0";
    };
  };

  # Intel GPU early load
  boot.initrd.kernelModules = [ "i915" ];

  # ── Laptop power management ──────────────────────────────────────
  services.thermald.enable = true; # Intel thermal daemon

  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      PCIE_ASPM_ON_BAT = "powersupersave";
      # ThinkPad battery charge thresholds
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };

  # Backlight control
  programs.light.enable = true;

  # Lid switch — hibernate on battery (swap + LUKS resume), lock on AC
  services.logind = {
    lidSwitch = "hibernate";
    lidSwitchExternalPower = "lock";
  };

  # ── btrfs (laptop — no @devel) ──────────────────────────────────
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  services.btrbk.instances."default" = {
    onCalendar = "hourly";
    settings = {
      timestamp_format = "long-iso";
      snapshot_preserve_min = "2d";
      snapshot_preserve = "48h 14d 4w 3m";
      snapshot_dir = "@snapshots";

      volume."/mnt/btrfs-root" = {
        subvolume."@root" = {
          snapshot_name = "root";
        };
        subvolume."@home" = {
          snapshot_name = "home";
        };
      };
    };
  };

  # ── XDG Portal ───────────────────────────────────────────────────
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
    config.common.default = [ "hyprland" "gtk" ];
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Polkit
  security.polkit.enable = true;

  # GVFS — enables MTP (phones), trash, SMB/NFS in file managers
  services.gvfs.enable = true;

  # Color management for CUPS/printers
  services.colord.enable = true;

  # Removable media filesystems
  boot.supportedFilesystems = [ "btrfs" "ntfs" "exfat" ];

  # Zram — compressed swap in RAM
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # SSH
  services.openssh.enable = true;
  programs.ssh.startAgent = false;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.hyprlock.enableGnomeKeyring = true;

  # Fonts
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.sauce-code-pro
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
    ];
    fontconfig = {
      defaultFonts = {
        monospace = [ "SauceCodePro Nerd Font" ];
        sansSerif = [ "Noto Sans" ];
        serif = [ "Noto Serif" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  # Electron apps: force Wayland
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
  };

  # System packages (minimal — most go in home-manager)
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    pciutils
    usbutils
    lshw
    man-db
    man-pages
    # btrfs
    btrfs-progs
    btrbk
    compsize
  ];

  system.stateVersion = "24.11";
}
