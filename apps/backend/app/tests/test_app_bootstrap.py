"""アプリのブートストラップ検証テスト。"""

from app.kernel import create_app


def test_create_app() -> None:
    app = create_app()
    assert app.title == "DocDD Starter API"
