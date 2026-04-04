{ config, pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    # AI
    inputs.claude-code.packages.${pkgs.system}.default
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

    # Wallpaper
    swww

    # Emoji picker
    bemoji

    # Communication
    caprine
    discord
    spotify
    youtube-music

    # Media
    mpv
    imv
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
    keepassxc
    polkit_gnome

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

    # Wayland utilities
    wtype # Keyboard input simulation (for emoji picker)

    # Nix tools
    nil # Nix LSP (for VSCode and other editors)

    # Network discovery
    wsdd # Windows Service Discovery for Thunar network browsing

    # Virtualization / disk images
    libguestfs-with-appliance # guestmount for VHDX/VHD/qcow2
    qemu_kvm # provides qemu-img/qemu-nbd needed by libguestfs

    # Office
    libreoffice

    # Archive support
    p7zip
  ];
}
