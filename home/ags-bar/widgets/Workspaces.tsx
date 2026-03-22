import { createBinding, createComputed, For } from "ags"
import Hyprland from "gi://AstalHyprland"

export default function Workspaces() {
  const hyprland = Hyprland.get_default()
  const workspaces = createBinding(hyprland, "workspaces")
  const focused = createBinding(hyprland, "focusedWorkspace")

  const sorted = createComputed(() =>
    [...workspaces()].filter(ws => ws.id > 0).sort((a, b) => a.id - b.id)
  )

  return (
    <box cssClasses={["workspaces"]}>
      <For each={sorted} id={ws => ws.id}>
        {(ws) => (
          <button
            cssClasses={createComputed(() =>
              ["workspace-btn", ...(focused()?.id === ws.id ? ["active"] : [])]
            )}
            onClicked={() => ws.focus()}
          >
            <label label={`${ws.id}`} />
          </button>
        )}
      </For>
    </box>
  )
}
