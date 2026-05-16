{
  # KDE's display manager. Replaces greetd+regreet for lightspeed only —
  # SDDM integrates cleanly with Plasma 6 (Wayland greeter, session picker)
  # and avoids the xdg-desktop-portal-hyprland crashes we saw during
  # regreet-inside-Hyprland handoff.
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # Plasma X11 fallback still needs xserver.
  services.xserver.enable = true;
}
