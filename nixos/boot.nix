{ config, pkgs, lib, vars, ... }:

let
  sauceCodePro = pkgs.nerd-fonts.sauce-code-pro;
  sauceCodeProTtf = "${sauceCodePro}/share/fonts/truetype/NerdFonts/SauceCodePro/SauceCodeProNerdFontMono-Regular.ttf";

  # Generate a large PF2 font for GRUB from SauceCodePro (readable at native 4K)
  grubFont = pkgs.runCommand "saucecodeprp-grub-font" {
    nativeBuildInputs = [ pkgs.grub2 ];
  } ''
    mkdir -p $out
    grub-mkfont --size=48 -o $out/SauceCodePro48.pf2 ${sauceCodeProTtf}
  '';

  # Generate a large PSF console font from SauceCodePro for LUKS prompt + TTY at 4K
  # Pipeline: TTF → BDF (rasterize at 48px) → fix metadata → PSF (console format)
  # Lat2.256 charset covers Polish and Central European characters
  consoleFont = pkgs.runCommand "saucecodeprp-console-font" {
    nativeBuildInputs = [ pkgs.otf2bdf pkgs.bdf2psf ];
  } ''
    mkdir -p $out/share/consolefonts
    # otf2bdf returns non-zero on glyph warnings but still produces valid output
    otf2bdf -p 48 ${sauceCodeProTtf} -o raw.bdf || true
    # Fix BDF metadata: mark as monospace (C) and correct average width
    sed -e 's/AVERAGE_WIDTH [0-9]*/AVERAGE_WIDTH 400/' \
        -e 's/-P-[0-9]*-/-C-400-/' \
        raw.bdf > font.bdf
    bdf2psf --fb \
      font.bdf \
      ${pkgs.bdf2psf}/share/bdf2psf/standard.equivalents \
      ${pkgs.bdf2psf}/share/bdf2psf/fontsets/Lat2.256 \
      512 \
      $out/share/consolefonts/SauceCodePro48.psf
    gzip $out/share/consolefonts/SauceCodePro48.psf
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
        font = lib.mkForce "${grubFont}/SauceCodePro48.pf2";
        fontSize = 48;
      };
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };

    # Informational kernel logs with Solarized-colored TTY
    kernelParams = [
      "loglevel=6"
      "systemd.show_status=true"
      "rd.udev.log_level=3"
    ];

    # Kernel
    kernelPackages = pkgs.linuxPackages_latest;

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

  # Expose grub-reboot for "Reboot to Windows" power menu
  environment.systemPackages = [ pkgs.grub2 ];

  # Solarized Dark TTY — beautiful LUKS prompt + kernel logs
  console = {
    earlySetup = true;
    font = "${consoleFont}/share/consolefonts/SauceCodePro48.psf.gz";
    packages = [ consoleFont ];
    colors = [
      "002b36" # color0  base03 (background)
      "dc322f" # color1  red
      "859900" # color2  green
      "b58900" # color3  yellow
      "268bd2" # color4  blue
      "d33682" # color5  magenta
      "2aa198" # color6  cyan
      "eee8d5" # color7  base2 (foreground)
      "073642" # color8  base02
      "cb4b16" # color9  orange
      "586e75" # color10 base01
      "657b83" # color11 base00
      "839496" # color12 base0
      "6c71c4" # color13 violet
      "93a1a1" # color14 base1
      "fdf6e3" # color15 base3
    ];
  };
}
