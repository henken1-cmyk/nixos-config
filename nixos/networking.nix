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

  # systemd-resolved: faster DNS, better Tailscale split-DNS via D-Bus
  services.resolved = {
    enable = true;
    dnssec = "false";                        # router doesn't support DNSSEC, skip validation
    fallbackDns = [ "1.1.1.1" "9.9.9.9" ];
    settings.Resolve.MulticastDNS = "no";   # avahi handles mDNS, avoid conflict
  };
  networking.networkmanager.dns = "systemd-resolved";

  environment.systemPackages = with pkgs; [
    networkmanagerapplet # nm-applet for tray
  ];
}
