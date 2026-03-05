export const colors = {
  base: "#1a0a1f",
  mantle: "#2d1438",
  crust: "#120818",
  surface0: "#3f1e50",
  surface1: "#6b4580",
  surface2: "#8a5090",
  overlay0: "#6b4580",
  text: "#a0e8c0",
  subtext0: "#80c8a0",
  subtext1: "#c0f0d8",
  blue: "#9070d0",
  green: "#50c878",
  yellow: "#e8c040",
  red: "#e03050",
  peach: "#e87030",
  mauve: "#c050a0",
  teal: "#40c0c0",
  lavender: "#9070d0",
  sky: "#40c0c0",
}

export const icons = {
  thermometer: "\u{F050F}",
  cpu: "\u{F2DB}",
  gpu: "\u{F08AE}",
  memory: "\u{F035B}",
  disk: "\u{F02CA}",
  network: "\u{F0200}",
}

export function thresholdClass(value: number, warn: number, crit: number): string {
  if (value >= crit) return "critical"
  if (value >= warn) return "warning"
  return "normal"
}
