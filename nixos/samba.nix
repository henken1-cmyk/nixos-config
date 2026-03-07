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
        "map to guest" = "Bad User";
        "guest account" = "nobody";
      };

      shared = {
        path = "/shared";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = "nobody";
        "force group" = "nogroup";
        "create mask" = "0664";
        "directory mask" = "0775";
      };
    };
  };

  # Samba discovery (so it shows up in file managers)
  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };
}
