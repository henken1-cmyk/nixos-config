{ config, pkgs, ... }:

{
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  # Ensure data directory ownership (needed for dedicated btrfs subvolume)
  systemd.tmpfiles.rules = [
    "d /var/lib/jellyfin 0700 jellyfin jellyfin -"
  ];

  # NVIDIA GPU access for NVENC/NVDEC hardware transcoding
  users.users.jellyfin.extraGroups = [ "video" "render" ];

  environment.systemPackages = with pkgs; [
    jellyfin-ffmpeg
  ];
}
