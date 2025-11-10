import pytest
from datetime import datetime, timezone

from app.modules.sample.balance_projection import compute_sync_status, project_balance


@pytest.mark.tc_id("TC-SAMPLE-001-001")
def test_sample_balance_instant_update():
    """DocDD TS-SAMPLE-001: 即時反映シナリオ."""
    current = 1000
    delta = 500
    projected = project_balance(current, delta)

    assert projected == 1500

    sync_state = compute_sync_status(projected, 1500, datetime.now(timezone.utc))
    assert sync_state["status"] == "synced"
    assert "最新" in sync_state["banner"]


@pytest.mark.tc_id("TC-SAMPLE-001-002")
def test_sample_balance_fallback_banner():
    """DocDD TS-SAMPLE-001: 遅延フォールバック通知."""
    projected = project_balance(1200, 0)

    sync_state = compute_sync_status(projected, 1000, None)
    assert sync_state["status"] == "pending"
    assert "同期" in sync_state["banner"]
