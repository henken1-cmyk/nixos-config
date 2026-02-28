# WARNING: This is a PLACEHOLDER. Replace with the output of:
#   sudo nixos-generate-config --show-hardware-config
# Run this during NixOS installation.

{ config, lib, pkgs, modulesPath, ... }:

let
  btrfsOpts = [ "compress=zstd:1" "noatime" "space_cache=v2" "ssd" "discard=async" ];
  btrfsNoCow = [ "noatime" "ssd" "discard=async" "nodatacow" ];
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # --- PLACEHOLDER VALUES — REPLACE AFTER nixos-generate-config ---

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # LUKS (btrfs directly on the LUKS device — no LVM)
  boot.initrd.luks.devices."cryptbtrfs" = {
    device = "/dev/disk/by-partlabel/CRYPTBTRFS"; # CHANGEME: use actual partition UUID
    allowDiscards = true; # SSD TRIM through LUKS
  };

  # EFI partition
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  # Btrfs subvolumes
  fileSystems."/" = {
    device = "/dev/mapper/cryptbtrfs";
    fsType = "btrfs";
    options = [ "subvol=@root" ] ++ btrfsOpts;
  };

  fileSystems."/home" = {
    device = "/dev/mapper/cryptbtrfs";
    fsType = "btrfs";
    options = [ "subvol=@home" ] ++ btrfsOpts;
  };

  fileSystems."/nix" = {
    device = "/dev/mapper/cryptbtrfs";
    fsType = "btrfs";
    options = [ "subvol=@nix" ] ++ btrfsNoCow;
  };

  fileSystems."/devel" = {
    device = "/dev/mapper/cryptbtrfs";
    fsType = "btrfs";
    options = [ "subvol=@devel" ] ++ btrfsOpts;
  };

  fileSystems."/var/log" = {
    device = "/dev/mapper/cryptbtrfs";
    fsType = "btrfs";
    options = [ "subvol=@log" ] ++ btrfsOpts;
    neededForBoot = true;
  };

  fileSystems."/.snapshots" = {
    device = "/dev/mapper/cryptbtrfs";
    fsType = "btrfs";
    options = [ "subvol=@snapshots" ] ++ btrfsOpts;
  };

  fileSystems."/swap" = {
    device = "/dev/mapper/cryptbtrfs";
    fsType = "btrfs";
    options = [ "subvol=@swap" ] ++ btrfsNoCow;
  };

  # Swap file on the @swap subvolume
  # Pre-create during install: btrfs filesystem mkswapfile --size 64g /mnt/swap/swapfile
  swapDevices = [
    { device = "/swap/swapfile"; }
  ];

  # CPU
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
