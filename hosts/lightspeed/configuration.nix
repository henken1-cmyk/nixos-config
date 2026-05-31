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
    ../../nixos/sddm.nix
    ../../nixos/locale.nix
    ../../nixos/networking.nix
    ../../nixos/nix.nix
    ../../nixos/plasma6.nix
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
  security.pam.services.sddm.enableGnomeKeyring = true;
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

  # ── NVIDIA Container Toolkit — GPU passthrough for the Docker stack ──
  # Generates a CDI spec at /run/cdi/ so containers can request the GPU via
  # `devices: ["nvidia.com/gpu=all"]` (used by the Jellyfin container for
  # NVENC/NVDEC). Host-scoped on purpose: the laptop `adam` shares
  # nixos/docker.nix and must NOT get this. Does not change the Docker default
  # runtime — GPU access stays opt-in per container.
  hardware.nvidia-container-toolkit.enable = true;

  # ── Docker must start AFTER the NTFS archive mount ──
  # /mnt/archive (ntfs3) can mount *after* dockerd has already captured the
  # empty mountpoint, so containers bind an empty dir (qBittorrent/Jellyfin/*arr
  # then see no media — and qBit could even write downloads onto the root fs).
  # Ordering dockerd after mnt-archive.mount closes that race. `wants` (not
  # `requires`) honours the mount's `nofail`: a missing archive disk just
  # skips the mount without taking the entire Docker stack down with it.
  systemd.services.docker = {
    after = [ "mnt-archive.mount" ];
    wants = [ "mnt-archive.mount" ];
  };

  # ── NTFS dirty-bit auto-repair for /mnt/archive (runs before the mount) ──
  # This disk is shared with Windows, which — especially with Fast Startup —
  # leaves the NTFS volume marked dirty on an unclean close; ntfs3 then mounts it
  # read-only to protect it. `ntfsfix -d` repairs common errors, resets the NTFS
  # $LogFile journal, and clears the dirty flag so the volume mounts read-write.
  # It is a no-op on an already-clean volume, hence safe to run every boot, and
  # it only operates while the device is UNMOUNTED (so it runs before the mount).
  #
  # NOTE: this does NOT remove a Windows hibernation file (hiberfil.sys from Fast
  # Startup) — if the drive still comes up read-only, disable Fast Startup in
  # Windows (or `powercfg /h off`). DefaultDependencies=false avoids an ordering
  # cycle with local-fs; wantedBy (not requiredBy) honours the mount's `nofail`.
  systemd.services.ntfsfix-archive = {
    description = "Repair NTFS dirty flag on /mnt/archive before mounting";
    before = [ "mnt-archive.mount" ];
    wantedBy = [ "mnt-archive.mount" ];
    requires = [ "dev-disk-by\\x2duuid-1CA2587FA2585F78.device" ];
    after = [ "dev-disk-by\\x2duuid-1CA2587FA2585F78.device" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.ntfs3g}/bin/ntfsfix -d /dev/disk/by-uuid/1CA2587FA2585F78";
    };
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

    # Available system-wide (for elf user and others)
    inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default
    gh
    playwright-test # Playwright with bundled Chromium
    nodejs_22       # Node.js for @playwright/cli
    bun
  ];

  system.stateVersion = "24.11";
}
