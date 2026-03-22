import { createBinding } from "ags"
import Hyprland from "gi://AstalHyprland"

export default function WindowTitle() {
  const hyprland = Hyprland.get_default()
  const title = createBinding(hyprland, "focusedClient", "title")

  return (
    <box cssClasses={["window-title"]}>
      <label
        label={title.as(t => t ?? "")}
        maxWidthChars={40}
        ellipsize={3}
      />
    </box>
  )
}
