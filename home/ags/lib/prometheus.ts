import { fetch } from "ags/fetch"

const PROMETHEUS_URL = "http://localhost:9090"

export type TimeSeries = [number, number][]

export async function queryRange(
  expr: string,
  rangeMinutes: number = 30,
  stepSeconds: number = 60,
  url: string = PROMETHEUS_URL,
): Promise<TimeSeries> {
  try {
    const end = Math.floor(Date.now() / 1000)
    const start = end - rangeMinutes * 60
    const body = `query=${encodeURIComponent(expr)}&start=${start}&end=${end}&step=${stepSeconds}`
    const resp = await fetch(`${url}/api/v1/query_range`, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body,
    })
    const data = await resp.json()
    if (data.status === "success" && data.data.result.length > 0) {
      return data.data.result[0].values.map(([t, v]: [number, string]) => [t, parseFloat(v)])
    }
    return []
  } catch (e) {
    console.log(`[prom] range error for: ${expr}`, e)
    return []
  }
}

export async function checkConnection(url: string): Promise<boolean> {
  try {
    const resp = await fetch(`${url}/-/ready`)
    return resp.ok
  } catch {
    return false
  }
}

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
