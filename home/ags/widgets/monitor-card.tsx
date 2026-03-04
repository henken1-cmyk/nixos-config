export default function MonitorCard({ icon, title, value, statusClass }: {
  icon: string
  title: string
  value: () => string
  statusClass: () => string
}) {
  return (
    <box cssClasses={["monitor-card"]} vertical>
      <label cssClasses={["card-icon"]} label={icon} />
      <label cssClasses={["card-title"]} label={title} />
      <label
        cssClasses={() => ["card-value", statusClass()]}
        label={value}
      />
    </box>
  )
}
