{ config, pkgs, lib, vars, ... }:

let
  # KDE-native graphical password prompt — Qt-based, integrates with kwallet,
  # works under Plasma and Hyprland (no compositor coupling).
  askpass = "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";
in
{
  # Shared development group
  users.groups.devel = { };

  users.users.${vars.username} = {
    isNormalUser = true;
    description = vars.fullName;
    extraGroups = [
      "wheel" # sudo
      "networkmanager"
      "docker"
      "video"
      "audio"
      "input"
      "render"
      "libvirtd"
      "devel" # /devel shared workspace
    ];
    shell = pkgs.fish;
  };

  # Enable Fish system-wide (needed for user shell)
  programs.fish.enable = true;

  security.sudo.extraRules =
    # Run the hermes CLI as the hermes-agent service user without a password.
    # Interactive use goes through the `hs` fish abbr (= `sudo -u hermes hermes`)
    # so files in /var/lib/hermes stay owned by hermes:hermes — kiper is not in
    # the hermes group, so direct writes would land as kiper:users and the
    # gateway couldn't read them back.
    [{
      users = [ vars.username ];
      runAs = "hermes";
      commands = [{
        command = "/run/current-system/sw/bin/hermes";
        options = [ "NOPASSWD" ];
      }];
    }]
    # Passwordless grub-reboot for the "Reboot to Windows" power menu option
    ++ lib.optionals (vars ? windowsBootEntry && vars.windowsBootEntry != null) [{
      users = [ vars.username ];
      commands = [{
        command = "/run/current-system/sw/bin/grub-reboot";
        options = [ "NOPASSWD" ];
      }];
    }];

  # Sudo askpass — KDE ksshaskpass for non-TTY contexts (`sudo -A`)
  environment.etc."sudo.conf" = {
    mode = "0400";
    text = "Path askpass ${askpass}";
  };

  # Preserve Wayland env vars so the askpass dialog can find the compositor
  security.sudo.extraConfig = ''
    Defaults env_keep += "WAYLAND_DISPLAY XDG_RUNTIME_DIR DISPLAY"
  '';

  # SSH askpass reuses the same dialog
  programs.ssh.enableAskPassword = true;
  programs.ssh.askPassword = askpass;

  # ── elf user (Claude Code remote worker) ─────────────────────────
  users.users.elf = {
    isNormalUser = true;
    description = "Elf — Claude Code remote worker";
    shell = pkgs.bash;
    extraGroups = [
      "devel"  # /devel shared workspace
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF6M9mQzC9CiDlcol3YnfDIa/BZGF5m0gVjrtj0/NelB elf@lightspeed"
    ];
  };

  # /devel permissions: setgid so new files inherit devel group
  systemd.tmpfiles.rules = [
    "d /devel 2775 root devel - -"
  ];
}
