{ config, pkgs, ... }:

{
  # Jellyfin runs as a Docker container now (see /devel/hub/docker-compose.yml),
  # NOT as a NixOS service. We deliberately keep the `jellyfin` user/group pinned
  # to their original uid/gid so that:
  #   - the migrated /var/lib/jellyfin (@jellyfin subvolume) ownership stays valid,
  #   - the container runs as 987:983 and reads its own data with no chown,
  #   - video/render membership documents the GPU (NVENC/NVDEC) access path.
  #
  # The @jellyfin subvolume mount is intentionally retained in
  # hosts/lightspeed/hardware-configuration.nix and bind-mounted into the
  # container as /config. GPU passthrough is via hardware.nvidia-container-toolkit
  # (hosts/lightspeed/configuration.nix).
  #
  # Full LAN functionality is preserved: the container publishes 8096/tcp plus the
  # discovery ports 7359/udp (Jellyfin auto-discovery) and 1900/udp (DLNA/SSDP),
  # reachable via Docker's own port forwarding (no NixOS firewall rule needed).
  users.groups.jellyfin.gid = 983;
  users.users.jellyfin = {
    isSystemUser = true;
    group = "jellyfin";
    uid = 987;
    extraGroups = [ "video" "render" ];
  };
}
