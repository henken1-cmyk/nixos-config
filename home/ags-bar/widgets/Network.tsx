import { createBinding, createComputed } from "ags"
import Network from "gi://AstalNetwork"

export default function NetworkWidget() {
  const network = Network.get_default()
  const primary = createBinding(network, "primary")

  return (
    <box cssClasses={["network"]}>
      {createComputed(() => {
        const p = primary()

        if (p === Network.Primary.WIFI && network.wifi) {
          const strength = createBinding(network.wifi, "strength")
          const ssid = createBinding(network.wifi, "ssid")

          return (
            <button cssClasses={["bar-btn"]} tooltipText={ssid}>
              <label
                cssClasses={["bar-icon"]}
                label={strength.as(s =>
                  s > 75 ? "󰤨" : s > 50 ? "󰤥" : s > 25 ? "󰤢" : "󰤟"
                )}
              />
            </button>
          )
        }

        if (p === Network.Primary.WIRED) {
          return (
            <button cssClasses={["bar-btn"]} tooltipText="Ethernet">
              <label cssClasses={["bar-icon"]} label="󰈀" />
            </button>
          )
        }

        return (
          <button cssClasses={["bar-btn"]} tooltipText="Disconnected">
            <label cssClasses={["bar-icon", "warning"]} label="󰤭" />
          </button>
        )
      })}
    </box>
  )
}
