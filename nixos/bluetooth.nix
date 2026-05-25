{ config, pkgs, ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true; # Battery level reporting
      };
    };
  };

  # KDE Plasma 6 bundles bluedevil (tray applet + Solid integration); no extra
  # service needed. Blueman (GTK) would otherwise XDG-autostart on top of it.
  services.blueman.enable = false;
}
