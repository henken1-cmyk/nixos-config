{ config, pkgs, ... }:

let
  textfileDir = "/var/lib/prometheus-node-exporter/textfile";

  # btrbk snapshot metrics collector
  btrbkCollector = pkgs.writeShellScript "textfile-btrbk" ''
    OUT="${textfileDir}/btrbk.prom"
    TMP="$OUT.$$"

    {
      for subvol in root home devel data; do
        count=$(${pkgs.btrbk}/bin/btrbk -c /etc/btrbk/default.conf list snapshot --format=raw 2>/dev/null \
          | ${pkgs.gnugrep}/bin/grep -c "snapshot_name=$subvol" || true)
        count=''${count:-0}
        echo "btrbk_snapshots_count{subvolume=\"$subvol\"} $count"
      done

      latest=$(${pkgs.coreutils}/bin/stat -c %Y "${textfileDir}/../" 2>/dev/null || echo 0)
      now=$(${pkgs.coreutils}/bin/date +%s)
      echo "btrbk_last_run_seconds_ago $(( now - latest ))"
    } > "$TMP"

    mv "$TMP" "$OUT"
  '';

  # Samba connection metrics collector
  sambaCollector = pkgs.writeShellScript "textfile-samba" ''
    OUT="${textfileDir}/samba.prom"
    TMP="$OUT.$$"

    connections=$(${pkgs.samba}/bin/smbstatus -b 2>/dev/null \
      | ${pkgs.gnugrep}/bin/grep -c "^[0-9]" || true)
    connections=''${connections:-0}
    echo "samba_connections_active $connections" > "$TMP"

    mv "$TMP" "$OUT"
  '';

  # Jellyfin session metrics collector
  jellyfinCollector = pkgs.writeShellScript "textfile-jellyfin" ''
    OUT="${textfileDir}/jellyfin.prom"
    TMP="$OUT.$$"

    JELLYFIN_URL="http://localhost:8096"
    API_KEY_FILE="/var/lib/jellyfin-exporter/api-key"

    if [ ! -f "$API_KEY_FILE" ]; then
      exit 0
    fi

    API_KEY=$(cat "$API_KEY_FILE")

    {
      # Active sessions
      sessions=$(${pkgs.curl}/bin/curl -sf \
        "$JELLYFIN_URL/Sessions?api_key=$API_KEY" 2>/dev/null \
        | ${pkgs.python3}/bin/python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null \
        || echo 0)
      echo "jellyfin_active_sessions $sessions"

      # Playing sessions
      playing=$(${pkgs.curl}/bin/curl -sf \
        "$JELLYFIN_URL/Sessions?api_key=$API_KEY" 2>/dev/null \
        | ${pkgs.python3}/bin/python3 -c "
import sys, json
sessions = json.load(sys.stdin)
print(sum(1 for s in sessions if s.get('NowPlayingItem')))" 2>/dev/null \
        || echo 0)
      echo "jellyfin_playing_sessions $playing"
    } > "$TMP"

    mv "$TMP" "$OUT"
  '';
in
{
  # ── Node Exporter ─────────────────────────────────────────────────
  services.prometheus.exporters.node = {
    enable = true;
    port = 9101;  # 9100 is used by devel-agent orchestrator
    enabledCollectors = [
      "systemd"
      "processes"
    ];
    extraFlags = [
      "--collector.textfile.directory=${textfileDir}"
    ];
  };

  # Open firewall so Docker containers can scrape node-exporter
  networking.firewall.allowedTCPPorts = [ 9101 ];

  # ── Textfile collector directory ──────────────────────────────────
  systemd.tmpfiles.rules = [
    "d ${textfileDir} 0755 root root -"
    "d /var/lib/jellyfin-exporter 0700 root root -"
  ];

  # ── btrbk metrics (runs after each btrbk snapshot) ───────────────
  systemd.services.textfile-btrbk = {
    description = "Export btrbk snapshot metrics for node-exporter";
    after = [ "btrbk-default.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = btrbkCollector;
    };
  };

  systemd.timers.textfile-btrbk = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      RandomizedDelaySec = "5m";
      Persistent = true;
    };
  };

  # ── Samba metrics (every 30s) ─────────────────────────────────────
  systemd.services.textfile-samba = {
    description = "Export Samba connection metrics for node-exporter";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = sambaCollector;
    };
  };

  systemd.timers.textfile-samba = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:*:00,30";
      Persistent = true;
    };
  };

  # ── Jellyfin metrics (every 30s) ─────────────────────────────────
  systemd.services.textfile-jellyfin = {
    description = "Export Jellyfin session metrics for node-exporter";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = jellyfinCollector;
    };
  };

  systemd.timers.textfile-jellyfin = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:*:00,30";
      Persistent = true;
    };
  };
}
