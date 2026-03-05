import { createState, createComputed } from "ags"
import { interval } from "ags/time"
import app from "ags/gtk4/app"
import Gtk from "gi://Gtk?version=4.0"
import Astal from "gi://Astal?version=4.0"
import Gtk4LayerShell from "gi://Gtk4LayerShell?version=1.0"
import { queryInstant } from "../lib/prometheus"
import { icons, thresholdClass } from "../lib/theme"
import MonitorCard from "./monitor-card"

const REMOTE_PROM = "http://100.71.144.104:9090"

interface Metric {
  display: string
  value: number
}

const INITIAL: Metric = { display: "\u2013", value: 0 }

export default function RemoteMonitorPanel() {
  const [cpuTemp, setCpuTemp] = createState<Metric>(INITIAL)
  const [cpuLoad, setCpuLoad] = createState<Metric>(INITIAL)
  const [gpuTemp, setGpuTemp] = createState<Metric>(INITIAL)
  const [gpuLoad, setGpuLoad] = createState<Metric>(INITIAL)
  const [ram, setRam] = createState<Metric>(INITIAL)
  const [nvme, setNvme] = createState<Metric>(INITIAL)

  async function poll() {
    const cpuTempVal = await queryInstant(
      'hw_cpu_temperature_celsius{sensor=~".*Tctl.*"}', REMOTE_PROM
    )
    if (cpuTempVal) {
      const v = Math.round(parseFloat(cpuTempVal))
      setCpuTemp({ display: `${v}\u00B0C`, value: v })
    }

    const cpuLoadVal = await queryInstant(
      'hw_cpu_load_percent', REMOTE_PROM
    )
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

    const ramVal = await queryInstant(
      'hw_memory_load_percent', REMOTE_PROM
    )
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
    <window
      namespace="remote-monitor-widgets"
      name="remote-monitor-widgets"
      exclusivity={Astal.Exclusivity.IGNORE}
      anchor={Astal.WindowAnchor.LEFT | Astal.WindowAnchor.BOTTOM}
      marginLeft={16}
      marginBottom={16}
      application={app}
      $={(self) => {
        Gtk4LayerShell.set_layer(self, Gtk4LayerShell.Layer.BOTTOM)
        self.visible = true
      }}
    >
      <box cssClasses={["monitor-panel"]} orientation={Gtk.Orientation.VERTICAL}>
        <label cssClasses={["panel-title"]} label="Desktop" />
        <box cssClasses={["monitor-row"]}>
          <MonitorCard
            icon={icons.thermometer}
            title="CPU Temp"
            value={createComputed(() => cpuTemp().display)}
            statusClass={createComputed(() => thresholdClass(cpuTemp().value, 70, 90))}
          />
          <MonitorCard
            icon={icons.cpu}
            title="CPU Load"
            value={createComputed(() => cpuLoad().display)}
            statusClass={createComputed(() => thresholdClass(cpuLoad().value, 70, 90))}
          />
        </box>
        <box cssClasses={["monitor-row"]}>
          <MonitorCard
            icon={icons.gpu}
            title="GPU Temp"
            value={createComputed(() => gpuTemp().display)}
            statusClass={createComputed(() => thresholdClass(gpuTemp().value, 75, 95))}
          />
          <MonitorCard
            icon={icons.gpu}
            title="GPU Load"
            value={createComputed(() => gpuLoad().display)}
            statusClass={createComputed(() => thresholdClass(gpuLoad().value, 70, 90))}
          />
        </box>
        <box cssClasses={["monitor-row"]}>
          <MonitorCard
            icon={icons.memory}
            title="RAM"
            value={createComputed(() => ram().display)}
            statusClass={createComputed(() => thresholdClass(ram().value, 70, 90))}
          />
          <MonitorCard
            icon={icons.disk}
            title="NVMe"
            value={createComputed(() => nvme().display)}
            statusClass={createComputed(() => thresholdClass(nvme().value, 55, 70))}
          />
        </box>
      </box>
    </window>
  )
}
