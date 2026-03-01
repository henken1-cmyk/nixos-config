{ config, pkgs, lib, vars, ... }:

{
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "max";
        editor = false; # Security: prevent kernel param editing
        configurationLimit = vars.bootGenerations or 10;
        sortKey = "nixos"; # NixOS entries sort before auto-detected Windows
        # "Reboot to firmware" entry controlled via loader.conf
        extraInstallCommands = lib.mkIf (!(vars.showFirmwareEntry or true)) ''
          echo "auto-firmware no" >> /boot/loader/loader.conf
        '';
      };
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };

    # Clean boot: suppress kernel spam, keep systemd status visible
    kernelParams = [
      "quiet"
      "loglevel=3"
      "systemd.show_status=auto"
      "rd.udev.log_level=3"
    ];

    # Plymouth disabled intentionally — we want to see systemd startup
    # but without the kernel debug wall

    # Kernel
    kernelPackages = pkgs.linuxPackages_latest;

    # initrd for LUKS + btrfs
    initrd = {
      systemd.enable = true;
      supportedFilesystems = [ "btrfs" ];
    };

    # Btrfs support at runtime
    supportedFilesystems = [ "btrfs" ];

    # Console font (larger for 4K)
    consoleLogLevel = 3;
  };

  # Early console font for HiDPI
  console = {
    earlySetup = true;
    font = "ter-v24n";
    packages = [ pkgs.terminus_font ];
  };
}
