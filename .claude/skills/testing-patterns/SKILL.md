# Testing Patterns - テスト戦略

## 概要

pytest（バックエンド）と Vitest（フロントエンド）を用いたテスト戦略を定義します。

## テスト分類

| 種別 | 目的 | ツール | 実行頻度 |
|------|------|--------|---------|
| Unit | 単一関数/コンポーネント | pytest / Vitest | 常時 |
| Integration | モジュール間連携 | pytest / Playwright | PR時 |
| E2E | ユーザーシナリオ | Playwright | デプロイ前 |

## ディレクトリ構造

```
tests/
├── backend/
│   ├── unit/
│   │   └── test_billing_service.py
│   ├── integration/
│   │   └── test_billing_api.py
│   └── conftest.py
└── frontend/
    ├── unit/
    │   └── sample/
    │       └── balance-status.test.ts
    └── e2e/
        └── login.spec.ts
```

## バックエンド（pytest）

### 基本構造

```python
# tests/backend/unit/test_billing_service.py
import pytest
from decimal import Decimal
from app.modules.billing.domain.services import BillingService

class TestBillingService:
    """BillingService のユニットテスト"""

    def test_calculate_total_with_issued_invoices(self):
        """発行済み請求書の合計を計算する"""
        # Arrange
        repository = MockInvoiceRepository()
        service = BillingService(repository)

        # Act
        total = service.calculate_total("customer-1")

        # Assert
        assert total == Decimal("100.00")

    def test_calculate_total_ignores_draft_invoices(self):
        """下書き請求書は合計に含めない"""
        ...
```

### フィクスチャ

```python
# tests/backend/conftest.py
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

@pytest.fixture
def db_session():
    """テスト用DBセッション"""
    engine = create_engine("sqlite:///:memory:")
    Session = sessionmaker(bind=engine)
    session = Session()
    yield session
    session.close()

@pytest.fixture
def sample_invoice():
    """サンプル請求書"""
    return Invoice(
        id="inv-001",
        customer_id="cust-001",
        amount=Decimal("100.00"),
        due_date=date(2024, 1, 31),
        status="issued"
    )
```

### マーカー

```python
# pytest.ini または pyproject.toml で定義
# [tool.pytest.ini_options]
# markers = [
#     "tc_id: Test Case ID for traceability",
#     "slow: marks tests as slow",
# ]

@pytest.mark.tc_id("TC-BILLING-001-001")
def test_invoice_creation():
    """TC-BILLING-001-001: 請求書作成テスト"""
    ...

@pytest.mark.slow
def test_large_data_processing():
    """大量データ処理テスト"""
    ...
```

### 実行コマンド

```bash
# 全テスト
PYTHONPATH=apps/backend pytest tests/backend -v

# 特定マーカー
PYTHONPATH=apps/backend pytest tests/backend -m "tc_id"

# カバレッジ付き
PYTHONPATH=apps/backend pytest tests/backend --cov=apps/backend --cov-report=html
```

## フロントエンド（Vitest）

### 基本構造

```tsx
// tests/frontend/unit/sample/balance-status.test.ts
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { BalanceStatus } from '@/app/dashboard/_components/BalanceStatus';

describe('BalanceStatus', () => {
  it('残高を表示する', () => {
    render(<BalanceStatus balance={1000} />);
    expect(screen.getByText('1,000円')).toBeInTheDocument();
  });

  it('残高更新時にアニメーションを表示する', async () => {
    const { rerender } = render(<BalanceStatus balance={1000} />);
    rerender(<BalanceStatus balance={2000} />);

    expect(screen.getByTestId('balance-animation')).toBeVisible();
  });
});
```

### モック

```tsx
// API モック
vi.mock('@/lib/api-client', () => ({
  fetchBalance: vi.fn().mockResolvedValue({ balance: 1000 })
}));

// Next.js router モック
vi.mock('next/navigation', () => ({
  useRouter: () => ({
    push: vi.fn(),
    replace: vi.fn(),
  }),
  usePathname: () => '/dashboard',
}));
```

### 実行コマンド

```bash
# 全テスト
npm run test:unit

# ウォッチモード
npm run test:unit -- --watch

# 特定ファイル
npx vitest run tests/frontend/unit/sample/balance-status.test.ts

# カバレッジ
npm run test:unit -- --coverage
```

## トレーサビリティ

### TC マーカーの付与

```python
# Python
@pytest.mark.tc_id("TC-SAMPLE-001-001")
def test_sample():
    ...
```

```tsx
// TypeScript（describe の説明に含める）
describe('TC-SAMPLE-001-002: BalanceStatus コンポーネント', () => {
  ...
});
```

### マップとの連携

```json
// docs/testing/traceability/sample_map.json
{
  "mappings": [
    {
      "test_case_id": "TC-SAMPLE-001-001",
      "automation": {
        "status": "automated",
        "command": "pytest tests/backend/unit/test_balance_projection.py -k test_sample"
      }
    }
  ]
}
```

## アンチパターン

### NG: 実装の詳細をテスト

```python
def test_internal_method():
    service = BillingService(repo)
    # NG: プライベートメソッドをテスト
    assert service._calculate_tax(100) == 10
```

### OK: 公開インターフェースをテスト

```python
def test_total_includes_tax():
    service = BillingService(repo)
    # OK: 公開メソッドの結果をテスト
    assert service.calculate_total_with_tax("cust-1") == Decimal("110.00")
```

### NG: テストの独立性がない

```python
class TestOrdered:
    total = 0

    def test_add(self):
        TestOrdered.total += 10  # NG: 状態を共有

    def test_subtract(self):
        assert TestOrdered.total == 10  # 前のテストに依存
```

## 参考資料

- [pytest 公式ドキュメント](https://docs.pytest.org/)
- [Vitest 公式ドキュメント](https://vitest.dev/)
- [Testing Library](https://testing-library.com/)
- [Testing Guide](../../../docs/testing/README.md)
