import Gtk from "gi://Gtk?version=4.0"
import { Accessor } from "ags"
import { colors } from "../lib/theme"
import type { TimeSeries } from "../lib/prometheus"

function hexToRgb(hex: string): [number, number, number] {
  const n = parseInt(hex.slice(1), 16)
  return [(n >> 16) / 255, ((n >> 8) & 0xff) / 255, (n & 0xff) / 255]
}

export default function Sparkline({ data, label, unit }: {
  data: Accessor<TimeSeries>
  label: string
  unit: string
}) {
  const area = new Gtk.DrawingArea({
    widthRequest: 220,
    heightRequest: 80,
  })
  area.add_css_class("sparkline-canvas")

  area.set_draw_func((_widget, cr, width, height) => {
    const points = data()
    if (points.length < 2) {
      const [r, g, b] = hexToRgb(colors.subtext0)
      cr.setSourceRGBA(r, g, b, 0.5)
      cr.selectFontFace("Sans", 0, 0)
      cr.setFontSize(11)
      cr.moveTo(width / 2 - 30, height / 2 + 4)
      cr.showText("No data")
      return
    }

    const values = points.map(([, v]) => v)
    const min = Math.min(...values)
    const max = Math.max(...values)
    const range = max - min || 1
    const pad = 4

    const w = width - pad * 2
    const h = height - pad * 2

    // filled area
    const [lr, lg, lb] = hexToRgb(colors.teal)
    cr.moveTo(pad, pad + h - ((values[0] - min) / range) * h)
    for (let i = 1; i < values.length; i++) {
      const x = pad + (i / (values.length - 1)) * w
      const y = pad + h - ((values[i] - min) / range) * h
      cr.lineTo(x, y)
    }
    cr.lineTo(pad + w, pad + h)
    cr.lineTo(pad, pad + h)
    cr.closePath()
    cr.setSourceRGBA(lr, lg, lb, 0.15)
    cr.fill()

    // line
    cr.moveTo(pad, pad + h - ((values[0] - min) / range) * h)
    for (let i = 1; i < values.length; i++) {
      const x = pad + (i / (values.length - 1)) * w
      const y = pad + h - ((values[i] - min) / range) * h
      cr.lineTo(x, y)
    }
    cr.setSourceRGBA(lr, lg, lb, 0.9)
    cr.setLineWidth(1.5)
    cr.stroke()

    // current value label (top-right)
    const last = values[values.length - 1]
    const [tr, tg, tb] = hexToRgb(colors.text)
    cr.setSourceRGBA(tr, tg, tb, 1)
    cr.selectFontFace("Sans", 0, 1)
    cr.setFontSize(12)
    const valText = `${Math.round(last)}${unit}`
    const ext = cr.textExtents(valText)
    cr.moveTo(width - ext.width - 6, 14)
    cr.showText(valText)

    // min/max (bottom corners)
    const [sr, sg, sb] = hexToRgb(colors.subtext0)
    cr.setSourceRGBA(sr, sg, sb, 0.6)
    cr.selectFontFace("Sans", 0, 0)
    cr.setFontSize(9)
    cr.moveTo(pad + 2, height - 4)
    cr.showText(`${Math.round(min)}${unit}`)
    const maxText = `${Math.round(max)}${unit}`
    const maxExt = cr.textExtents(maxText)
    cr.moveTo(width - maxExt.width - pad - 2, height - 4)
    cr.showText(maxText)
  })

  let prevLen = 0
  const tick = setInterval(() => {
    const d = data()
    if (d.length !== prevLen) {
      prevLen = d.length
      area.queue_draw()
    } else if (d.length > 0) {
      area.queue_draw()
    }
  }, 1000)

  area.connect("destroy", () => clearInterval(tick))

  return (
    <box cssClasses={["sparkline-card"]} orientation={Gtk.Orientation.VERTICAL}>
      <label cssClasses={["sparkline-label"]} label={label} />
      {area}
    </box>
  )
}
