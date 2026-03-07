{ config, pkgs, vars, ... }:

{
  services.samba = {
    enable = true;
    openFirewall = true; # Opens TCP 445, 139 and UDP 137, 138

    settings = {
      global = {
        workgroup = "WORKGROUP";
        "server string" = vars.hostname;
        security = "user";
      };

      shared = {
        path = "/shared";
        browseable = "yes";
        "read only" = "no";
        "valid users" = "samba";
        "force user" = "samba";
        "force group" = "samba";
        "create mask" = "0664";
        "directory mask" = "0775";
      };
    };
  };

  # Samba user (system account for SMB auth, no shell login)
  users.users.samba = {
    isSystemUser = true;
    group = "samba";
    home = "/shared";
    shell = "/run/current-system/sw/bin/nologin";
  };
  users.groups.samba = {};

  # Samba discovery (so it shows up in file managers)
  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };
}
