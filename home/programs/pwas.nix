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
      exec = "env MOZ_APP_NAME=\"${class}\" firefox -P \"${class}\" --no-remote \"${url}\"";
      terminal = false;
      categories = [ "Network" ];
      startupNotify = true;
      settings.StartupWMClass = class;
    };
  };

  pwas = {
    messenger = mkPwa { id = 1; name = "Messenger"; url = "https://messenger.com";    class = "messenger"; icon = "messenger"; };
    gmail     = mkPwa { id = 2; name = "Gmail";     url = "https://mail.google.com"; class = "gmail";     icon = "gmail";     };
    claude    = mkPwa { id = 3; name = "Claude";    url = "https://claude.ai";       class = "claude";    icon = "claude";    };
    github    = mkPwa { id = 4; name = "GitHub";    url = "https://github.com";      class = "github";    icon = "github";    };
  };
in
{
  programs.firefox.profiles =
    lib.mapAttrs (_: p: p.profile) pwas;

  xdg.desktopEntries =
    lib.mapAttrs (_: p: p.desktopEntry) pwas;

  # Activation script to fetch PWA icons with fallback to Google gstatic
  home.activation.fetchPwaIcons = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "$HOME/.local/share/icons/hicolor/192x192/apps"

    # Strategy 1: Try PWA manifest.json
    fetchFromManifest() {
      local name="$1"
      local url="$2"
      local outFile="$3"

      local manifest
      manifest=$(timeout 5 ${pkgs.curl}/bin/curl -s "$url/manifest.json" 2>/dev/null) || true
      [ -z "$manifest" ] && manifest=$(timeout 5 ${pkgs.curl}/bin/curl -s "$url/site.webmanifest" 2>/dev/null) || true

      [ -z "$manifest" ] && return 1

      local iconUrl
      iconUrl=$(echo "$manifest" | ${pkgs.jq}/bin/jq -r '.icons[] | select(.sizes | contains("192")) | .src' 2>/dev/null | head -1)
      [ -z "$iconUrl" ] && iconUrl=$(echo "$manifest" | ${pkgs.jq}/bin/jq -r '.icons[].src' 2>/dev/null | head -1)

      [ -z "$iconUrl" ] && return 1

      if [[ ! "$iconUrl" =~ ^https?:// ]]; then
        iconUrl="$url/''${iconUrl#/}"
      fi

      timeout 10 ${pkgs.curl}/bin/curl -sLf "$iconUrl" -o "$outFile" 2>/dev/null && return 0
      return 1
    }

    # Strategy 2: Fall back to Google gstatic faviconV2 API (works for JS-rendered sites)
    fetchFromGstatic() {
      local name="$1"
      local url="$2"
      local outFile="$3"

      local domain
      domain=$(printf '%s\n' "$url" | ${pkgs.gnused}/bin/sed 's|https\?://||;s|/.*||')
      local gstaticUrl="https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://$domain&size=256"

      timeout 10 ${pkgs.curl}/bin/curl -sLf "$gstaticUrl" -o "$outFile" 2>/dev/null && return 0
      return 1
    }

    # Resize icon to 192x192
    resizeIcon() {
      local outFile="$1"
      [ -f "$outFile" ] && ${pkgs.imagemagick}/bin/convert "$outFile" -resize 192x192 "$outFile" 2>/dev/null || true
    }

    # Fetch icon with fallback chain
    fetchPwaIcon() {
      local name="$1"
      local url="$2"
      local outFile="$HOME/.local/share/icons/hicolor/192x192/apps/$name.png"

      if fetchFromManifest "$name" "$url" "$outFile"; then
        echo "Downloaded icon for $name from manifest"
        resizeIcon "$outFile"
        return 0
      fi

      if fetchFromGstatic "$name" "$url" "$outFile"; then
        echo "Downloaded icon for $name from Google gstatic"
        resizeIcon "$outFile"
        return 0
      fi

      echo "Warning: Could not fetch icon for $name"
      return 0
    }

    # Fetch icons for all PWAs (best-effort, non-blocking)
    fetchPwaIcon "messenger" "https://messenger.com" || true
    fetchPwaIcon "gmail" "https://mail.google.com" || true
    fetchPwaIcon "claude" "https://claude.ai" || true
    fetchPwaIcon "github" "https://github.com" || true

    # Update icon cache
    ${pkgs.gtk3}/bin/gtk-update-icon-cache -q "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
  '';
}
