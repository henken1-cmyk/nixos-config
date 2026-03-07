{ config, pkgs, ... }:

{
  networking = {
    networkmanager.enable = true;

    # Firewall
    firewall = {
      enable = true;
      # Trust all Docker interfaces (default bridge + custom br-* networks)
      # "docker+" is an iptables wildcard matching docker0, dockerveth*, etc.
      # "br-+" matches all Docker custom bridge networks (br-<hash>)
      trustedInterfaces = [ "docker0" "br-+" ];
      # Open ports as needed:
      # allowedTCPPorts = [ 22 ];
      # allowedUDPPorts = [ ];
    };
  };

  # DNS — NetworkManager handles this, but we can add fallbacks
  # networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];

  environment.systemPackages = with pkgs; [
    networkmanagerapplet # nm-applet for tray
  ];
}
