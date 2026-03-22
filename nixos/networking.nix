{ config, pkgs, ... }:

{
  networking = {
    networkmanager.enable = true;

    # Firewall
    firewall = {
      enable = true;
      # Open ports as needed:
      # allowedTCPPorts = [ 22 ];
      # allowedUDPPorts = [ ];
    };
  };

  # Don't block boot waiting for network — desktop doesn't need it
  systemd.services.NetworkManager-wait-online.enable = false;

  # DNS — NetworkManager handles this, but we can add fallbacks
  # networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];

  environment.systemPackages = with pkgs; [
    networkmanagerapplet # nm-applet for tray
  ];
}
