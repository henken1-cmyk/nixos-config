import { createBinding, createComputed } from "ags"
import Battery from "gi://AstalBattery"

function batteryIcon(percent: number, charging: boolean): string {
  if (charging) return "󰂄"
  if (percent > 90) return "󰁹"
  if (percent > 70) return "󰂁"
  if (percent > 50) return "󰁾"
  if (percent > 30) return "󰁻"
  if (percent > 10) return "󰁺"
  return "󰂎"
}

export default function BatteryWidget() {
  const battery = Battery.get_default()
  const percentage = createBinding(battery, "percentage")
  const charging = createBinding(battery, "charging")

  return (
    <box cssClasses={["battery"]}>
      <box
        cssClasses={percentage.as(p =>
          ["battery-inner", ...(p <= 0.1 ? ["critical"] : p <= 0.3 ? ["warning"] : [])]
        )}
      >
        <label
          cssClasses={["bar-icon"]}
          label={createComputed(() =>
            batteryIcon(Math.round(percentage() * 100), charging())
          )}
        />
        <label
          cssClasses={["battery-label"]}
          label={percentage.as(p => `${Math.round(p * 100)}%`)}
        />
      </box>
    </box>
  )
}
