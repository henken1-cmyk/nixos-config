{ config, pkgs, lib, vars, ... }:

let
  colors = config.lib.stylix.colors;

  bootloader   = vars.bootloader     or "grub";          # "grub" | "systemd-boot"
  use4kFont    = vars.use4kBootFont  or false;
  usePlymouth  = vars.usePlymouth    or false;
  useCachy     = (vars.kernelPackages or "default") == "cachyos-lto-v3";

  fontSize      = toString (vars.grubFontSize    or 16);
  consoleFontSz = toString (vars.consoleFontSize or 16);

  sauceCodePro    = pkgs.nerd-fonts.sauce-code-pro;
  sauceCodeProTtf = "${sauceCodePro}/share/fonts/truetype/NerdFonts/SauceCodePro/SauceCodeProNerdFontMono-Regular.ttf";

  # 4K-friendly GRUB font (lightspeed only)
  grubFont = pkgs.runCommand "saucecodepro-grub-font-${fontSize}" {
    nativeBuildInputs = [ pkgs.grub2 ];
  } ''
    mkdir -p $out
    grub-mkfont --size=${fontSize} -o $out/SauceCodePro.pf2 ${sauceCodeProTtf}
  '';

  # 4K console PSF (lightspeed only)
  consoleFont = pkgs.runCommand "saucecodepro-console-font-${consoleFontSz}" {
    nativeBuildInputs = [ pkgs.otf2bdf pkgs.bdf2psf ];
  } ''
    mkdir -p $out/share/consolefonts
    otf2bdf -p ${consoleFontSz} ${sauceCodeProTtf} -o raw.bdf || true
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

  # Custom Plymouth theme — Stylix-driven background, snowflake spinner,
  # Polish LUKS prompt. Used when usePlymouth = true (adam, henkenit).
  customPlymouth = pkgs.runCommand "plymouth-custom" {
    nativeBuildInputs = [ pkgs.librsvg ];
  } ''
    mkdir -p $out/share/plymouth/themes/custom

    rsvg-convert -w 50 -h 50 \
      ${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg \
      -o $out/share/plymouth/themes/custom/logo.png

    cat > $out/share/plymouth/themes/custom/custom.plymouth << EOF
    [Plymouth Theme]
    Name=Custom
    ModuleName=script

    [script]
    ImageDir=$out/share/plymouth/themes/custom
    ScriptFile=$out/share/plymouth/themes/custom/custom.script
    EOF

    cat > $out/share/plymouth/themes/custom/custom.script << 'SCRIPT'
    center_x = Window.GetWidth() / 2;
    center_y = Window.GetHeight() / 2;
    baseline_y = Window.GetHeight() * 0.9;
    message_y = Window.GetHeight() * 0.75;

    Window.SetBackgroundTopColor(${colors.base00-dec-r}, ${colors.base00-dec-g}, ${colors.base00-dec-b});
    Window.SetBackgroundBottomColor(${colors.base00-dec-r}, ${colors.base00-dec-g}, ${colors.base00-dec-b});

    logo.image = Image("logo.png");
    logo.sprite = Sprite(logo.image);
    logo.sprite.SetPosition(
      center_x - (logo.image.GetWidth() / 2),
      center_y - (logo.image.GetHeight() / 2),
      1
    );

    logo.spinner_active = 1;
    logo.spinner_third = 0;
    logo.spinner_index = 0;
    logo.spinner_max_third = 32;
    logo.spinner_max = logo.spinner_max_third * 3;

    real_index = 0;
    for (third = 0; third < 3; third++) {
      for (index = 0; index < logo.spinner_max_third; index++) {
        subthird = index / logo.spinner_max_third;
        angle = (third + ((Math.Sin(Math.Pi * (subthird - 0.5)) / 2) + 0.5)) / 3;
        logo.spinner_image[real_index] = logo.image.Rotate(2*Math.Pi * angle);
        real_index++;
      }
    }

    fun activate_spinner () { logo.spinner_active = 1; }
    fun deactivate_spinner () { logo.spinner_active = 0; logo.sprite.SetImage(logo.image); }

    fun refresh_callback () {
      if (logo.spinner_active) {
        logo.spinner_index = (logo.spinner_index + 1) % (logo.spinner_max * 2);
        logo.sprite.SetImage(logo.spinner_image[Math.Int(logo.spinner_index / 2)]);
      }
    }
    Plymouth.SetRefreshFunction(refresh_callback);

    prompt = null;
    bullets = null;
    bullet.image = Image.Text("•", ${colors.base05-dec-r}, ${colors.base05-dec-g}, ${colors.base05-dec-b});

    fun password_callback (prompt_text, bullet_count) {
      deactivate_spinner();
      prompt.image = Image.Text("Podaj magiczne słowo...", ${colors.base05-dec-r}, ${colors.base05-dec-g}, ${colors.base05-dec-b});
      prompt.sprite = Sprite(prompt.image);
      prompt.sprite.SetPosition(
        center_x - (prompt.image.GetWidth() / 2),
        baseline_y - prompt.image.GetHeight(),
        1
      );
      total_width = bullet_count * bullet.image.GetWidth();
      start_x = center_x - (total_width / 2);
      bullets = null;
      for (i = 0; i < bullet_count; i++) {
        bullets[i].sprite = Sprite(bullet.image);
        bullets[i].sprite.SetPosition(
          start_x + (i * bullet.image.GetWidth()),
          baseline_y + bullet.image.GetHeight(),
          1
        );
      }
    }
    Plymouth.SetDisplayPasswordFunction(password_callback);

    question = null;
    answer = null;
    fun question_callback(prompt_text, entry) {
      deactivate_spinner();
      question = null;
      answer = null;
      question.image = Image.Text(prompt_text, ${colors.base05-dec-r}, ${colors.base05-dec-g}, ${colors.base05-dec-b});
      question.sprite = Sprite(question.image);
      question.sprite.SetPosition(
        center_x - (question.image.GetWidth() / 2),
        baseline_y - question.image.GetHeight(),
        1
      );
      answer.image = Image.Text(entry, ${colors.base05-dec-r}, ${colors.base05-dec-g}, ${colors.base05-dec-b});
      answer.sprite = Sprite(answer.image);
      answer.sprite.SetPosition(
        center_x - (answer.image.GetWidth() / 2),
        baseline_y + answer.image.GetHeight(),
        1
      );
    }
    Plymouth.SetDisplayQuestionFunction(question_callback);

    message = null;
    fun message_callback(text) {
      message.image = Image.Text(text, ${colors.base05-dec-r}, ${colors.base05-dec-g}, ${colors.base05-dec-b});
      message.sprite = Sprite(message.image);
      message.sprite.SetPosition(
        center_x - message.image.GetWidth() / 2,
        message_y,
        1
      );
    }
    Plymouth.SetMessageFunction(message_callback);

    fun normal_callback() {
      prompt = null; bullets = null;
      question = null; answer = null;
      message = null;
      activate_spinner();
    }
    Plymouth.SetDisplayNormalFunction(normal_callback);

    fun quit_callback() { prompt = null; bullets = null; deactivate_spinner(); }
    Plymouth.SetQuitFunction(quit_callback);
    SCRIPT
  '';
in
{
  boot = lib.mkMerge [
    # ── Common ──────────────────────────────────────────────────────
    {
      kernelPackages =
        if useCachy
        then pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto-x86_64-v3
        else pkgs.linuxPackages_latest;

      initrd.systemd.enable = true;
      initrd.supportedFilesystems = [ "btrfs" ];
      supportedFilesystems = [ "btrfs" ];
    }

    # ── GRUB (lightspeed) ───────────────────────────────────────────
    (lib.mkIf (bootloader == "grub") {
      loader.grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        useOSProber = true;
        configurationLimit = vars.bootGenerations or 10;
      };
      loader.efi.canTouchEfiVariables = true;
      loader.timeout = 3;

      kernelParams = [
        "loglevel=6"
        "systemd.show_status=true"
        "rd.udev.log_level=3"
        "amd_pstate=active"
        "nowatchdog"
      ];
      consoleLogLevel = 6;
    })

    (lib.mkIf (bootloader == "grub" && use4kFont) {
      loader.grub.font = lib.mkForce "${grubFont}/SauceCodePro.pf2";
      loader.grub.fontSize = vars.grubFontSize or 16;
      loader.grub.extraConfig = ''
        terminal_input console
      '';
    })

    (lib.mkIf (bootloader == "grub" && (vars.showFirmwareEntry or false)) {
      loader.grub.extraEntries = ''
        menuentry "UEFI Firmware Settings" --class efi {
          fwsetup
        }
      '';
    })

    # ── systemd-boot (adam, henkenit) ───────────────────────────────
    (lib.mkIf (bootloader == "systemd-boot") {
      loader.systemd-boot = {
        enable = true;
        consoleMode = "auto"; # "max" breaks Plymouth transition
        editor = false;       # security
        configurationLimit = vars.bootGenerations or 10;
        sortKey = "nixos";
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
      loader.efi.canTouchEfiVariables = true;
      loader.timeout = 1;

      kernelParams = [
        "quiet"
        "splash"
        "loglevel=3"
        "systemd.show_status=auto"
        "rd.udev.log_level=3"
        "udev.log_priority=3"
        "vt.global_cursor_default=0"
      ] ++ map (m: "video=${m}:D") (vars.monitors_drm or []);

      consoleLogLevel = 3;
      initrd.verbose = false;
    })

    # ── Plymouth (opt-in) ───────────────────────────────────────────
    (lib.mkIf usePlymouth {
      plymouth = {
        enable = true;
        theme = lib.mkForce "custom";
        themePackages = lib.mkForce [ customPlymouth ];
      };
    })
  ];

  # USB wake disable — opt-in (lightspeed: prevents immediate wake on hibernate)
  services.udev.extraRules = lib.mkIf (vars.disableUsbWake or false) ''
    ACTION=="add", SUBSYSTEM=="pci", DRIVER=="xhci_hcd", ATTR{power/wakeup}="disabled"
  '';

  # grub-reboot for "Reboot to Windows" power menu (GRUB hosts only)
  environment.systemPackages = lib.mkIf (bootloader == "grub") [ pkgs.grub2 ];

  # Console: 4K SauceCodePro on lightspeed; terminus + black palette when Plymouth active
  console =
    (if use4kFont then {
      earlySetup = true;
      font = "${consoleFont}/share/consolefonts/SauceCodePro.psf.gz";
      packages = [ consoleFont ];
    } else {
      earlySetup = true;
      font = "ter-v24n";
      packages = [ pkgs.terminus_font ];
    })
    // (lib.optionalAttrs usePlymouth {
      # All-black palette hides the brief VT flash between Plymouth → greeter → Hyprland
      colors = [
        "000000" "000000" "000000" "000000"
        "000000" "000000" "000000" "000000"
        "000000" "000000" "000000" "000000"
        "000000" "000000" "000000" "000000"
      ];
    });
}
