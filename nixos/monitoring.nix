{ config, pkgs, ... }:

let
  prometheusConfig = pkgs.writeText "prometheus.yml" ''
    global:
      scrape_interval: 5s

    scrape_configs:
      - job_name: 'node'
        static_configs:
          - targets: ['host.docker.internal:9100']
  '';

  grafanaDatasource = pkgs.writeText "datasource.yml" ''
    apiVersion: 1
    datasources:
      - name: Prometheus
        type: prometheus
        access: proxy
        url: http://prometheus:9090
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

  # ── Docker network for monitoring stack ─────────────────────────
  systemd.services.docker-network-monitoring = {
    description = "Create Docker network for monitoring";
    after = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.docker}/bin/docker network inspect monitoring >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker network create monitoring
    '';
  };

  # ── Prometheus container ────────────────────────────────────────
  virtualisation.oci-containers.backend = "docker";

  virtualisation.oci-containers.containers.prometheus = {
    image = "prom/prometheus:latest";
    ports = [ "127.0.0.1:9090:9090" ];
    volumes = [
      "${prometheusConfig}:/etc/prometheus/prometheus.yml:ro"
      "prometheus-data:/prometheus"
    ];
    cmd = [
      "--config.file=/etc/prometheus/prometheus.yml"
      "--storage.tsdb.path=/prometheus"
    ];
    extraOptions = [
      "--add-host=host.docker.internal:host-gateway"
      "--network=monitoring"
    ];
  };

  # ── Grafana container ──────────────────────────────────────────
  virtualisation.oci-containers.containers.grafana = {
    image = "grafana/grafana:latest";
    ports = [ "127.0.0.1:3000:3000" ];
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
    extraOptions = [
      "--network=monitoring"
    ];
  };

  # ── Ensure containers start after network is created ───────────
  systemd.services.docker-prometheus.after = [ "docker-network-monitoring.service" ];
  systemd.services.docker-prometheus.requires = [ "docker-network-monitoring.service" ];
  systemd.services.docker-grafana.after = [ "docker-network-monitoring.service" ];
  systemd.services.docker-grafana.requires = [ "docker-network-monitoring.service" ];
}
