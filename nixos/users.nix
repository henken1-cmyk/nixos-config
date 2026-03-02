{ config, pkgs, vars, ... }:

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

  # /devel permissions: setgid so new files inherit devel group
  systemd.tmpfiles.rules = [
    "d /devel 2775 root devel - -"
  ];
}
