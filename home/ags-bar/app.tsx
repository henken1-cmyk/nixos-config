import app from "ags/gtk4/app"
import style from "./style.css"
import Bar from "./widgets/Bar"
import { MonitorPopup } from "./widgets/Prometheus"

app.start({
  css: style,
  main() {
    Bar()
    MonitorPopup()
  },
})
