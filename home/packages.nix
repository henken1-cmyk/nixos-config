{ config, pkgs, inputs, ... }:

let
  usdb-import = pkgs.writeShellApplication {
    name = "usdb-import";
    runtimeInputs = with pkgs; [
      yt-dlp
      ffmpeg
      curl
      coreutils
      findutils
      gawk
      gnugrep
    ];
    text = builtins.readFile ./scripts/usdb-import.sh;
  };
in
{
  home.packages = with pkgs; [
    usdb-import
    # AI
    inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default
    # CLI essentials
    ripgrep
    fd
    eza
    jq
    httpie
    curlie
    unzip
    zip
    file
    tree
    tldr
    dust

    # Dev tools
    lazygit
    lazydocker
    gh # GitHub CLI
    imagemagick

    # Hyprland ecosystem
    hyprpicker # Color picker
    hyprsunset # Night light
    swayosd # Volume OSD

    # Screenshot / recording
    grim
    slurp
    satty
    gpu-screen-recorder

    # Clipboard
    wl-clipboard
    cliphist

    # Wallpaper (swww package, binaries renamed to awww/awww-daemon in 0.10+)
    swww

    # Emoji picker
    bemoji

    # Audio
    sox # Audio recording/playback (used by Claude Code voice mode)

    # Media
    mpv
    imv
    ffmpeg-full
    playerctl # Media key control (play/pause/next/prev)

    # File management
    thunar
    thunar-volman
    tumbler # Thumbnail generation for Thunar
    ffmpegthumbnailer # Video thumbnails
    udiskie

    # Notifications
    libnotify # notify-send

    # Auth / security
    age
    keepassxc
    hyprpolkitagent

    # Image format support
    webp-pixbuf-loader # WebP in GTK apps

    # Appearance
    papirus-icon-theme
    libsForQt5.qt5ct
    kdePackages.qt6ct
    libsForQt5.qtstyleplugin-kvantum
    kdePackages.qtstyleplugin-kvantum

    # Waybar extras
    wttrbar # Rich weather tooltip for waybar

    # System info
    fastfetch
    nvtopPackages.full # GPU monitor TUI (NVIDIA + Intel + AMD)

    # Wayland utilities
    wtype # Keyboard input simulation (for emoji picker)

    # Nix tools
    nil # Nix LSP (for VSCode and other editors)
    nix-tree # Interactive nix store dependency browser

    # Network discovery
    wsdd # Windows Service Discovery for Thunar network browsing

    # Remote desktop / streaming
    parsec-bin

    # Virtualization / disk images
    libguestfs-with-appliance # guestmount for VHDX/VHD/qcow2
    qemu_kvm # provides qemu-img/qemu-nbd needed by libguestfs

    # Office
    libreoffice

    # Archive support
    p7zip

    # 3D / creative
    (blender.override { cudaSupport = true; })
  ];
}
