# 統合テスト DBフィクスチャ規則

## 概要

CIでは複数のテストファイルが同一DBを共有する。
テスト間の干渉を防ぐため、以下のルールを遵守する。

## 禁止事項

### 1. drop_all 禁止

```python
# NG: 他のテストに影響する
@pytest.fixture(autouse=True)
async def setup_database():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)   # 禁止
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)   # 禁止
```

### 2. 固定ID常時INSERT 禁止

```python
# NG: 2回目の実行で重複キーエラー
@pytest.fixture
async def test_item(session):
    item = await repo.create_with_id(
        item_id=UUID("11111111-1111-1111-1111-111111111111"),
        name="Test Item"
    )  # 2回目でエラー
    return item
```

## 推奨パターン

### 1. create_all のみ使用

```python
# OK: テーブル作成のみ（drop_all なし）
@pytest.fixture(autouse=True)
async def setup_database():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)  # テーブル作成のみ
    yield engine
```

### 2. find or create パターン

```python
# OK: 既存があれば再利用
@pytest.fixture
async def test_item(session):
    repo = ItemRepository(session)
    existing = await repo.find_by_id(TEST_ITEM_ID)
    if existing:
        return existing  # 既存があれば再利用
    return await repo.create_with_id(item_id=TEST_ITEM_ID, name="Test Item")
```

### 3. 動的ID生成

```python
# OK: 毎回新しいIDを生成
@pytest.fixture
async def create_test_item(session):
    async def _create(name: str = "Test Item"):
        item_id = uuid4()  # 毎回新しいID
        await repo.create_with_id(item_id=item_id, name=name)
        return item_id
    return _create
```

### 4. ファクトリーパターン

```python
# OK: 柔軟なテストデータ生成
@pytest.fixture
def item_factory(session):
    async def _create(**kwargs):
        defaults = {
            "item_id": uuid4(),
            "name": "Test Item",
            "status": "pending",
        }
        defaults.update(kwargs)
        return await ItemRepository(session).create(**defaults)
    return _create
```

## 共通テストID

```python
# conftest.py で定義
TEST_ITEM_ID = UUID("11111111-1111-1111-1111-111111111111")
```

全統合テストでこのIDを使用（find or create パターンで）。

## テストマーカー

| マーカー | 説明 | CI実行 |
|---------|------|:------:|
| `unit` | 単体テスト（DBなし） | Yes |
| `integration` | 統合テスト（DB必須） | Yes |
| `integration_local` | ローカル専用 | No |
| `slow` | 遅いテスト | Yes |

```python
@pytest.mark.integration
async def test_create_item(session):
    ...

@pytest.mark.integration_local
async def test_external_api(session):
    # CIではスキップされる
    ...
```

## 関連ファイル

- [skills/testing-patterns/SKILL.md](../skills/testing-patterns/SKILL.md)
