import app from "ags/gtk4/app"
import style from "./style.css"
import MonitorPanel from "./widgets/monitor-panel"
import HistoryPanel from "./widgets/history-panel"

app.start({
  css: style,
  main() {
    return (
      <>
        <MonitorPanel />
        <HistoryPanel />
      </>
    )
  },
})
