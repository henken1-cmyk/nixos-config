{ config, pkgs, vars, ... }:

{
  programs.fish = {
    enable = true;

    plugins = [
      { name = "bobthefish"; src = pkgs.fishPlugins.bobthefish.src; }
    ];

    interactiveShellInit = ''
      # Emacs-style keybinds (default, explicit)
      fish_default_key_bindings

      # No greeting
      set -g fish_greeting

      # bobthefish powerline theme config
      set -g theme_color_scheme solarized-dark
      set -g theme_nerd_fonts yes
      set -g theme_display_git yes
      set -g theme_display_git_dirty yes
      set -g theme_display_git_untracked yes
      set -g theme_display_git_ahead_verbose yes
      set -g theme_display_date no
      set -g theme_display_cmd_duration yes
      set -g theme_powerline_fonts yes
    '' + (if vars.zellijAutostart or false then ''
      # Zellij auto-attach (if not already inside zellij)
      if not set -q ZELLIJ
        zellij attach --create default
      end
    '' else "");

    shellAbbrs = {
      # Nix
      nrs = "nh os switch";
      nrt = "nh os test";
      nrb = "nh os boot";
      nfu = "nix flake update";
      nse = "nix search nixpkgs";
      nsh = "nix-shell -p";
      ndev = "nix develop";

      # Git
      g = "git";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline --graph";
      gs = "git status";
      gd = "git diff";
      gco = "git checkout";
      gb = "git branch";
      lg = "lazygit";

      # Navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      # Modern replacements
      ls = "eza --icons";
      ll = "eza -la --icons --git";
      lt = "eza --tree --icons --level=2";
      cat = "bat";
      find = "fd";
      grep = "rg";
      top = "btm";
      du = "dust";

      # Docker
      dc = "docker compose";
      dcu = "docker compose up -d";
      dcd = "docker compose down";
      dcl = "docker compose logs -f";
      ld = "lazydocker";

      # System
      ff = "fastfetch";
      cls = "clear";
    };

    functions = {
      # Quick directory creation and cd
      mkcd = "mkdir -p $argv[1] && cd $argv[1]";

      # Extract anything
      extract = ''
        switch $argv[1]
          case '*.tar.bz2'; tar xjf $argv[1]
          case '*.tar.gz'; tar xzf $argv[1]
          case '*.tar.xz'; tar xJf $argv[1]
          case '*.bz2'; bunzip2 $argv[1]
          case '*.gz'; gunzip $argv[1]
          case '*.tar'; tar xf $argv[1]
          case '*.tbz2'; tar xjf $argv[1]
          case '*.tgz'; tar xzf $argv[1]
          case '*.zip'; unzip $argv[1]
          case '*.7z'; 7z x $argv[1]
          case '*'; echo "Cannot extract '$argv[1]'"
        end
      '';
    };
  };

}
