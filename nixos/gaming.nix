{ config, pkgs, vars, ... }:

let
  usdxSongDir = "/games/usdx/songs";
  ultrastardxDesktop = pkgs.makeDesktopItem {
    name = "ultrastardx";
    desktopName = "UltraStar Deluxe";
    comment = "Karaoke program that evaluates your performance";
    icon = "ultrastardx";
    exec = "ultrastardx";
    terminal = false;
    categories = [ "Game" "ArcadeGame" ];
    keywords = [ "karaoke" "singing" "song" "microphone" ];
  };
  ultrastardx = pkgs.symlinkJoin {
    name = "ultrastardx-wrapped";
    paths = [ pkgs.ultrastardx ultrastardxDesktop ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/ultrastardx \
        --add-flags "-songpath ${usdxSongDir}"
      install -Dm644 ${pkgs.ultrastardx.src}/icons/ultrastardx-icon.svg \
        $out/share/icons/hicolor/scalable/apps/ultrastardx.svg
      install -Dm644 ${pkgs.ultrastardx.src}/icons/ultrastardx-icon_512.png \
        $out/share/icons/hicolor/512x512/apps/ultrastardx.png
      install -Dm644 ${pkgs.ultrastardx.src}/icons/ultrastardx-icon_256.png \
        $out/share/icons/hicolor/256x256/apps/ultrastardx.png
      install -Dm644 ${pkgs.ultrastardx.src}/icons/ultrastardx-icon_32.png \
        $out/share/icons/hicolor/32x32/apps/ultrastardx.png
    '';
    meta.mainProgram = "ultrastardx";
  };
in
{
  # ── Steam (provides steam-run FHS environment for Wine games) ────
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = false;
  };

  # ── GameMode (CPU governor, nice, GPU perf mode during games) ────
  programs.gamemode.enable = true;

  # ── Gamescope (Wayland micro-compositor for frame pacing, FSR) ──
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  # ── Esync/Fsync file descriptor limits ──────────────────────────
  # Required for Wine synchronization performance. Without this,
  # games using esync will crash or stutter.
  security.pam.loginLimits = [{
    domain = "*";
    type = "hard";
    item = "nofile";
    value = "524288";
  }];

  # ── UltraStar Deluxe (karaoke, songs pinned to nocow /games) ────
  # ── umu-launcher (FHS-wrapped Proton runner Lutris invokes) ────
  # Lutris auto-downloads a generic umu binary that lacks the FHS env
  # pressure-vessel needs on NixOS — without it, ldconfig isn't found,
  # NVIDIA Vulkan driver passthrough fails, and games crash with
  # VK_ERROR_INCOMPATIBLE_DRIVER. The nixpkgs build wraps umu in bwrap.
  environment.systemPackages = [ ultrastardx pkgs.umu-launcher ];

  # ── /games directory permissions ────────────────────────────────
  systemd.tmpfiles.rules = [
    "d /games 0755 ${vars.username} users -"
    "d /games/usdx 0755 ${vars.username} users -"
    "d ${usdxSongDir} 0755 ${vars.username} users -"
  ];
}
