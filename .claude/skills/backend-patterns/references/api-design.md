# API 設計パターン

> FastAPI ベースの RESTful API 設計ガイド。

## レイヤー分離

API 層はビジネスロジックを持たず、HTTP リクエスト/レスポンスの変換のみを担当。

```
API層（routes.py）
    ↓ 入力バリデーション + 変換
Service層（*_service.py）
    ↓ ビジネスロジック
Repository層（*_repository.py）
    ↓ データアクセス
Model層（*_model.py）
```

## ルート定義

```python
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.kernel.database import get_db
from app.shared.auth import AuthContext, get_current_user
from ..services import ItemService, ItemNotFoundError
from ..schemas import ItemResponse

router = APIRouter()

@router.get("/items/{item_id}", response_model=ItemResponse)
async def get_item(
    item_id: str,
    db: AsyncSession = Depends(get_db),
    auth: AuthContext = Depends(get_current_user),
) -> ItemResponse:
    """アイテム詳細取得"""
    try:
        item_uuid = UUID(item_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="無効なIDです")

    service = ItemService(db)
    try:
        item = await service.get_item(item_uuid)
    except ItemNotFoundError:
        raise HTTPException(status_code=404, detail="アイテムが見つかりません")

    return ItemResponse.from_model(item)
```

## 一覧取得パターン

```python
@router.get("/items", response_model=List[ItemResponse])
async def list_items(
    status: Optional[str] = Query(None, description="ステータス"),
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
) -> List[ItemResponse]:
    """アイテム一覧取得"""
    repo = ItemRepository(db)
    items = await repo.find_all(
        status=status,
        limit=limit,
        offset=offset,
    )
    return [ItemResponse.from_model(item) for item in items]
```

## ロールベースアクセス制御

```python
from app.shared.auth import require_role

# admin ロール必須
@router.post("/items/{item_id}/approve")
async def approve_item(
    item_id: str,
    auth: AuthContext = Depends(require_role("admin")),
    ...
):
    ...

# viewer ロール以上（読み取り専用）
@router.get("/items")
async def list_items(
    auth: AuthContext = Depends(get_current_user),
    ...
):
    ...
```

## パスパラメータとクエリパラメータ

| 用途 | パターン | 例 |
|------|---------|-----|
| リソース識別 | パスパラメータ | `/items/{item_id}` |
| フィルタ | クエリパラメータ | `?status=pending&limit=50` |
| ソート | クエリパラメータ | `?sort=created_at&order=desc` |

## 関連ドキュメント

- [FastAPI Router](https://fastapi.tiangolo.com/tutorial/bigger-applications/)
- [FastAPI Path Parameters](https://fastapi.tiangolo.com/tutorial/path-params/)
- [FastAPI Query Parameters](https://fastapi.tiangolo.com/tutorial/query-params/)
