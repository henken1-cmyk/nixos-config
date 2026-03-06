import { createState } from "ags"
import { interval } from "ags/time"
import app from "ags/gtk4/app"
import Gtk from "gi://Gtk?version=4.0"
import Astal from "gi://Astal?version=4.0"
import Gtk4LayerShell from "gi://Gtk4LayerShell?version=1.0"
import { queryRange, TimeSeries } from "../lib/prometheus"
import Sparkline from "./sparkline"

const REMOTE_PROM = "http://100.71.144.104:9090"
const RANGE_MIN = 30
const STEP_SEC = 60

interface ChartDef {
  label: string
  unit: string
  expr: string
  url?: string
}

const localCharts: ChartDef[] = [
  { label: "CPU Temp", unit: "°C", expr: 'avg(node_hwmon_temp_celsius{chip=~".*coretemp.*"})' },
  { label: "CPU Load", unit: "%", expr: '100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100)' },
  { label: "GPU Temp", unit: "°C", expr: 'node_hwmon_temp_celsius{chip="platform_thinkpad_hwmon",sensor="temp2"}' },
  { label: "RAM", unit: "%", expr: "(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100" },
  { label: "NVMe", unit: "°C", expr: 'node_hwmon_temp_celsius{chip=~".*nvme.*"}' },
  { label: "Network", unit: " B/s", expr: 'sum(rate(node_network_receive_bytes_total{device!="lo"}[1m]))' },
]

const remoteCharts: ChartDef[] = [
  { label: "CPU Temp", unit: "°C", expr: 'hw_cpu_temperature_celsius{sensor=~".*Tctl.*"}', url: REMOTE_PROM },
  { label: "CPU Load", unit: "%", expr: "hw_cpu_load_percent", url: REMOTE_PROM },
  { label: "GPU Temp", unit: "°C", expr: 'hw_gpu_temperature_celsius{sensor="core"}', url: REMOTE_PROM },
  { label: "GPU Load", unit: "%", expr: 'hw_gpu_load_percent{type="3d"}', url: REMOTE_PROM },
  { label: "RAM", unit: "%", expr: "hw_memory_load_percent", url: REMOTE_PROM },
  { label: "NVMe", unit: "°C", expr: 'hw_storage_temperature_celsius{disk=~".*Kingston.*"}', url: REMOTE_PROM },
]

function ChartSection({ title, charts }: { title: string; charts: ChartDef[] }) {
  const states = charts.map(() => createState<TimeSeries>([]))

  async function poll() {
    await Promise.all(
      charts.map(async (c, i) => {
        const data = await queryRange(c.expr, RANGE_MIN, STEP_SEC, c.url)
        states[i][1](data)
      }),
    )
  }

  poll()
  interval(30000, poll)

  return (
    <box cssClasses={["history-section"]} orientation={Gtk.Orientation.VERTICAL}>
      <label cssClasses={["panel-title"]} label={title} />
      <box cssClasses={["history-grid"]} orientation={Gtk.Orientation.VERTICAL}>
        {/* 2 charts per row */}
        {Array.from({ length: Math.ceil(charts.length / 2) }, (_, row) => (
          <box cssClasses={["history-row"]}>
            <Sparkline
              label={charts[row * 2].label}
              unit={charts[row * 2].unit}
              data={states[row * 2][0]}
            />
            {row * 2 + 1 < charts.length && (
              <Sparkline
                label={charts[row * 2 + 1].label}
                unit={charts[row * 2 + 1].unit}
                data={states[row * 2 + 1][0]}
              />
            )}
          </box>
        ))}
      </box>
    </box>
  )
}

export default function HistoryPanel() {
  return (
    <window
      namespace="history-panel"
      name="history-panel"
      exclusivity={Astal.Exclusivity.IGNORE}
      anchor={Astal.WindowAnchor.RIGHT | Astal.WindowAnchor.TOP}
      marginRight={16}
      marginTop={16}
      application={app}
      $={(self) => {
        Gtk4LayerShell.set_layer(self, Gtk4LayerShell.Layer.BOTTOM)
        self.visible = true
      }}
    >
      <box cssClasses={["monitor-panel", "history-panel-box"]} orientation={Gtk.Orientation.HORIZONTAL}>
        <ChartSection title="Laptop — 30 min" charts={localCharts} />
        <ChartSection title="Desktop — 30 min" charts={remoteCharts} />
      </box>
    </window>
  )
}
