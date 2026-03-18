{ config, pkgs, lib, vars, ... }:

let
  fontSize = toString (vars.grubFontSize or 16);
  consoleFontSz = toString (vars.consoleFontSize or 16);

  sauceCodePro = pkgs.nerd-fonts.sauce-code-pro;
  sauceCodeProTtf = "${sauceCodePro}/share/fonts/truetype/NerdFonts/SauceCodePro/SauceCodeProNerdFontMono-Regular.ttf";

  # Generate PF2 font for GRUB from SauceCodePro (size from vars)
  grubFont = pkgs.runCommand "saucecodeprp-grub-font-${fontSize}" {
    nativeBuildInputs = [ pkgs.grub2 ];
  } ''
    mkdir -p $out
    grub-mkfont --size=${fontSize} -o $out/SauceCodePro.pf2 ${sauceCodeProTtf}
  '';

  # Generate PSF console font from SauceCodePro for LUKS prompt + TTY
  # Pipeline: TTF → BDF (rasterize) → fix metadata → PSF (console format)
  # Lat2.256 charset covers Polish and Central European characters
  consoleFont = pkgs.runCommand "saucecodeprp-console-font-${consoleFontSz}" {
    nativeBuildInputs = [ pkgs.otf2bdf pkgs.bdf2psf ];
  } ''
    mkdir -p $out/share/consolefonts
    # otf2bdf returns non-zero on glyph warnings but still produces valid output
    otf2bdf -p ${consoleFontSz} ${sauceCodeProTtf} -o raw.bdf || true
    # Fix BDF metadata: mark as monospace (C) and correct average width
    sed -e 's/AVERAGE_WIDTH [0-9]*/AVERAGE_WIDTH 400/' \
        -e 's/-P-[0-9]*-/-C-400-/' \
        raw.bdf > font.bdf
    bdf2psf --fb \
      font.bdf \
      ${pkgs.bdf2psf}/share/bdf2psf/standard.equivalents \
      ${pkgs.bdf2psf}/share/bdf2psf/fontsets/Lat2.256 \
      512 \
      $out/share/consolefonts/SauceCodePro.psf
    gzip $out/share/consolefonts/SauceCodePro.psf
  '';
in
{
  boot = {
    loader = {
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        useOSProber = true; # Auto-detect Windows on separate drive (nvme1n1)
        configurationLimit = vars.bootGenerations or 10;
        # Stylix handles Solarized Dark colors + wallpaper background
        font = lib.mkForce "${grubFont}/SauceCodePro.pf2";
        fontSize = vars.grubFontSize or 16;
        extraConfig = ''
          terminal_input console
        '';
      } // lib.optionalAttrs (vars.showFirmwareEntry or false) {
        extraEntries = ''
          menuentry "UEFI Firmware Settings" --class efi {
            fwsetup
          }
        '';
      };
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };

    # Informational kernel logs with Solarized-colored TTY
    kernelParams = [
      "loglevel=6"
      "systemd.show_status=true"
      "rd.udev.log_level=3"
      "amd_pstate=active"
      "nowatchdog"
    ];

    # Kernel
    kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto-x86_64-v3;

    # initrd for LUKS + btrfs
    initrd = {
      systemd.enable = true;
      supportedFilesystems = [ "btrfs" ];
    };

    # Btrfs support at runtime
    supportedFilesystems = [ "btrfs" ];

    # Informational console output
    consoleLogLevel = 6;
  };

  # Disable USB wake from S4 (hibernate) — prevents immediate wake on hibernate
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", DRIVER=="xhci_hcd", ATTR{power/wakeup}="disabled"
  '';

  # Expose grub-reboot for "Reboot to Windows" power menu
  environment.systemPackages = [ pkgs.grub2 ];

  # TTY — Stylix handles console.colors, we just set font + early setup
  console = {
    earlySetup = true;
    font = "${consoleFont}/share/consolefonts/SauceCodePro.psf.gz";
    packages = [ consoleFont ];
  };
}
