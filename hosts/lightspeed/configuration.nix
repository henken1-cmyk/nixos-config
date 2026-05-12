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
    ../../nixos/btrfs.nix
    ../../nixos/docker.nix
    ../../nixos/flatpak.nix
    ../../nixos/gpu.nix
    ../../nixos/jellyfin.nix
    ../../nixos/libvirt.nix
    ../../nixos/greetd.nix
    ../../nixos/locale.nix
    ../../nixos/networking.nix
    ../../nixos/nix.nix
    ../../nixos/printing.nix
    ../../nixos/samba.nix
    ../../nixos/monitoring.nix
    ../../nixos/gaming.nix

    ../../nixos/sysctl.nix
    ../../nixos/users.nix
    ../../nixos/devel-worker.nix
    ../../nixos/hermes.nix
    ../../themes
  ];

  networking.hostName = vars.hostname;

  # XDG Portal — Hyprland module provides portal support
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
    config.common.default = [ "hyprland" "gtk" ];
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # FUSE — allow unprivileged users to use FUSE mounts
  programs.fuse.userAllowOther = true;

  # Polkit
  security.polkit.enable = true;

  # GVFS — enables MTP (phones), trash, SMB/NFS in file managers
  services.gvfs.enable = true;

  # Color management for CUPS/printers
  services.colord.enable = true;

  # Removable media filesystems
  boot.supportedFilesystems = [ "btrfs" "ntfs" "exfat" ];

  # Zram — compressed swap in RAM for better responsiveness
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # SSH
  services.openssh.enable = true;
  programs.ssh.startAgent = false; # Using gnome-keyring instead
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

  # Flatpak apps (declarative via nix-flatpak)
  services.flatpak.packages = [
  ];

  # nix-ld: CUDA + native deps for dynamically linked binaries (PyTorch, pip wheels)
  programs.nix-ld.libraries = with pkgs; [
    cudaPackages.cudatoolkit
    cudaPackages.cudnn
    cudaPackages.nccl
    stdenv.cc.cc.lib  # libstdc++
    zlib
  ];

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

    # Available system-wide (for elf user and others)
    inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default
    gh
    playwright-test # Playwright with bundled Chromium
    nodejs_22       # Node.js for @playwright/cli
    bun
  ];

  system.stateVersion = "24.11";
}
