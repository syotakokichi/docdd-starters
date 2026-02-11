"""Utility helpers that mirror TS-SAMPLE-001 test steps."""

from __future__ import annotations

from datetime import datetime, timedelta, timezone

SYNC_STALENESS_SECONDS = 5


def project_balance(current_balance: int, pending_delta: int) -> int:
    """Return optimistic balance after applying the pending delta."""
    return current_balance + pending_delta


def compute_sync_status(
    projected_balance: int,
    confirmed_balance: int,
    last_synced_at: datetime | None,
) -> dict[str, str]:
    """Return sync status used by DocDD sample tests."""
    if projected_balance == confirmed_balance:
        return {
            "status": "synced",
            "banner": "残高は最新です",
        }

    is_stale = True
    if last_synced_at:
        freshness_cutoff = datetime.now(timezone.utc) - timedelta(
            seconds=SYNC_STALENESS_SECONDS
        )
        is_stale = last_synced_at < freshness_cutoff

    banner = "残高同期を確認しています..." if is_stale else "取引を確定中..."
    return {
        "status": "pending",
        "banner": banner,
    }
