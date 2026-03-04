import app from "ags/gtk4/app"
import style from "./style.css"
import MonitorPanel from "./widgets/monitor-panel"

app.start({
  css: style,
  main() {
    return <MonitorPanel />
  },
})
