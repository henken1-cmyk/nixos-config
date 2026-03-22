{ config, pkgs, lib, ... }:

let
  prometheusConfig = pkgs.writeText "prometheus.yml" ''
    global:
      scrape_interval: 5s

    scrape_configs:
      - job_name: 'node'
        static_configs:
          - targets: ['localhost:9100']
  '';

  grafanaDatasource = pkgs.writeText "datasource.yml" ''
    apiVersion: 1
    datasources:
      - name: Prometheus
        type: prometheus
        access: proxy
        url: http://localhost:9090
        isDefault: true
        uid: prometheus
  '';

  grafanaDashboardProvider = pkgs.writeText "dashboards.yml" ''
    apiVersion: 1
    providers:
      - name: default
        type: file
        allowUiUpdates: true
        options:
          path: /var/lib/grafana/dashboards
  '';

  grafanaDashboard = ./grafana-dashboard.json;
in
{
  # ── Node exporter — native service for host metrics ─────────────
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    enabledCollectors = [
      "cpu"
      "meminfo"
      "diskstats"
      "filesystem"
      "netdev"
      "loadavg"
      "hwmon"
      "thermal_zone"
    ];
  };

  # ── Prometheus container ────────────────────────────────────────
  virtualisation.oci-containers.backend = "docker";

  virtualisation.oci-containers.containers.prometheus = {
    image = "prom/prometheus:latest";
    volumes = [
      "${prometheusConfig}:/etc/prometheus/prometheus.yml:ro"
      "prometheus-data:/prometheus"
    ];
    cmd = [
      "--config.file=/etc/prometheus/prometheus.yml"
      "--storage.tsdb.path=/prometheus"
    ];
    extraOptions = [ "--network=host" "--stop-timeout=1" ];
  };

  # Kill containers immediately on shutdown
  systemd.services.docker-prometheus.serviceConfig.TimeoutStopSec = lib.mkForce "2s";

  # ── Grafana container ──────────────────────────────────────────
  virtualisation.oci-containers.containers.grafana = {
    image = "grafana/grafana:latest";
    environment = {
      GF_SECURITY_ADMIN_PASSWORD = "qweqwe";
    };
    volumes = [
      "grafana-data:/var/lib/grafana"
      "${grafanaDatasource}:/etc/grafana/provisioning/datasources/datasource.yml:ro"
      "${grafanaDashboardProvider}:/etc/grafana/provisioning/dashboards/dashboards.yml:ro"
      "${grafanaDashboard}:/var/lib/grafana/dashboards/hw-monitor.json:ro"
    ];
    dependsOn = [ "prometheus" ];
    extraOptions = [ "--network=host" "--stop-timeout=1" ];
  };

  systemd.services.docker-grafana.serviceConfig.TimeoutStopSec = lib.mkForce "2s";
}
