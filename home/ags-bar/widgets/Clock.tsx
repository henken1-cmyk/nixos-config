import { createState } from "ags"
import { interval } from "ags/time"
import Gtk from "gi://Gtk?version=4.0"

function formatTime(): string {
  const now = new Date()
  return now.toLocaleTimeString("pl-PL", { hour: "2-digit", minute: "2-digit" })
}

function formatDate(): string {
  const now = new Date()
  return now.toLocaleDateString("pl-PL", { weekday: "short", day: "numeric", month: "short" })
}

export default function Clock() {
  const [time, setTime] = createState(formatTime())
  const [date, setDate] = createState(formatDate())

  interval(1000, () => {
    setTime(formatTime())
    setDate(formatDate())
  })

  return (
    <box cssClasses={["clock"]}>
      <box orientation={Gtk.Orientation.VERTICAL}>
        <label cssClasses={["clock-time"]} label={time} />
        <label cssClasses={["clock-date"]} label={date} />
      </box>
    </box>
  )
}
