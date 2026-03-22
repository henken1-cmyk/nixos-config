import { createBinding, For } from "ags"
import Tray from "gi://AstalTray"

export default function SysTray() {
  const tray = Tray.get_default()
  const items = createBinding(tray, "items")

  return (
    <box cssClasses={["systray"]}>
      <For each={items} id={item => item.itemId}>
        {(item) => (
          <menubutton
            cssClasses={["tray-item"]}
            tooltipMarkup={createBinding(item, "tooltipMarkup")}
            actionGroup={createBinding(item, "actionGroup").as(ag => ["dbusmenu", ag])}
            menuModel={createBinding(item, "menuModel")}
          >
            <image gicon={createBinding(item, "gicon")} pixelSize={16} />
          </menubutton>
        )}
      </For>
    </box>
  )
}
