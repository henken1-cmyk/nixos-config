import { createState, createComputed } from "ags"
import { interval } from "ags/time"
import app from "ags/gtk4/app"
import Gtk from "gi://Gtk?version=4.0"
import Astal from "gi://Astal?version=4.0"
import Gtk4LayerShell from "gi://Gtk4LayerShell?version=1.0"
import { queryInstant, checkConnection } from "../lib/prometheus"
import { icons, thresholdClass } from "../lib/theme"
import MonitorCard from "./monitor-card"
import HistoryContent from "./history-panel"

interface Metric {
  display: string
  value: number
}

const INITIAL: Metric = { display: "\u2013", value: 0 }
const REMOTE_PROM = "http://100.71.144.104:9090"

function formatBytes(bytes: number): string {
  if (bytes >= 1048576) return `${(bytes / 1048576).toFixed(1)} MB/s`
  if (bytes >= 1024) return `${(bytes / 1024).toFixed(0)} KB/s`
  return `${Math.round(bytes)} B/s`
}

function LocalMetrics() {
  const [cpuTemp, setCpuTemp] = createState<Metric>(INITIAL)
  const [cpuLoad, setCpuLoad] = createState<Metric>(INITIAL)
  const [gpuTemp, setGpuTemp] = createState<Metric>(INITIAL)
  const [ram, setRam] = createState<Metric>(INITIAL)
  const [nvme, setNvme] = createState<Metric>(INITIAL)
  const [net, setNet] = createState<Metric>({ display: "\u2013", value: -1 })

  async function poll() {
    const cpuTempVal = await queryInstant(
      'avg(node_hwmon_temp_celsius{chip=~".*coretemp.*"})'
    )
    if (cpuTempVal) {
      const v = Math.round(parseFloat(cpuTempVal))
      setCpuTemp({ display: `${v}\u00B0C`, value: v })
    }

    const cpuLoadVal = await queryInstant(
      '100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100)'
    )
    if (cpuLoadVal) {
      const v = Math.round(parseFloat(cpuLoadVal))
      setCpuLoad({ display: `${v}%`, value: v })
    }

    const gpuTempVal = await queryInstant(
      'node_hwmon_temp_celsius{chip="platform_thinkpad_hwmon",sensor="temp2"}'
    )
    if (gpuTempVal) {
      const v = Math.round(parseFloat(gpuTempVal))
      setGpuTemp({ display: `${v}\u00B0C`, value: v })
    }

    const ramVal = await queryInstant(
      "(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100"
    )
    if (ramVal) {
      const v = Math.round(parseFloat(ramVal))
      setRam({ display: `${v}%`, value: v })
    }

    const nvmeVal = await queryInstant(
      'node_hwmon_temp_celsius{chip=~".*nvme.*"}'
    )
    if (nvmeVal) {
      const v = Math.round(parseFloat(nvmeVal))
      setNvme({ display: `${v}\u00B0C`, value: v })
    }

    const netVal = await queryInstant(
      'sum(rate(node_network_receive_bytes_total{device!="lo"}[1m]))'
    )
    if (netVal) {
      const bytes = parseFloat(netVal)
      setNet({ display: formatBytes(bytes), value: bytes })
    }
  }

  poll()
  interval(5000, poll)

  return (
    <box cssClasses={["monitor-section"]} orientation={Gtk.Orientation.VERTICAL}>
      <label cssClasses={["panel-title"]} label="Laptop" />
      <box cssClasses={["monitor-row"]}>
        <MonitorCard
          icon={icons.thermometer} title="CPU Temp"
          value={createComputed(() => cpuTemp().display)}
          statusClass={createComputed(() => thresholdClass(cpuTemp().value, 70, 90))}
        />
        <MonitorCard
          icon={icons.cpu} title="CPU Load"
          value={createComputed(() => cpuLoad().display)}
          statusClass={createComputed(() => thresholdClass(cpuLoad().value, 70, 90))}
        />
      </box>
      <box cssClasses={["monitor-row"]}>
        <MonitorCard
          icon={icons.gpu} title="GPU Temp"
          value={createComputed(() => gpuTemp().display)}
          statusClass={createComputed(() => thresholdClass(gpuTemp().value, 75, 95))}
        />
        <MonitorCard
          icon={icons.memory} title="RAM"
          value={createComputed(() => ram().display)}
          statusClass={createComputed(() => thresholdClass(ram().value, 70, 90))}
        />
      </box>
      <box cssClasses={["monitor-row"]}>
        <MonitorCard
          icon={icons.disk} title="NVMe"
          value={createComputed(() => nvme().display)}
          statusClass={createComputed(() => thresholdClass(nvme().value, 55, 70))}
        />
        <MonitorCard
          icon={icons.network} title="Network"
          value={createComputed(() => net().display)}
          statusClass={createComputed(() => "normal")}
        />
      </box>
    </box>
  )
}

function RemoteMetrics() {
  const [cpuTemp, setCpuTemp] = createState<Metric>(INITIAL)
  const [cpuLoad, setCpuLoad] = createState<Metric>(INITIAL)
  const [gpuTemp, setGpuTemp] = createState<Metric>(INITIAL)
  const [gpuLoad, setGpuLoad] = createState<Metric>(INITIAL)
  const [ram, setRam] = createState<Metric>(INITIAL)
  const [nvme, setNvme] = createState<Metric>(INITIAL)
  const [online, setOnline] = createState(false)

  async function poll() {
    const connected = await checkConnection(REMOTE_PROM)
    setOnline(connected)
    if (!connected) return

    const cpuTempVal = await queryInstant(
      'hw_cpu_temperature_celsius{sensor=~".*Tctl.*"}', REMOTE_PROM
    )
    if (cpuTempVal) {
      const v = Math.round(parseFloat(cpuTempVal))
      setCpuTemp({ display: `${v}\u00B0C`, value: v })
    }

    const cpuLoadVal = await queryInstant('hw_cpu_load_percent', REMOTE_PROM)
    if (cpuLoadVal) {
      const v = Math.round(parseFloat(cpuLoadVal))
      setCpuLoad({ display: `${v}%`, value: v })
    }

    const gpuTempVal = await queryInstant(
      'hw_gpu_temperature_celsius{sensor="core"}', REMOTE_PROM
    )
    if (gpuTempVal) {
      const v = Math.round(parseFloat(gpuTempVal))
      setGpuTemp({ display: `${v}\u00B0C`, value: v })
    }

    const gpuLoadVal = await queryInstant(
      'hw_gpu_load_percent{type="3d"}', REMOTE_PROM
    )
    if (gpuLoadVal) {
      const v = Math.round(parseFloat(gpuLoadVal))
      setGpuLoad({ display: `${v}%`, value: v })
    }

    const ramVal = await queryInstant('hw_memory_load_percent', REMOTE_PROM)
    if (ramVal) {
      const v = Math.round(parseFloat(ramVal))
      setRam({ display: `${v}%`, value: v })
    }

    const nvmeVal = await queryInstant(
      'hw_storage_temperature_celsius{disk=~".*Kingston.*"}', REMOTE_PROM
    )
    if (nvmeVal) {
      const v = Math.round(parseFloat(nvmeVal))
      setNvme({ display: `${v}\u00B0C`, value: v })
    }
  }

  poll()
  interval(5000, poll)

  return (
    <box cssClasses={["monitor-section"]} orientation={Gtk.Orientation.VERTICAL}>
      <box cssClasses={["section-header"]}>
        <label cssClasses={["panel-title"]} label="Desktop" />
        <label
          cssClasses={createComputed(() => ["status-dot", online() ? "online" : "offline"])}
          label={createComputed(() => online() ? "\u25CF" : "\u25CF")}
        />
      </box>
      <box cssClasses={["monitor-row"]}>
        <MonitorCard
          icon={icons.thermometer} title="CPU Temp"
          value={createComputed(() => cpuTemp().display)}
          statusClass={createComputed(() => thresholdClass(cpuTemp().value, 70, 90))}
        />
        <MonitorCard
          icon={icons.cpu} title="CPU Load"
          value={createComputed(() => cpuLoad().display)}
          statusClass={createComputed(() => thresholdClass(cpuLoad().value, 70, 90))}
        />
      </box>
      <box cssClasses={["monitor-row"]}>
        <MonitorCard
          icon={icons.gpu} title="GPU Temp"
          value={createComputed(() => gpuTemp().display)}
          statusClass={createComputed(() => thresholdClass(gpuTemp().value, 75, 95))}
        />
        <MonitorCard
          icon={icons.gpu} title="GPU Load"
          value={createComputed(() => gpuLoad().display)}
          statusClass={createComputed(() => thresholdClass(gpuLoad().value, 70, 90))}
        />
      </box>
      <box cssClasses={["monitor-row"]}>
        <MonitorCard
          icon={icons.memory} title="RAM"
          value={createComputed(() => ram().display)}
          statusClass={createComputed(() => thresholdClass(ram().value, 70, 90))}
        />
        <MonitorCard
          icon={icons.disk} title="NVMe"
          value={createComputed(() => nvme().display)}
          statusClass={createComputed(() => thresholdClass(nvme().value, 55, 70))}
        />
      </box>
    </box>
  )
}

export default function MonitorPanel() {
  return (
    <window
      namespace="monitor-widgets"
      name="monitor-widgets"
      exclusivity={Astal.Exclusivity.IGNORE}
      anchor={Astal.WindowAnchor.RIGHT | Astal.WindowAnchor.BOTTOM}
      marginRight={16}
      marginBottom={16}
      application={app}
      $={(self) => {
        Gtk4LayerShell.set_layer(self, Gtk4LayerShell.Layer.BOTTOM)
        self.visible = true
      }}
    >
      <box cssClasses={["monitor-panel"]} orientation={Gtk.Orientation.VERTICAL}>
        <HistoryContent />
        <box cssClasses={["panel-divider"]} />
        <box orientation={Gtk.Orientation.HORIZONTAL}>
          <LocalMetrics />
          <RemoteMetrics />
        </box>
      </box>
    </window>
  )
}
