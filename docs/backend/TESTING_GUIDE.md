# FastAPI テストガイド

FastAPI でモジュラーモノリスを構築する際のテスト指針とテンプレートをまとめます。pytest を前提としつつ、実際の PostgreSQL や SQLite インメモリ、Testcontainers など状況に応じて使い分けられる構成としています。

## 1. テストディレクトリ構成

```text
project/
├── apps/backend/app/          # アプリケーション本体
└── tests/backend/
    ├── unit/                  # ドメイン・サービスの単体テスト
    └── integration/           # API 統合テスト
```

- 単体テストは副作用を排除したドメイン／ユースケースの検証に集中します。
- 統合テストでは FastAPI `TestClient` を使ってエンドポイント全体を検証します。
- `PYTHONPATH=apps/backend` を指定して pytest を実行することで、アプリ本体を import できるようにします。

## 2. pytest フィクスチャと依存関係の差し替え

共通セットアップは `tests/conftest.py` にまとめ、SQLite インメモリや Testcontainers を利用してテスト用 DB を準備します。

```python
# tests/conftest.py
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.config import get_settings
from app.kernel import create_app
from app.shared import get_session
from app.core.database import Base  # SQLAlchemy Base

@pytest.fixture(scope="function")
def db_session():
    engine = create_engine("sqlite://", connect_args={"check_same_thread": False})
    Base.metadata.create_all(engine)
    SessionLocal = sessionmaker(bind=engine)
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(engine)

@pytest.fixture(scope="function")
def client(db_session):
    app = create_app()

    # FastAPI 依存関数をテスト用セッションに差し替え
    def override_get_session():
        yield db_session

    app.dependency_overrides[get_session] = override_get_session
    return TestClient(app)
```

- `db_session` フィクスチャでテスト用 DB を用意し、各テスト後にクリーンアップします。
- `client` フィクスチャで `get_session` などの依存関数をオーバーライドし、API 呼び出し時にテスト DB が使われるようにします。
- PostgreSQL を使う場合は `DATABASE_URL` をテスト用に切り替えるか、Testcontainers で一時的なコンテナを起動してください。

## 3. 単体テストのテンプレート

外部 I/O をモックしたドメインサービスのテスト例です。

```python
# tests/backend/unit/test_user_service.py
import pytest
from app.modules.example.services.user_service import UserService

class DummyUserRepo:
    def __init__(self):
        self.users = {1: {"name": "Alice", "email": "alice@example.com"}}

    def get_user(self, user_id: int):
        return self.users.get(user_id)

class DummyLogger:
    def info(self, message: str) -> None:
        pass

@pytest.fixture
def service():
    return UserService(user_repository=DummyUserRepo(), logger=DummyLogger())

def test_get_user_display_name_success(service):
    assert service.get_user_display_name(1) == "Alice (alice@example.com)"

def test_get_user_display_name_not_found(service):
    with pytest.raises(ValueError):
        service.get_user_display_name(999)
```

ポイント:
- 依存するリポジトリや外部サービスはモック／スタブで差し替え、副作用を排除します。
- ドメインロジックの分岐や例外を細かく検証します。

## 4. FastAPI 統合テストのテンプレート

```python
# tests/backend/integration/test_users.py

def test_create_user_success(client):
    payload = {"email": "bob@example.com", "password": "secret"}
    response = client.post("/users/", json=payload)

    assert response.status_code == 200
    data = response.json()
    assert data["email"] == "bob@example.com"
    assert "id" in data

def test_create_user_validation_error(client):
    payload = {"email": "invalid", "password": ""}
    response = client.post("/users/", json=payload)

    assert response.status_code == 422
    assert response.json()["detail"]
```

- 正常系と異常系（バリデーションエラーなど）をセットで検証します。
- フィクスチャで差し替えたテスト用 DB が利用されるため、本番 DB を汚染する心配はありません。

## 5. データベース戦略の選択肢

| 方法 | メリット | 留意点 |
| ---- | -------- | ------ |
| SQLite インメモリ | 高速・管理が容易 | PostgreSQL 固有機能は検証できない |
| Testcontainers (Postgres) | 本番に近い挙動 | 起動コストが高い、CI で Docker が必要 |
| 共有テスト DB | データ再利用が可能 | テスト毎の初期化を徹底しないと汚染リスク |

プロジェクト要件に合わせて選択し、`pytest.ini` や環境変数で切り替えられるようにしておくと便利です。

## 6. テスト実行コマンド例

```bash
# 単体テストのみ
PYTHONPATH=apps/backend pytest tests/backend/unit

# 統合テストのみ
PYTHONPATH=apps/backend pytest tests/backend/integration

# すべてのバックエンドテスト
PYTHONPATH=apps/backend pytest tests/backend
```

CI では `.github/workflows/test.yml` などで上記コマンドを実行し、7-axis `TC` の `automation.command` と一致させてください。

## 7. Traceability

- 新しいテストを追加したら `docs/testing/traceability/<domain>_map.json` を更新します。
- `python scripts/test/validate_traceability_map.py` で整合性を検証し、テストコマンド・結果を `TC` frontmatter に記載します。

---

このガイドをベースに、プロジェクト固有のルールやフィクスチャを追加してカスタマイズしてください。
