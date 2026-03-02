{ config, pkgs, lib, ... }:

let
  # Hides tabs toolbar and URL bar — SSB/PWA feel
  # Ctrl+L still opens the URL bar; F6 cycles focus
  minimalChrome = ''
    #TabsToolbar { visibility: collapse !important; }
    #nav-bar { visibility: collapse !important; }
  '';

  mkPwa = { id, name, url, class, icon }: {
    profile = {
      inherit id;
      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "browser.tabs.inTitlebar" = 0;
        "widget.use-xdg-desktop-portal.notifications" = 1;
      };
      userChrome = minimalChrome;
    };
    desktopEntry = {
      inherit name icon;
      exec = ''firefox -P "${class}" --class "${class}" --no-remote "${url}"'';
      terminal = false;
      categories = [ "Network" ];
      startupNotify = true;
      settings.StartupWMClass = class;
    };
  };

  pwas = {
    messenger = mkPwa { id = 1; name = "Messenger"; url = "https://messenger.com";    class = "messenger"; icon = "facebook-messenger"; };
    gmail     = mkPwa { id = 2; name = "Gmail";     url = "https://mail.google.com"; class = "gmail";     icon = "gmail";              };
    claude    = mkPwa { id = 3; name = "Claude";    url = "https://claude.ai";       class = "claude";    icon = "firefox";             };
    github    = mkPwa { id = 4; name = "GitHub";    url = "https://github.com";      class = "github";    icon = "github";              };
  };
in
{
  programs.firefox.profiles =
    lib.mapAttrs (_: p: p.profile) pwas;

  xdg.desktopEntries =
    lib.mapAttrs (_: p: p.desktopEntry) pwas;
}
