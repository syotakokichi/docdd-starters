export type BalanceSnapshot = {
  projected: number
  confirmed: number
  lastSyncedAt?: Date | null
}

export type BalanceSyncState = {
  status: "synced" | "pending"
  banner: string
}

const STALE_THRESHOLD_MS = 5_000

export function getBalanceSyncState({ projected, confirmed, lastSyncedAt }: BalanceSnapshot): BalanceSyncState {
  if (projected === confirmed) {
    return { status: "synced", banner: "残高は最新です" }
  }

  const isStale = !lastSyncedAt || Date.now() - lastSyncedAt.getTime() > STALE_THRESHOLD_MS
  return {
    status: "pending",
    banner: isStale ? "残高同期を確認しています..." : "取引を確定中...",
  }
}
