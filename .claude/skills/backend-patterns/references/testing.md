# テストパターン

> pytest による FastAPI テスト戦略。

## テストマーカー

```python
import pytest

# モジュール全体に適用
pytestmark = pytest.mark.unit

# 個別テストに適用
@pytest.mark.integration
async def test_create_item(async_client):
    ...
```

| マーカー | 説明 | CI 実行 |
|---------|------|:-------:|
| `unit` | 単体テスト（モック使用） | Yes |
| `integration` | 統合テスト（DB 必須） | Yes |
| `integration_local` | ローカル専用 | No |

## 非同期テストクライアント

```python
# tests/conftest.py
import pytest_asyncio
from httpx import ASGITransport, AsyncClient

@pytest_asyncio.fixture
async def async_client() -> AsyncClient:
    engine = create_async_engine(settings.database_url, poolclass=NullPool)
    session_factory = async_sessionmaker(engine, expire_on_commit=False)

    async def override_get_db():
        async with session_factory() as session:
            try:
                yield session
                await session.commit()
            except Exception:
                await session.rollback()
                raise

    app = create_app()
    app.dependency_overrides[get_db] = override_get_db

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

    await engine.dispose()
```

## 認証ヘッダ fixture

```python
from app.shared.auth.testing import create_auth_headers

TEST_USER_ID = UUID("33333333-3333-3333-3333-333333333333")

@pytest.fixture
def auth_headers() -> dict[str, str]:
    """admin ロールの認証ヘッダ"""
    return create_auth_headers(
        user_id=TEST_USER_ID,
        role="admin",
    )

@pytest.fixture
def viewer_auth_headers() -> dict[str, str]:
    """viewer ロールの認証ヘッダ"""
    return create_auth_headers(
        user_id=TEST_USER_ID,
        role="viewer",
    )
```

## テストデータ作成（find or create）

```python
# CI では複数テストが同一 DB を共有するため、drop_all 禁止

async def _create_test_items(session: AsyncSession) -> None:
    repo = ItemRepository(session)

    # 既存があれば再利用
    existing = await repo.find_by_id(TEST_ITEM_ID)
    if not existing:
        await repo.create_with_id(
            item_id=TEST_ITEM_ID,
            name="テストアイテム",
        )
    await session.commit()
```

## ファクトリ fixture

```python
@pytest_asyncio.fixture
async def create_item() -> Callable[..., Awaitable[UUID]]:
    """テスト用 Item を動的に作成"""
    async def _create(item_id: UUID | None = None) -> UUID:
        if item_id is None:
            item_id = uuid4()  # 毎回新しい ID

        async with session_factory() as session:
            repo = ItemRepository(session)
            existing = await repo.find_by_id(item_id)
            if not existing:
                await repo.create_with_id(item_id=item_id, ...)
                await session.commit()
        return item_id

    return _create
```

## API テスト例

```python
@pytest.mark.integration
async def test_list_items(async_client: AsyncClient, auth_headers: dict):
    response = await async_client.get(
        "/api/items",
        headers=auth_headers,
    )
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)


@pytest.mark.integration
async def test_process_requires_admin(
    async_client: AsyncClient,
    viewer_auth_headers: dict,
):
    response = await async_client.post(
        "/api/items/some-id/process",
        headers=viewer_auth_headers,
    )
    assert response.status_code == 403
```

## 関連ドキュメント

- [FastAPI Testing](https://fastapi.tiangolo.com/tutorial/testing/)
- [pytest-asyncio](https://pytest-asyncio.readthedocs.io/)
- [Testing Guide](../../../../docs/backend/TESTING_GUIDE.md)
