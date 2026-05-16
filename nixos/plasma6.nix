{ vars, ... }:
{
  services.desktopManager.plasma6.enable = true;

  # Stylix's qt target makes HM enable its qt module, which exports
  # QT_STYLE_OVERRIDE. Plasma 6's Kirigami then QML-imports that value as a
  # QtQuickControls2 style; the import fails for any widget-style name
  # (kvantum, Breeze, Fusion, …) giving cursor-on-black. Plasma manages
  # widget styling natively via kdeglobals. Disable on both layers.
  stylix.targets.qt.enable = false;
  home-manager.users.${vars.username}.stylix.targets.qt.enable = false;
}
