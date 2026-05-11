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

  # Don't block boot waiting for network — desktop doesn't need it
  systemd.services.NetworkManager-wait-online.enable = false;

  # systemd-resolved: faster DNS, better Tailscale split-DNS via D-Bus
  services.resolved = {
    enable = true;
    settings.Resolve.DNSSEC = "false";         # router doesn't support DNSSEC, skip validation
    settings.Resolve.FallbackDNS = [ "1.1.1.1" "9.9.9.9" ];
    settings.Resolve.MulticastDNS = "no";   # avahi handles mDNS, avoid conflict
  };
  networking.networkmanager.dns = "systemd-resolved";

  # ── L2TP/IPSec VPN support ─────────────────────────────────────
  # strongSwan on NixOS has two issues (nixpkgs#375352):
  # 1. Integrity check fails (NixOS-patched binaries)
  # 2. Missing /etc/strongswan.conf after PR#372967

  # Fix 1: Override strongswan AND nm-l2tp to propagate the fix
  nixpkgs.overlays = [(final: prev: {
    strongswan = prev.strongswan.overrideAttrs (old: {
      configureFlags = old.configureFlags ++ [ "--disable-integrity-test" ];
    });
    networkmanager-l2tp = prev.networkmanager-l2tp.override {
      strongswan = final.strongswan;
    };
  })];

  # Fix 2: Create /etc/strongswan.conf so charon doesn't abort
  environment.etc."strongswan.conf".text = "";

  # Runtime disable of integrity test (belt and suspenders)
  environment.etc."strongswan.d/charon/integrity-test.conf".text = ''
    charon {
      integrity_test = no
    }
  '';

  networking.networkmanager.plugins = with pkgs; [
    networkmanager-l2tp
  ];

  environment.systemPackages = with pkgs; [
    networkmanagerapplet # nm-applet for tray
  ];
}
