from __future__ import annotations

import sys
from pathlib import Path

# apps/backend/app を import できるようテスト時にパスを追加
ROOT = Path(__file__).resolve().parents[3]
BACKEND_APP = ROOT / "apps" / "backend"
if str(BACKEND_APP) not in sys.path:
    sys.path.insert(0, str(BACKEND_APP))

from app.kernel import create_app  # noqa: E402


def test_create_app_sets_title() -> None:
    app = create_app()
    assert app.title == "DocDD Starter API"
