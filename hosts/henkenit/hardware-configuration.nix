# TEMPLATE for HenkenIt desktop (AMD Ryzen 7 7800X3D + NVIDIA RTX 5070 Ti)
# IMPORTANT: After running `nixos-generate-config --root /mnt`, merge ONLY the
# kernel modules and UUIDs from the generated file into this one.
# Do NOT replace this file — it contains btrfs subvolume mounts.
{ config, lib, pkgs, modulesPath, ... }:

let
  btrfsOpts = [ "compress=zstd:1" "noatime" "space_cache=v2" "ssd" "discard=async" ];
  btrfsNoCow = [ "noatime" "ssd" "discard=async" "nodatacow" ];
in
{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  # AMD Ryzen 7 7800X3D (Zen 4)
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # CHANGEME: Replace UUID with value from `blkid /dev/<luks-partition>` (the LUKS partition)
  boot.initrd.luks.devices."cryptbtrfs" = {
    device = "/dev/disk/by-uuid/4f9add7f-85eb-46dc-8384-14a544eac08d";
    allowDiscards = true; # SSD TRIM through LUKS
  };

  # CHANGEME: Replace UUID with value from `blkid /dev/<efi-partition>`
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/C405-61A3";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  # Btrfs subvolumes (no @devel)
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

  # Top-level btrfs mount for btrbk snapshot access
  fileSystems."/mnt/btrfs-root" = {
    device = "/dev/mapper/cryptbtrfs";
    fsType = "btrfs";
    options = [ "subvolid=5" ] ++ btrfsOpts;
  };

  fileSystems."/swap" = {
    device = "/dev/mapper/cryptbtrfs";
    fsType = "btrfs";
    options = [ "subvol=@swap" ] ++ btrfsNoCow;
  };

  # Swap file on @swap subvolume
  swapDevices = [
    { device = "/swap/swapfile"; }
  ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
