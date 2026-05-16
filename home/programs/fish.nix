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

      # Claude-generated tech tip greeting
      function fish_greeting
        set -l tips_file "$HOME/.local/share/greeting/tips.json"
        if test -f $tips_file
          set -l tip (jq -r '.[(now | floor) % length]' $tips_file)
          set_color brblue
          echo "  $tip"
          set_color normal
        end
      end

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

      # Override bobthefish nix prompt to show primary tool + version
      function __bobthefish_prompt_nix -S -d 'Display current nix environment'
        test -z "$IN_NIX_SHELL"; and return

        __bobthefish_start_segment $color_nix
        set -l nix_info "$IN_NIX_SHELL"

        if set -q nativeBuildInputs[1]
          # Extract first package name and version from nix store path
          set -l first_pkg (string split ' ' $nativeBuildInputs)[1]
          set -l pkg_base (basename $first_pkg)
          # Parse name-version from store path basename (strip hash prefix)
          if string match -rq '^[a-z0-9]+-(?<pkg_name>.+)-(?<pkg_ver>[0-9]+\\..+)$' $pkg_base
            set nix_info "$pkg_name $pkg_ver"
          end
        end

        echo -ns $nix_glyph $nix_info ' '
        set_color normal
      end
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

      # Hermes — interact with the gateway as the hermes service user so files
      # in /var/lib/hermes stay owned by hermes:hermes (kiper is not in the
      # hermes group; NOPASSWD rule lives in nixos/users.nix).
      hs = "sudo -u hermes hermes";
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

  # Daily Claude-generated tech tips for fish greeting
  systemd.user.services.greeting-generate = {
    Unit.Description = "Generate fish greeting tips via Claude";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash %h/.config/nixos/home/scripts/greeting-generate.sh";
      Environment = "PATH=${pkgs.jq}/bin:/run/current-system/sw/bin:%h/.nix-profile/bin";
    };
  };

  systemd.user.timers.greeting-generate = {
    Unit.Description = "Daily fish greeting tips generation";
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
