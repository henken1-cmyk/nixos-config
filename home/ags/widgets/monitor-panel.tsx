import { createState } from "ags"
import { interval } from "ags/time"
import app from "ags/gtk4/app"
import Astal from "gi://Astal?version=4.0"
import { queryInstant } from "../lib/prometheus"
import { icons, thresholdClass } from "../lib/theme"
import MonitorCard from "./monitor-card"

interface Metric {
  display: string
  value: number
}

const INITIAL: Metric = { display: "\u2013", value: 0 }

function formatBytes(bytes: number): string {
  if (bytes >= 1048576) return `${(bytes / 1048576).toFixed(1)} MB/s`
  if (bytes >= 1024) return `${(bytes / 1024).toFixed(0)} KB/s`
  return `${Math.round(bytes)} B/s`
}

export default function MonitorPanel() {
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
      'node_hwmon_temp_celsius{chip=~".*nvidia.*"}'
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
    <window
      visible
      namespace="monitor-widgets"
      name="monitor-widgets"
      layer={Astal.Layer.TOP}
      exclusivity={Astal.Exclusivity.IGNORE}
      anchor={Astal.WindowAnchor.RIGHT | Astal.WindowAnchor.BOTTOM}
      marginRight={16}
      marginBottom={16}
      application={app}
    >
      <box cssClasses={["monitor-panel"]} vertical>
        <box cssClasses={["monitor-row"]}>
          <MonitorCard
            icon={icons.thermometer}
            title="CPU Temp"
            value={() => cpuTemp().display}
            statusClass={() => thresholdClass(cpuTemp().value, 70, 90)}
          />
          <MonitorCard
            icon={icons.cpu}
            title="CPU Load"
            value={() => cpuLoad().display}
            statusClass={() => thresholdClass(cpuLoad().value, 70, 90)}
          />
        </box>
        <box cssClasses={["monitor-row"]}>
          <MonitorCard
            icon={icons.gpu}
            title="GPU Temp"
            value={() => gpuTemp().display}
            statusClass={() => thresholdClass(gpuTemp().value, 75, 95)}
          />
          <MonitorCard
            icon={icons.memory}
            title="RAM"
            value={() => ram().display}
            statusClass={() => thresholdClass(ram().value, 70, 90)}
          />
        </box>
        <box cssClasses={["monitor-row"]}>
          <MonitorCard
            icon={icons.disk}
            title="NVMe"
            value={() => nvme().display}
            statusClass={() => thresholdClass(nvme().value, 55, 70)}
          />
          <MonitorCard
            icon={icons.network}
            title="Network"
            value={() => net().display}
            statusClass={() => "normal"}
          />
        </box>
      </box>
    </window>
  )
}
