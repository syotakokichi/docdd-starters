# DDD パターン

> モジュラーモノリスで採用する DDD パターン。

## レイヤー構成

```
app/modules/<module_name>/
├── domain/           # エンティティ、値オブジェクト
├── services/         # ドメインサービス、アプリケーションサービス
├── infrastructure/   # リポジトリ実装、外部サービス
│   ├── models/       # SQLAlchemy モデル
│   └── repositories/ # リポジトリ実装
├── schemas/          # API スキーマ（Pydantic）
└── presentation/     # API 層（routes）
```

## Entity（エンティティ）

ID による同一性判定。Pydantic BaseModel で定義。

```python
# domain/item.py
from pydantic import BaseModel, Field

class Item(BaseModel):
    """アイテムエンティティ"""

    id: str
    name: str
    status: str = Field(..., description="draft | active | archived")
```

**注意**: domain/ のエンティティはビジネスルールの表現に使用。
DB 永続化には infrastructure/models/ の SQLAlchemy モデルを使用。

## Value Object（値オブジェクト）

属性値による等価性判定。不変。

```python
from dataclasses import dataclass

@dataclass(frozen=True)
class Money:
    amount: Decimal
    currency: str = "JPY"

    def add(self, other: "Money") -> "Money":
        if self.currency != other.currency:
            raise ValueError("通貨が異なります")
        return Money(self.amount + other.amount, self.currency)
```

## Repository（リポジトリ）

AsyncSession を注入し、CRUD 操作を提供。

```python
# infrastructure/repositories/item_repository.py
class ItemRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def find_by_id(self, item_id: UUID) -> Optional[ItemModel]:
        stmt = select(ItemModel).where(ItemModel.id == item_id)
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def create(self, ...) -> ItemModel:
        item = ItemModel(...)
        self.session.add(item)
        await self.session.flush()
        await self.session.refresh(item)
        return item
```

## Application Service（アプリケーションサービス）

ユースケースのオーケストレーション。トランザクション境界の管理。

```python
# services/application_service.py
class ApplicationService:
    """ワークフロー全体のオーケストレーション"""

    def __init__(self, session: AsyncSession) -> None:
        self.session = session
        self.item_repo = ItemRepository(session)

    async def process(self, input_data: ProcessInput) -> ProcessResult:
        # 1. 取得・検証
        item = await self.item_repo.find_by_id(input_data.item_id)
        if not item:
            raise ItemNotFoundError(input_data.item_id)

        # 2. ビジネスロジック実行
        result = await self._execute_logic(item, input_data)

        # Note: commit は API 層の get_db() で管理
        return result
```

## Domain Service（ドメインサービス）

単一エンティティに属さないビジネスロジック。

```python
# services/pricing_service.py
class PricingService:
    """価格計算のビジネスロジック"""

    def __init__(self, session: AsyncSession) -> None:
        self.item_repo = ItemRepository(session)
        self.discount_repo = DiscountRepository(session)

    async def calculate_price(self, item_id: UUID, quantity: int) -> Money:
        item = await self.item_repo.find_by_id(item_id)
        discounts = await self.discount_repo.find_applicable(item_id)

        base_price = Money(item.price * quantity)
        return self._apply_discounts(base_price, discounts)
```

## トランザクション管理

トランザクション境界は API 層の `get_db()` で管理。

```python
# kernel/database.py
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with session_factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
```

## 関連ドキュメント

- [Domain-Driven Design Reference](https://www.domainlanguage.com/ddd/reference/)
