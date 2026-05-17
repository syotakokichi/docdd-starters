---
name: backend-patterns
description: |
  FastAPI モジュラーモノリスのバックエンド実装パターン。
  API 設計（レイヤー分離）、DDD パターン（Entity / Repository / Service）、
  依存性注入、エラーハンドリング、ミドルウェア、pytest テスト戦略を提供。
  バックエンド実装時（`/develop` 等）に参照される。
---

# Backend Patterns - FastAPI モジュラーモノリス

## 概要

FastAPI を用いたモジュラーモノリスアーキテクチャのパターンを定義します。

**対象範囲**:
- API 設計（RESTful、レイヤー分離）
- DDD パターン（Entity、Repository、Service）
- 依存性注入（Depends パターン）
- エラーハンドリング（例外階層、HTTPException 変換）
- ミドルウェア（CORS、ログ、認証）
- テスト戦略（pytest-asyncio、fixture）

## 参照インデックス

| ドキュメント | 内容 | 優先度 |
|-------------|------|:------:|
| [api-design.md](references/api-design.md) | RESTful API 設計、ルート定義、アクセス制御 | 高 |
| [ddd-patterns.md](references/ddd-patterns.md) | Entity、Repository、Service のパターン | 高 |
| [dependency-injection.md](references/dependency-injection.md) | FastAPI Depends パターン | 高 |
| [error-handling.md](references/error-handling.md) | 例外階層、HTTPException 変換 | 中 |
| [middleware.md](references/middleware.md) | CORS、ログ、認証ミドルウェア | 中 |
| [testing.md](references/testing.md) | pytest-asyncio、fixture パターン | 中 |

## ディレクトリ構造

```
apps/backend/
├── app/
│   ├── __init__.py
│   ├── main.py              # アプリケーションエントリポイント
│   ├── kernel/              # 共通基盤
│   │   ├── __init__.py
│   │   ├── config.py        # 設定管理
│   │   ├── database.py      # DB接続
│   │   └── dependencies.py  # 共通依存性
│   ├── modules/             # ドメインモジュール
│   │   └── <module_name>/
│   │       ├── __init__.py
│   │       ├── domain/      # ドメイン層
│   │       ├── infrastructure/  # インフラ層
│   │       └── presentation/    # プレゼンテーション層
│   └── shared/              # 共通ユーティリティ
│       ├── __init__.py
│       └── utils.py
├── requirements.txt
└── requirements-dev.txt
```

## モジュール構造

### domain/

ビジネスロジックとドメインモデルを配置。

```python
# modules/billing/domain/models.py
from dataclasses import dataclass
from datetime import date
from decimal import Decimal

@dataclass
class Invoice:
    id: str
    customer_id: str
    amount: Decimal
    due_date: date
    status: str  # draft | issued | paid | overdue
```

```python
# modules/billing/domain/services.py
from .models import Invoice

class BillingService:
    def __init__(self, repository: "InvoiceRepository"):
        self._repository = repository

    def calculate_total(self, customer_id: str) -> Decimal:
        invoices = self._repository.find_by_customer(customer_id)
        return sum(inv.amount for inv in invoices if inv.status == "issued")
```

### infrastructure/

データベースアクセスや外部サービス連携を配置。

```python
# modules/billing/infrastructure/repositories.py
from sqlalchemy.orm import Session
from ..domain.models import Invoice

class InvoiceRepository:
    def __init__(self, session: Session):
        self._session = session

    def find_by_customer(self, customer_id: str) -> list[Invoice]:
        # SQLAlchemy クエリ
        ...

    def save(self, invoice: Invoice) -> Invoice:
        ...
```

### presentation/

API エンドポイントとスキーマを配置。

```python
# modules/billing/presentation/routes.py
from fastapi import APIRouter, Depends
from .schemas import InvoiceResponse, CreateInvoiceRequest
from ..domain.services import BillingService

router = APIRouter(prefix="/billing", tags=["billing"])

@router.get("/invoices/{invoice_id}", response_model=InvoiceResponse)
async def get_invoice(
    invoice_id: str,
    service: BillingService = Depends(get_billing_service)
):
    return service.get_invoice(invoice_id)
```

```python
# modules/billing/presentation/schemas.py
from pydantic import BaseModel
from decimal import Decimal
from datetime import date

class InvoiceResponse(BaseModel):
    id: str
    customer_id: str
    amount: Decimal
    due_date: date
    status: str

    class Config:
        from_attributes = True
```

## 依存性注入

```python
# kernel/dependencies.py
from functools import lru_cache
from .config import Settings
from .database import get_session

@lru_cache
def get_settings() -> Settings:
    return Settings()

def get_db_session():
    session = get_session()
    try:
        yield session
    finally:
        session.close()
```

```python
# modules/billing/dependencies.py
from fastapi import Depends
from app.kernel.dependencies import get_db_session
from .domain.services import BillingService
from .infrastructure.repositories import InvoiceRepository

def get_billing_service(
    session = Depends(get_db_session)
) -> BillingService:
    repository = InvoiceRepository(session)
    return BillingService(repository)
```

## アンチパターン

### NG: モジュール間の直接依存

```python
# billing/domain/services.py
from modules.customer.domain.models import Customer  # NG: 直接import
```

### OK: 共有インターフェース経由

```python
# shared/interfaces.py
from abc import ABC, abstractmethod

class CustomerServiceInterface(ABC):
    @abstractmethod
    def get_customer(self, customer_id: str) -> dict:
        ...

# billing/domain/services.py
from app.shared.interfaces import CustomerServiceInterface

class BillingService:
    def __init__(self, customer_service: CustomerServiceInterface):
        ...
```

## テスト

```python
# tests/backend/unit/test_billing_service.py
import pytest
from app.modules.billing.domain.services import BillingService

class MockInvoiceRepository:
    def find_by_customer(self, customer_id: str):
        return [...]

def test_calculate_total():
    repository = MockInvoiceRepository()
    service = BillingService(repository)
    total = service.calculate_total("customer-1")
    assert total == Decimal("100.00")
```

## 参考資料

- [FastAPI 公式ドキュメント](https://fastapi.tiangolo.com/)
- [Backend README](../../../apps/backend/README.md)
- [ARCHITECTURE.md](../../../docs/backend/ARCHITECTURE.md) - バックエンドアーキテクチャ詳細
- [TESTING_GUIDE.md](../../../docs/backend/TESTING_GUIDE.md) - テスト戦略ガイド
