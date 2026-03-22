{ config, pkgs, ... }:

{
  # CUPS: socket-activated (starts on first print request, not at boot)
  services.printing = {
    enable = true;
    startWhenNeeded = true;
    drivers = with pkgs; [
      gutenprint
      gutenprintBin
      cups-pdf-to-pdf
    ];
  };

  # Network printer discovery
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  environment.systemPackages = with pkgs; [
    system-config-printer
  ];
}
