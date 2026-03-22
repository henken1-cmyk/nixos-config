{ config, pkgs, lib, vars, ... }:

{
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "auto"; # "max" breaks Plymouth transition
        editor = false; # Security: prevent kernel param editing
        configurationLimit = vars.bootGenerations or 10;
        sortKey = "nixos"; # NixOS entries sort before auto-detected Windows
        # Copy Windows Boot Manager from Windows ESP so systemd-boot sees it
        extraInstallCommands = ''
          ${lib.optionalString (!(vars.showFirmwareEntry or true)) ''
            echo "auto-firmware no" >> /boot/loader/loader.conf
          ''}
          ${lib.optionalString (vars.windowsEfiDevice or "" != "") ''
            tmp=$(mktemp -d)
            mount -o ro ${vars.windowsEfiDevice} "$tmp"
            if [ -d "$tmp/EFI/Microsoft" ]; then
              mkdir -p /boot/EFI/Microsoft
              cp -ru "$tmp/EFI/Microsoft/." /boot/EFI/Microsoft/
            fi
            umount "$tmp"
            rmdir "$tmp"
          ''}
        '';
      };
      efi.canTouchEfiVariables = true;
      timeout = 1; # Quick boot — hold key to access menu
    };

    # Clean boot with Plymouth splash
    kernelParams = [
      "quiet"
      "splash"
      "loglevel=3"
      "systemd.show_status=auto"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      "vt.global_cursor_default=0" # Hide blinking text cursor
    ];

    plymouth.enable = true; # Theme set by Stylix to match base16 scheme

    # Kernel
    kernelPackages = pkgs.linuxPackages_latest;

    # initrd for LUKS + btrfs
    initrd = {
      systemd.enable = true;
      supportedFilesystems = [ "btrfs" ];
      verbose = false; # Suppress initrd messages after LUKS unlock
    };

    # Btrfs support at runtime
    supportedFilesystems = [ "btrfs" ];

    # Console font (larger for 4K)
    consoleLogLevel = 3;
  };

  # Early console font for HiDPI
  # All 16 VT palette colors set to black so console text is invisible
  # during the greeter→desktop transition. Plymouth covers boot; regreet
  # covers login; this hides the brief VT flash in between.
  console = {
    earlySetup = true;
    font = "ter-v24n";
    packages = [ pkgs.terminus_font ];
    colors = [
      "000000" "000000" "000000" "000000"
      "000000" "000000" "000000" "000000"
      "000000" "000000" "000000" "000000"
      "000000" "000000" "000000" "000000"
    ];
  };
}
