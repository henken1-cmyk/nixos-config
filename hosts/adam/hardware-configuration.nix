# TEMPLATE for Lenovo ThinkPad T480s (20L6S55L00)
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

  # ThinkPad T480s — Intel i7-8550U (Kaby Lake Refresh)
  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # CHANGEME: Replace UUID with value from `blkid /dev/nvme0n1p2` (the LUKS partition)
  boot.initrd.luks.devices."cryptbtrfs" = {
    device = "/dev/disk/by-uuid/c08cbccf-615d-4a63-8977-21f887d94786";
    allowDiscards = true; # SSD TRIM through LUKS
  };

  # CHANGEME: Replace UUID with value from `blkid /dev/nvme0n1p1`
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/6EA3-33AD";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  # Btrfs subvolumes (no @devel on laptop)
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

  # 16 GB swap file for hibernation
  swapDevices = [
    { device = "/swap/swapfile"; }
  ];

  # Hibernation: resume from LUKS mapper
  boot.resumeDevice = "/dev/mapper/cryptbtrfs";
  boot.kernelParams = [ "resume_offset=533760" ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
