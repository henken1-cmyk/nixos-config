import app from "ags/gtk4/app"
import Gtk from "gi://Gtk?version=4.0"
import Astal from "gi://Astal?version=4.0"
import Workspaces from "./Workspaces"
import WindowTitle from "./WindowTitle"
import Media from "./Media"
import { PrometheusButton } from "./Prometheus"
import Volume from "./Volume"
import BatteryWidget from "./Battery"
import NetworkWidget from "./Network"
import BluetoothWidget from "./Bluetooth"
import SysTray from "./SysTray"
import Notifications from "./Notifications"
import Clock from "./Clock"

function Left() {
  return (
    <box cssClasses={["bar-left"]} halign={Gtk.Align.START}>
      <Workspaces />
      <WindowTitle />
    </box>
  )
}

function Center() {
  return (
    <box cssClasses={["bar-center"]} halign={Gtk.Align.CENTER}>
      <Media />
    </box>
  )
}

function Right() {
  return (
    <box cssClasses={["bar-right"]} halign={Gtk.Align.END}>
      <PrometheusButton />
      <Volume />
      <BatteryWidget />
      <NetworkWidget />
      <BluetoothWidget />
      <SysTray />
      <Notifications />
      <Clock />
    </box>
  )
}

export default function Bar() {
  return (
    <window
      namespace="ags-bar"
      name="ags-bar"
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={
        Astal.WindowAnchor.TOP
        | Astal.WindowAnchor.LEFT
        | Astal.WindowAnchor.RIGHT
      }
      application={app}
      $={(self) => { self.visible = true }}
    >
      <centerbox cssClasses={["bar"]}>
        <Left />
        <Center />
        <Right />
      </centerbox>
    </window>
  )
}
