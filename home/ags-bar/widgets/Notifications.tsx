import { createBinding, createComputed } from "ags"
import Notifd from "gi://AstalNotifd"

export default function Notifications() {
  const notifd = Notifd.get_default()
  const notifications = createBinding(notifd, "notifications")

  return (
    <box cssClasses={["notifications"]}>
      <button
        cssClasses={["bar-btn"]}
        onClicked={() => {
          notifd.dontDisturb = !notifd.dontDisturb
        }}
        tooltipText={notifications.as(n =>
          n.length > 0 ? `${n.length} notification${n.length > 1 ? "s" : ""}` : "No notifications"
        )}
      >
        <label
          cssClasses={["bar-icon"]}
          label={notifications.as(n => n.length > 0 ? "󱅫" : "󰂚")}
        />
        {createComputed(() => {
          const n = notifications()
          return n.length > 0
            ? <label cssClasses={["notif-count"]} label={`${n.length}`} />
            : <box />
        })}
      </button>
    </box>
  )
}
