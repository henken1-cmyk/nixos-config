{ config, pkgs, lib, vars, ... }:

let
  settingsTarget = "/home/${vars.username}/.config/nixos/hosts/${vars.hostname}/vscode-settings.json";
in
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;

    mutableExtensionsDir = true;

    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        # Nix
        jnoortheen.nix-ide

        # Go
        golang.go

        # Rust
        rust-lang.rust-analyzer

        # Git
        eamodio.gitlens

        # Remote
        ms-vscode-remote.remote-ssh

        # General
        editorconfig.editorconfig
        esbenp.prettier-vscode
      ];

      # Suppress HM-managed settings.json — we symlink a mutable repo file instead
      userSettings = lib.mkForce {};
    };
  };

  # Stylix target stays enabled — it installs the color theme extension.
  # Its settings injection is overridden by mkForce {} above.

  # Symlink settings.json to a mutable, version-controlled, host-specific repo file.
  # Stylix theme/font values are baked into the JSON file directly.
  home.activation.vscodeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings_file="$HOME/.config/Code/User/settings.json"
    mkdir -p "$(dirname "$settings_file")"
    if [ ! -L "$settings_file" ] || [ "$(readlink "$settings_file")" != "${settingsTarget}" ]; then
      rm -f "$settings_file"
      ln -s "${settingsTarget}" "$settings_file"
    fi
  '';
}
