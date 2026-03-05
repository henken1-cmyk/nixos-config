import { fetch } from "ags/fetch"

const PROMETHEUS_URL = "http://localhost:9090"

export async function queryInstant(expr: string, url: string = PROMETHEUS_URL): Promise<string | null> {
  try {
    const resp = await fetch(`${url}/api/v1/query`, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: `query=${encodeURIComponent(expr)}`,
    })
    const data = await resp.json()
    if (data.status === "success" && data.data.result.length > 0) {
      return data.data.result[0].value[1]
    }
    return null
  } catch (e) {
    console.log(`[prom] error for: ${expr}`, e)
    return null
  }
}
