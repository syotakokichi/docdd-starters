# 依存性注入パターン

> FastAPI の Depends による依存性注入。

## 基本パターン

```python
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.kernel.database import get_db

@router.get("/items")
async def list_items(
    db: AsyncSession = Depends(get_db),
):
    repo = ItemRepository(db)
    return await repo.find_all()
```

## 階層的な依存関係

```python
# presentation/deps.py
async def get_external_adapter(
    item_id: UUID,
    db: AsyncSession = Depends(get_db),
    settings: AppSettings = Depends(get_settings),
) -> ExternalAdapter:
    """設定から外部アダプターを取得"""
    repo = ItemRepository(db)
    item = await repo.find_by_id(item_id)

    if not item:
        raise HTTPException(status_code=404, detail="アイテムが見つかりません")

    return ExternalAdapter(settings, item_config=item.config)
```

## 認証コンテキストの注入

```python
from app.shared.auth import AuthContext, get_current_user

@router.get("/items")
async def list_items(
    auth: AuthContext = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # auth.user_id, auth.role で認証情報にアクセス
    ...
```

## サービスの注入パターン

### パターン1: 手動インスタンス化（推奨）

```python
@router.post("/items/{item_id}/process")
async def process_item(
    item_id: str,
    db: AsyncSession = Depends(get_db),
):
    service = ItemService(db)
    return await service.process(...)
```

### パターン2: ファクトリ関数

```python
# presentation/deps.py
def get_item_service(db: AsyncSession = Depends(get_db)) -> ItemService:
    return ItemService(db)

# presentation/routes.py
@router.post("/items/{item_id}/process")
async def process_item(
    service: ItemService = Depends(get_item_service),
):
    return await service.process(...)
```

## テストでのオーバーライド

```python
# tests/conftest.py
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
app.dependency_overrides[get_settings] = _get_test_settings
```

## 関連ドキュメント

- [FastAPI Dependencies](https://fastapi.tiangolo.com/tutorial/dependencies/)
- [FastAPI Sub-dependencies](https://fastapi.tiangolo.com/tutorial/dependencies/sub-dependencies/)
- [FastAPI Testing Dependencies](https://fastapi.tiangolo.com/advanced/testing-dependencies/)
