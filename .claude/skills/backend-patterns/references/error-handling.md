# エラーハンドリング

> FastAPI でのエラーハンドリングパターン。

## エラークラス階層

ドメイン固有のエラーは Service 層で定義し、API 層で HTTPException に変換。

```python
# services/item_service.py

class ItemError(Exception):
    """アイテム関連のエラー基底クラス"""
    pass


class ItemNotFoundError(ItemError):
    """アイテムが見つからないエラー"""
    def __init__(self, item_id: UUID) -> None:
        self.item_id = item_id
        super().__init__(f"アイテムが見つかりません: item_id={item_id}")


class ItemAlreadyExistsError(ItemError):
    """アイテム重複エラー"""
    def __init__(self, name: str) -> None:
        self.name = name
        super().__init__("このアイテム名は既に登録されています")

    @property
    def code(self) -> str:
        return "ITEM_EXISTS"
```

## API 層での変換

```python
# presentation/routes.py
from fastapi import HTTPException
from ..services import (
    ItemNotFoundError,
    ItemNotProcessableError,
    AccessDeniedError,
)

@router.post("/items/{item_id}/process")
async def process_item(item_id: str, ...):
    try:
        result = await service.process(...)
    except ItemNotFoundError:
        raise HTTPException(status_code=404, detail="アイテムが見つかりません")
    except AccessDeniedError:
        # 情報漏洩防止: 404 で返す
        raise HTTPException(status_code=404, detail="アイテムが見つかりません")
    except ItemNotProcessableError as e:
        raise HTTPException(
            status_code=400,
            detail=f"処理対象外のステータスです: {e.status}",
        )
    return result
```

## エラーレスポンス形式

### シンプルな形式

```python
raise HTTPException(status_code=404, detail="アイテムが見つかりません")
```

### 構造化された形式

```python
raise HTTPException(
    status_code=400,
    detail={
        "code": "NOT_CONFIGURED",
        "message": "設定が完了していません",
    },
)
```

## バリデーションエラー

Pydantic のバリデーションエラーは FastAPI が自動で 422 レスポンスに変換。

```python
from pydantic import BaseModel, Field

class CreateItemInput(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    email: str = Field(..., regex=r"^[\w\.-]+@[\w\.-]+\.\w+$")
    quantity: int = Field(..., ge=1, le=1000)
```

## ログ出力

```python
import logging
logger = logging.getLogger(__name__)

async def process(self, input_data: ProcessInput):
    logger.info("処理開始: item_id=%s", input_data.item_id)

    item = await self.item_repo.find_by_id(input_data.item_id)
    if not item:
        logger.warning("Item not found: item_id=%s", input_data.item_id)
        raise ItemNotFoundError(input_data.item_id)
```

## 関連ドキュメント

- [FastAPI Handling Errors](https://fastapi.tiangolo.com/tutorial/handling-errors/)
- [FastAPI Custom Exception Handlers](https://fastapi.tiangolo.com/tutorial/handling-errors/#install-custom-exception-handlers)
