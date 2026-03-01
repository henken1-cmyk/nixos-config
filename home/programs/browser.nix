{ config, pkgs, inputs, ... }:

let
  addons = inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  programs.firefox = {
    enable = true;

    profiles.default = {
      id = 0;
      isDefault = true;

      # Extensions
      extensions.force = true;
      extensions.packages = with addons; [
        ublock-origin
        darkreader
        privacy-badger
        keepassxc-browser
      ];

      # Settings
      settings = {
        # Wayland
        "widget.use-xdg-desktop-portal.file-picker" = 1;
        "widget.use-xdg-desktop-portal.mime-handler" = 1;

        # Privacy
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
        "browser.send_pings" = false;
        "dom.battery.enabled" = false;

        # Performance
        "gfx.webrender.all" = true;
        "layers.acceleration.force-enabled" = true;
        "media.ffmpeg.vaapi.enabled" = true;

        # UI
        "browser.tabs.inTitlebar" = 0;
        "browser.uidensity" = 1;
        "browser.toolbars.bookmarks.visibility" = "newtab";

        # Enable Stylix userChrome/userContent CSS
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

        # Disable telemetry
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.unified" = false;
        "datareporting.healthreport.uploadEnabled" = false;

        # New tab
        "browser.newtabpage.activity-stream.feeds.topsites" = false;
        "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
      };

      # Search engines
      search = {
        default = "ddg";
        force = true;
      };
    };
  };
}
