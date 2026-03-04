import { fetch } from "ags/fetch"

const PROMETHEUS_URL = "http://localhost:9090"

export async function queryInstant(expr: string): Promise<string | null> {
  try {
    const url = `${PROMETHEUS_URL}/api/v1/query?query=${encodeURIComponent(expr)}`
    const resp = await fetch(url)
    const data = await resp.json()
    if (data.status === "success" && data.data.result.length > 0) {
      return data.data.result[0].value[1]
    }
    return null
  } catch {
    return null
  }
}
