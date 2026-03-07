{ config, pkgs, ... }:

{
  # ── Btrfs automatic scrub ──────────────────────────────────────────
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  # ── btrbk — automated snapshots + retention ────────────────────────
  services.btrbk.instances."default" = {
    onCalendar = "hourly";
    settings = {
      timestamp_format = "long-iso";
      snapshot_preserve_min = "2d";
      snapshot_preserve = "48h 14d 4w 3m";
      snapshot_dir = "@snapshots";

      volume."/mnt/btrfs-root" = {
        subvolume."@root" = {
          snapshot_name = "root";
        };
        subvolume."@home" = {
          snapshot_name = "home";
        };
        subvolume."@devel" = {
          snapshot_name = "devel";
        };
        # @nix: not snapshotted — reproducible from flake
        # @log: not snapshotted — preserved across rollbacks but not worth snapshot space
        # @shared: not snapshotted — ephemeral collaboration area
        # @swap: not snapshotted
      };
    };
  };

  # ── Btrfs tools ────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    btrfs-progs
    btrbk
    compsize # Show actual disk usage with compression ratios
  ];
}
