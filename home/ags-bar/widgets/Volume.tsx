import { createBinding, createComputed } from "ags"
import Gtk from "gi://Gtk?version=4.0"
import Wp from "gi://AstalWp"

function volumeIcon(volume: number, mute: boolean): string {
  if (mute) return "󰝟"
  if (volume > 0.66) return "󰕾"
  if (volume > 0.33) return "󰖀"
  return "󰕿"
}

export default function Volume() {
  const wp = Wp.get_default()!
  const speaker = wp.audio.defaultSpeaker!

  const vol = createBinding(speaker, "volume")
  const mute = createBinding(speaker, "mute")

  return (
    <box cssClasses={["volume"]}>
      <button
        cssClasses={["bar-btn"]}
        onClicked={() => { speaker.mute = !speaker.mute }}
        tooltipText={vol.as(v => `Volume: ${Math.round(v * 100)}%`)}
        $={(self) => {
          const scroll = new Gtk.EventControllerScroll(
            Gtk.EventControllerScrollFlags.VERTICAL
          )
          scroll.connect("scroll", (_, _dx, dy) => {
            speaker.volume = Math.min(1.5, Math.max(0, speaker.volume - dy * 0.05))
            return true
          })
          self.add_controller(scroll)
        }}
      >
        <label
          cssClasses={["bar-icon"]}
          label={createComputed(() => volumeIcon(vol(), mute()))}
        />
      </button>
    </box>
  )
}
