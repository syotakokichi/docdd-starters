import { describe, expect, it } from "vitest"

import { getBalanceSyncState } from "@/lib/sample/balanceStatus"

describe("TS-SAMPLE-001 バランス同期 UI", () => {
  it("TC-SAMPLE-001-001: 即時反映時は同期済みを返す", () => {
    const result = getBalanceSyncState({ projected: 1500, confirmed: 1500, lastSyncedAt: new Date() })

    expect(result.status).toBe("synced")
    expect(result.banner).toContain("最新")
  })

  it("TC-SAMPLE-001-002: 差分があれば pending を返す", () => {
    const result = getBalanceSyncState({ projected: 1500, confirmed: 1000, lastSyncedAt: null })

    expect(result.status).toBe("pending")
    expect(result.banner).toContain("同期")
  })
})
