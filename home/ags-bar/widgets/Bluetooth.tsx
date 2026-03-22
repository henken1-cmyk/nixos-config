import { createBinding, createComputed } from "ags"
import Bluetooth from "gi://AstalBluetooth"

export default function BluetoothWidget() {
  const bluetooth = Bluetooth.get_default()
  const isPowered = createBinding(bluetooth, "isPowered")
  const isConnected = createBinding(bluetooth, "isConnected")

  return (
    <box cssClasses={["bluetooth"]}>
      <button
        cssClasses={["bar-btn"]}
        tooltipText={isConnected.as(c =>
          c ? "Bluetooth: Connected" : "Bluetooth"
        )}
      >
        <label
          cssClasses={isPowered.as(p =>
            ["bar-icon", ...(p ? [] : ["dim"])]
          )}
          label={isConnected.as(c => c ? "󰂯" : "󰂲")}
        />
      </button>
    </box>
  )
}
