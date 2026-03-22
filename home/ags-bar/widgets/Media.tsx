import { createBinding, createComputed } from "ags"
import Mpris from "gi://AstalMpris"

export default function Media() {
  const mpris = Mpris.get_default()
  const players = createBinding(mpris, "players")

  return (
    <box cssClasses={["media"]}>
      {createComputed(() => {
        const p = players()
        const player = p[0]
        if (!player) return <box />

        const status = createBinding(player, "playbackStatus")
        const title = createBinding(player, "title")
        const artist = createBinding(player, "artist")

        return (
          <box cssClasses={["media-player"]}>
            <button cssClasses={["media-btn"]} onClicked={() => player.previous()}>
              <label label="󰒮" />
            </button>
            <button cssClasses={["media-btn"]} onClicked={() => player.play_pause()}>
              <label label={status.as(s =>
                s === Mpris.PlaybackStatus.PLAYING ? "󰏤" : "󰐊"
              )} />
            </button>
            <button cssClasses={["media-btn"]} onClicked={() => player.next()}>
              <label label="󰒭" />
            </button>
            <label
              cssClasses={["media-title"]}
              label={createComputed(() => {
                const t = title() ?? ""
                const a = artist() ?? ""
                return a ? `${a} \u2014 ${t}` : t
              })}
              maxWidthChars={40}
              ellipsize={3}
            />
          </box>
        )
      })}
    </box>
  )
}
