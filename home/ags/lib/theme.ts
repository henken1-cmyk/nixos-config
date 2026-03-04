export const colors = {
  base: "#1e1e2e",
  mantle: "#181825",
  crust: "#11111b",
  surface0: "#313244",
  surface1: "#45475a",
  surface2: "#585b70",
  overlay0: "#6c7086",
  text: "#cdd6f4",
  subtext0: "#a6adc8",
  subtext1: "#bac2de",
  blue: "#89b4fa",
  green: "#a6e3a1",
  yellow: "#f9e2af",
  red: "#f38ba8",
  peach: "#fab387",
  mauve: "#cba6f7",
  teal: "#94e2d5",
  lavender: "#b4befe",
  sky: "#89dceb",
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
