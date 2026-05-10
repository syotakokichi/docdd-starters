---
name: tdd-workflow
description: |
  pytest / Vitest TDD（テスト駆動開発）ワークフローを支援。
  RED-GREEN-REFACTOR サイクル、RED 証跡フォーマット、Backend (pytest) / Frontend (Vitest) のパターン集を提供。
  `/tdd` `/develop` `/verify` から参照される。
---

# TDD ワークフロースキル

## 概要

docdd-starters における TDD の実践パターン。
Backend は `make test-backend`（pytest）、Frontend は `make test-frontend`（Vitest）を使用する。
`0 selected` / `all skipped` / `no test files found` を「成功」扱いにしない。

判断基準（TDD 必須 / スキップ）は [`.claude/rules/tdd-gate.md`](../../rules/tdd-gate.md) を参照。

---

## 本リポジトリの pytest 前提（必須知識）

**本リポジトリの pytest marker は `tc_id` のみ**（`apps/backend/pytest.ini` 参照）。
SubsCore 由来の `unit` / `integration` / `integration_local` marker は本リポジトリでは **適用しない**。

代わりに **テスト配置ディレクトリ** で unit / integration を分ける:

| 種別 | 配置 | コマンド |
|------|------|----------|
| 単体テスト | `tests/backend/unit/` | `make test-backend`（全実行）/ `PYTHONPATH=apps/backend pytest tests/backend/unit/test_xxx.py -v`（focused） |
| 統合テスト | `tests/backend/integration/` | `make test-backend`（全実行）/ `PYTHONPATH=apps/backend pytest tests/backend/integration/test_xxx.py -v`（focused） |
| 全テスト | `tests/backend/` | `make test-backend` |

> **`PYTHONPATH=apps/backend` が必須**: `apps/backend/pytest.ini` の `pythonpath = app` は pytest 設定。Makefile 経由でない focused 実行では環境変数で同等の解決を行う。

### 正しいコマンド一覧

| 用途 | コマンド | 備考 |
|------|---------|------|
| 全 backend テスト | `make test-backend` | 推奨（CI と同一） |
| 全 frontend テスト | `make test-frontend` | 推奨（CI と同一） |
| 全テスト | `make test` | backend + frontend |
| 特定ファイル（unit） | `PYTHONPATH=apps/backend pytest tests/backend/unit/test_xxx.py -v` | focused |
| 特定テスト関数 | `PYTHONPATH=apps/backend pytest tests/backend/unit/test_xxx.py::test_func -v` | focused |
| integration の特定テスト | `PYTHONPATH=apps/backend pytest tests/backend/integration/test_xxx.py -v` | DB 起動が前提 |
| Frontend 特定ファイル | `cd apps/frontend && npx vitest run ../../tests/frontend/unit/xxx.test.ts` | focused |
| dx-docs（`.claude/`）変更時 | `make validate-claude` | frontmatter 検証 |
| DocDD 変更時 | `make traceability` | 7 軸 map 整合性 |

> 補足: `make test-unit` / `make test-integration` / `make quality-gate` などのターゲットは **本リポジトリには存在しない**（後続 Issue 5-1 想定）。skill / command でこれらのターゲットを案内しないこと。

---

## RED-GREEN サイクル

### フロー

```
1. 失敗するテストを書く（RED）
2. RED を確認する（make test-backend → FAILED を目視）
3. 最小実装を書く（GREEN にする）
4. GREEN を確認する（make test-backend → PASSED）
5. 必要なら整理（REFACTOR → GREEN を維持）
```

### ポイント

- **最小実装**: テストを通すだけの最小コードを書く。追加機能は次の RED から始める
- **1 サイクル 1 概念**: 1 つのテストが 1 つの振る舞いを検証する
- **RED は意図的に**: 偶然 RED になるのではなく、意図した失敗を確認する

---

## テストファイル作成時のツール選択

### Write / Edit がブロックされるパターン

`.claude/settings.json` の `permissions.deny` と harness の directory permission で以下がブロックされ得る:

| glob パターン | Write | Edit | MultiEdit | 備考 |
|-------------|:---:|:---:|:---:|------|
| `test_*.py` / `conftest.py` | ⚠️ | ❌ | ❌ | `conftest.py` は Write も deny されることがある |
| `*.test.*` / `*.spec.*` | ✅ | ❌ | ❌ | FE テスト（`.test.tsx` 等） |
| `vitest.config*` / `tsconfig.json` / `biome.json` / `pytest.ini` | ❌ | ❌ | ❌ | 設定ファイルは完全 deny |
| worktree 内の `apps/**` | ⚠️ | ⚠️ | ⚠️ | directory permission で `Write` が denied になる場合あり |

### 判断フロー

```
新規テストファイルを作成したい
  └→ 既存テストの改変か？
       └→ Yes → 置換ブロックを提示してユーザー側で反映（heredoc で上書きしない。弱体化リスク）
       └→ No（純粋な新規 RED テスト）
            └→ Write を試す
                └→ 通った → OK
                └→ denied → Bash heredoc を使う
                     └→ `cat > tests/backend/unit/test_xxx.py << 'EOF' ... EOF`
                     └→ `wc -l tests/backend/unit/test_xxx.py` で保存確認
                     └→ Bash も denied → `touch <path>` + 内容提示 → ユーザー貼付

設定ファイル（vitest.config.ts / pytest.ini 等）を変更したい
  └→ Write / Edit 両方 deny → パッチ内容を提示してユーザー側で反映（heredoc も使わない）
```

### なぜ新規 RED テストの heredoc は OK か

テスト弱体化（既存の PASS テストを失敗しないように書き換える等）の防止が目的であり、新規 RED テスト作成は TDD の正規手順であって弱体化ではない。
**既存テストの改変・設定ファイルの変更には heredoc を使わない**。

---

## パターン集

### パターン 1: 新しいビジネスロジック

```python
# ① RED: 先にテストを書く
# tests/backend/unit/test_fee_service.py
def test_calculate_subscription_fee_with_discount():
    """割引適用後の月額計算"""
    from app.modules.billing.services.fee_service import calculate_subscription_fee
    result = calculate_subscription_fee(base_amount=10000, discount_rate=0.1)
    assert result == 9000

# PYTHONPATH=apps/backend pytest tests/backend/unit/test_fee_service.py -v
# → FAILED: ImportError または AssertionError

# ② 実装
def calculate_subscription_fee(base_amount: int, discount_rate: float) -> int:
    return int(base_amount * (1 - discount_rate))

# ③ GREEN
# PYTHONPATH=apps/backend pytest tests/backend/unit/test_fee_service.py -v
# → PASSED
```

### パターン 2: バグ修正（再現テスト先行）

```python
# ① RED: バグを再現するテストを書く
def test_invoice_total_includes_tax():
    """バグ: 消費税が合計に含まれていない"""
    invoice = Invoice(subtotal=1000, tax_rate=0.1)
    assert invoice.total == 1100  # 現在は 1000 を返す

# → FAILED: AssertionError: assert 1000 == 1100

# ② 修正
@property
def total(self) -> int:
    return int(self.subtotal * (1 + self.tax_rate))

# ③ GREEN: PASSED
```

### パターン 3: 状態遷移テスト

```python
# ① RED: 遷移ルールを先に定義する
def test_contract_cannot_activate_from_cancelled():
    """解約済み契約を有効化しようとするとエラー"""
    contract = Contract(status=ContractStatus.CANCELLED)
    with pytest.raises(InvalidStateTransitionError):
        contract.activate()

def test_contract_can_activate_from_pending():
    """保留中の契約は有効化できる"""
    contract = Contract(status=ContractStatus.PENDING)
    contract.activate()
    assert contract.status == ContractStatus.ACTIVE

# ② 実装（状態遷移ルールを service に書く）
# ③ GREEN
```

### パターン 4: API エンドポイント（integration テスト）

```python
# ① RED: エンドポイントの仕様を先に書く
# tests/backend/integration/test_invoice_api.py
async def test_create_invoice_returns_201(client, sample_store):
    """POST /api/billing/invoices は 201 を返す"""
    payload = {"store_id": str(sample_store.store_id), "amount": 1000}
    response = await client.post("/api/billing/invoices", json=payload)
    assert response.status_code == 201
    assert "invoice_id" in response.json()

# PYTHONPATH=apps/backend pytest tests/backend/integration/test_invoice_api.py -v
# → FAILED (404 or error)

# ② 実装（route, service, repository を追加）
# ③ GREEN
```

### パターン 5: parametrize で複数ケース

```python
import pytest

@pytest.mark.parametrize("amount,rate,expected", [
    (1000, 0.1, 100),
    (5000, 0.05, 250),
    (0, 0.1, 0),
])
def test_calculate_fee_parametrized(amount, rate, expected):
    assert calculate_fee(amount, rate) == expected
```

---

## Vitest（Frontend）

### テスト配置

```
tests/frontend/
├── unit/
│   └── xxx.test.ts(x)
└── e2e/
    └── xxx.spec.ts
```

`apps/frontend/package.json` の `test:unit` script は `vitest run ../../tests/frontend/unit` を実行する（Makefile `test-frontend` ターゲットから呼び出される）。

### コマンド

| 用途 | コマンド |
|------|---------|
| 全テスト実行 | `make test-frontend` |
| 全テスト実行（npm 直接） | `cd apps/frontend && npm run test:unit` |
| 特定ファイル | `cd apps/frontend && npx vitest run ../../tests/frontend/unit/xxx.test.ts` |
| ウォッチモード（開発中） | `cd apps/frontend && npx vitest` |

### import 方針

`globals: true` は使用しない前提とし、各テストファイルで vitest を明示 import する:

```typescript
import { describe, it, expect, beforeEach } from "vitest"
```

理由: `tsc --noEmit` との衝突を回避。

### RED-GREEN サイクル例（Zod スキーマ変更）

```typescript
// ① RED: 新しいバリデーションルールのテストを先に書く
// tests/frontend/unit/createApplicationSchema.test.ts
import { describe, it, expect } from "vitest"
import { createApplicationSchema } from "@/lib/validations/application"

describe("createApplicationSchema", () => {
  it("rejects phone without country code", () => {
    const schema = createApplicationSchema()
    const result = schema.safeParse({
      // ... required fields ...
      phone: "+8109012345678",  // ← 新ルール: 国番号不可
    })
    expect(result.success).toBe(false)  // ← まだ FAIL する
  })
})

// make test-frontend → FAILED

// ② 実装: PHONE_REGEX を更新
// ③ GREEN: make test-frontend → PASSED
```

### Zustand store テストパターン

```typescript
import { describe, it, expect, beforeEach } from "vitest"
import { useXxxStore } from "@/store/xxxStore"

describe("useXxxStore", () => {
  beforeEach(() => {
    useXxxStore.setState({ /* initial state */ })
  })

  it("action updates state correctly", () => {
    useXxxStore.getState().someAction("value")
    expect(useXxxStore.getState().someField).toBe("value")
  })
})
```

### よくある失敗パターン（Vitest）

| 症状 | 原因 | 対処 |
|------|------|------|
| `No test files found` | `include` パターンと不一致 | `tests/frontend/unit/**/*.test.ts(x)` に配置する |
| `Cannot find module '@/...'` | path alias が解決できない | `vitest.config.ts` の path alias 設定を確認 |
| 型エラー（`describe` is not defined） | `globals: true` 不使用のため | `import { describe, it, expect } from "vitest"` を追加 |

---

## 証跡記録

`/develop` Phase 5 の実装サマリー（`.claude/templates/implementation-summary-comment.md`）に以下を記録する。

```markdown
### TDD 証跡
| 項目 | 内容 |
|------|------|
| TDD 判定 | 必須 / スキップ（理由: ）|
| 追加したテスト | `tests/backend/unit/test_xxx.py::test_function_name` |
| RED コマンド | `PYTHONPATH=apps/backend pytest tests/backend/unit/test_xxx.py -v` |
| RED 結果 | FAILED: 1 failed, 0 passed（AssertionError: ...）|
| GREEN コマンド | `PYTHONPATH=apps/backend pytest tests/backend/unit/test_xxx.py -v` |
| GREEN 結果 | PASSED: 1 passed |
```

**スキップの場合:**

```markdown
### TDD 証跡
| 項目 | 内容 |
|------|------|
| TDD 判定 | スキップ（理由: .claude/ ファイルのみの変更。コード変更なし）|
| 追加したテスト | なし |
| RED コマンド | なし |
| GREEN コマンド | なし |
```

---

## よくある失敗パターン

| 症状 | 原因 | 対処 |
|------|------|------|
| `0 selected` | path 指定ミス（存在しない glob / 誤った filename） | `tests/backend/unit/test_xxx.py` を絶対 / 相対パスで正確に指定 |
| `all skipped` | `@pytest.mark.skip` / `xfail` が残っている | skip マーカーを確認して削除 |
| `ImportError` in RED | 実装前にテストを書いたため | 正常な RED（次のステップで実装する） |
| RED で PASS になる | テストが正しい振る舞いを定義できていない | テストの期待値を確認する |
| GREEN にならない | 実装が不足している | エラーメッセージを読んで追加実装する |

---

## 棲み分け: testing-patterns / verification-before-completion との違い

| スキル | 担当範囲 |
|--------|---------|
| **tdd-workflow**（本スキル） | RED-GREEN フロー、TDD パターン集、証跡フォーマット |
| **testing-patterns** | DB フィクスチャ設計、CI 共有 DB 問題回避、テストファイル構成 |
| **verification-before-completion** | 完了主張前の 5 ステップゲート（IDENTIFY / RUN / READ / VERIFY / CLAIM） |
| **test-design** | Critical Path 判定・保護レイヤー選択・Coverage expectation |
| **rules/tdd-gate.md** | TDD 必須 / スキップ判定の SSOT |

統合テストで DB が必要な場合は `testing-patterns` も参照する。

---

## 証跡チェーン

TDD 証跡は以下の順で引き継がれる。切れた場合は `/pr` でブロックされる。

```
/plan 検証定義
  └─ TDD 判定 + 想定 RED/GREEN コマンド

/tdd RED 証跡（Issue コメント ← gh issue comment で投稿）
  └─ TDD 判定 + 追加テスト + RED コマンド + RED 結果

/develop 実装サマリー（implementation-summary-comment.md）
  └─ TDD 証跡テーブル（追加テスト / RED / GREEN）

/verify 検証結果コメント（verification-result-comment.md）
  └─ TDD 証跡テーブル（/develop から転記 + 再確認結果）

/pr PR ゲート
  └─ TDD 証跡の有無を確認（ブラウザ確認と同等のゲート）
```

> **重要**: `/tdd` の RED 証跡は **必ず Issue コメントに投稿**する。会話内のテキスト出力だけではセッション間で失われ、`/develop` が証跡を確認できなくなる。

---

## 関連ファイル

### プロジェクト内参照

- [rules/tdd-gate.md](../../rules/tdd-gate.md) - TDD 判断基準（必須/スキップ + Critical Path 連携）
- [skills/test-design/SKILL.md](../test-design/SKILL.md) - Critical Path 判定・保護レイヤー
- [skills/verification-before-completion/SKILL.md](../verification-before-completion/SKILL.md) - 完了主張前のゲート
- [skills/testing-patterns/SKILL.md](../testing-patterns/SKILL.md) - DB フィクスチャ
- [apps/backend/pytest.ini](../../../apps/backend/pytest.ini) - pytest 設定（marker は `tc_id` のみ）
- [templates/implementation-summary-comment.md](../../templates/implementation-summary-comment.md) - TDD 証跡テーブル

### 公式ドキュメント・外部リファレンス

- [pytest 公式ドキュメント](https://docs.pytest.org/)
- [pytest-asyncio ドキュメント](https://pytest-asyncio.readthedocs.io/)
- [pytest parametrize](https://docs.pytest.org/en/latest/how-to/parametrize.html)
- [Vitest 公式](https://vitest.dev/)
