import { Accessor, createComputed } from "ags"
import Gtk from "gi://Gtk?version=4.0"

export default function MonitorCard({ icon, title, value, statusClass }: {
  icon: string
  title: string
  value: Accessor<string>
  statusClass: Accessor<string>
}) {
  return (
    <box cssClasses={["monitor-card"]} orientation={Gtk.Orientation.VERTICAL}>
      <label cssClasses={["card-icon"]} label={icon} />
      <label cssClasses={["card-title"]} label={title} />
      <label
        cssClasses={createComputed(() => ["card-value", statusClass()])}
        label={value}
      />
    </box>
  )
}
