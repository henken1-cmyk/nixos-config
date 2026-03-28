{ config, pkgs, lib, vars, ... }:

let
  # Custom Plymouth theme — patched Stylix theme with custom LUKS prompt
  customPlymouth = pkgs.runCommand "plymouth-custom" {
    nativeBuildInputs = [ pkgs.librsvg ];
  } ''
    mkdir -p $out/share/plymouth/themes/custom

    # NixOS snowflake logo (smaller spinning icon)
    rsvg-convert -w 50 -h 50 \
      ${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg \
      -o $out/share/plymouth/themes/custom/logo.png

    # Theme definition
    cat > $out/share/plymouth/themes/custom/custom.plymouth << EOF
    [Plymouth Theme]
    Name=Custom
    ModuleName=script

    [script]
    ImageDir=$out/share/plymouth/themes/custom
    ScriptFile=$out/share/plymouth/themes/custom/custom.script
    EOF

    # Plymouth script (Stylix colors + custom password prompt)
    cat > $out/share/plymouth/themes/custom/custom.script << 'SCRIPT'
    center_x = Window.GetWidth() / 2;
    center_y = Window.GetHeight() / 2;
    baseline_y = Window.GetHeight() * 0.9;
    message_y = Window.GetHeight() * 0.75;

    Window.SetBackgroundTopColor(0.109375, 0.054688, 0.179688);
    Window.SetBackgroundBottomColor(0.109375, 0.054688, 0.179688);

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
    bullet.image = Image.Text("•", 0.625000, 0.906250, 0.750000);

    fun password_callback (prompt_text, bullet_count) {
      deactivate_spinner();
      prompt.image = Image.Text("Podaj magiczne słowo...", 0.625000, 0.906250, 0.750000);
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
      question.image = Image.Text(prompt_text, 0.625000, 0.906250, 0.750000);
      question.sprite = Sprite(question.image);
      question.sprite.SetPosition(
        center_x - (question.image.GetWidth() / 2),
        baseline_y - question.image.GetHeight(),
        1
      );
      answer.image = Image.Text(entry, 0.625000, 0.906250, 0.750000);
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
      message.image = Image.Text(text, 0.625000, 0.906250, 0.750000);
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
    ] ++ map (m: "video=${m}:D") (vars.monitors_drm or []);

    plymouth = {
      enable = true;
      theme = lib.mkForce "custom";
      themePackages = lib.mkForce [ customPlymouth ];
    };

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
