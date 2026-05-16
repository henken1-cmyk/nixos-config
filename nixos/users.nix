{ config, pkgs, lib, vars, ... }:

let
  fuzzel-askpass = pkgs.writeShellScript "fuzzel-askpass" ''
    # Read the command that invoked sudo from parent process
    raw=$(${pkgs.coreutils}/bin/tr '\0' ' ' < /proc/$PPID/cmdline 2>/dev/null)
    cmd=$(echo "$raw" | ${pkgs.gnused}/bin/sed 's|.*/sudo[^ ]* ||; s/ *-[AknSEHPBu][^ ]*//g; s/^ *//')
    exec ${pkgs.fuzzel}/bin/fuzzel \
      --dmenu \
      --password \
      --prompt-only="🔒 ''${cmd:-sudo} › " \
      --placeholder="password" \
      --width=80 \
      --lines=0
  '';
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

  # Sudo askpass via fuzzel (graphical password prompt for non-TTY contexts)
  environment.etc."sudo.conf" = {
    mode = "0400";
    text = "Path askpass ${fuzzel-askpass}";
  };

  # Preserve Wayland env vars so fuzzel-askpass can find the compositor
  security.sudo.extraConfig = ''
    Defaults env_keep += "WAYLAND_DISPLAY XDG_RUNTIME_DIR DISPLAY"
  '';

  # SSH askpass reuses the same fuzzel dialog
  programs.ssh.enableAskPassword = true;
  programs.ssh.askPassword = toString fuzzel-askpass;

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
