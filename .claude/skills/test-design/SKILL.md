---
name: test-design
description: |
  テスト設計スキル。Critical Path 判定・保護レイヤー選択・Coverage expectation の判断基準を提供。
  `/plan` Phase 1.3（Critical Path 判定）で Critical または Mixed と判定された Issue で追加読込される。
---

# テスト設計スキル

## 概要

`/plan` の成果物として test design を decision-complete にするためのスキル。
高リスク Issue で「何を守るか」「どの層で守るか」「どこまで守るか」を迷わず決められる判断基準を提供する。

> **本リポジトリの pytest marker は `tc_id` のみ**（`apps/backend/pytest.ini` 参照）。SubsCore 由来の `unit` / `integration` / `integration_local` marker は本リポジトリでは適用しない。テスト種別はディレクトリ配置（`tests/backend/{unit,integration}/`、`tests/frontend/{unit,e2e}/`）で分類する。

## 非ゴール（このスキルが扱わないもの）

| 扱わない内容 | 担当スキル |
|-------------|-----------|
| fixture / DB 共有ルール | [testing-patterns](../testing-patterns/SKILL.md) |
| RED-GREEN 実行手順・証跡記録 | [tdd-workflow](../tdd-workflow/SKILL.md) |
| TDD 必須 / スキップ判定の SSOT | [rules/tdd-gate.md](../../rules/tdd-gate.md) |
| 完了主張前の検証ゲート | [verification-before-completion](../verification-before-completion/SKILL.md) |

---

## 使い方

### いつ読み込むか

`/plan` Phase 1.2（依存先トレース）完了後に Critical Path 判定を行い、**Critical または Mixed** と判定された場合にこのスキルを追加読込する。

Non-critical の場合はこのスキルは不要。既存の Critical Path テーブルを埋めるだけで十分。

### 読み込みフロー

```
/plan Phase 1.2 完了
  ↓
Critical Path 判定（下記の判定基準で評価）
  ↓
Critical or Mixed → このスキルを読み込む
Non-critical     → スキップ（既存テーブルを埋めるだけ）
```

---

## 詳細

### 1. Critical Path 判定基準

Issue の変更対象を以下の基準で判定する。

#### Critical（全テスト層で保護が必要）

以下の **いずれか** に該当する場合は Critical:

| 領域 | 例 |
|------|-----|
| 申込導線（フォーム → 確認 → 決済 → 完了） | 申込フォーム、カード登録、決済処理 |
| auth / 権限（JWT 検証、ロールチェック） | ログイン、トークンリフレッシュ、権限ガード |
| billing / payment / 契約の状態遷移 | 契約作成、請求書発行、決済フロー |
| callback を含む整合性境界 | 外部決済結果通知、Webhook、OAuth callback |
| 外部連携の冪等性・排他制御 | 二重課金防止、外部 API リトライ |

#### Non-critical（標準テストで十分）

以下の **すべて** に該当する場合は Non-critical:

- 状態遷移を含まない
- 外部連携・callback がない
- auth / 権限に影響しない
- 申込導線に影響しない

例: UI 文言修正、CSS 調整、管理画面の表示改善、DX ツーリング

#### Mixed（Critical + Non-critical が混在）

Issue に Critical と Non-critical の両方が含まれる場合。
Critical 部分は Critical の保護レイヤー、Non-critical 部分は標準テストで保護する。

### 2. 保護レイヤー選択ガイド

判定結果に応じて、どのテスト層で保護するかを選択する。

| レイヤー | 何を保護するか | いつ使うか | コマンド例 |
|---------|--------------|-----------|-----------|
| **Unit** | ドメインロジック、計算、バリデーション | ビジネスルール・状態遷移のロジックテスト | `make test-backend`（全実行）/ focused: `PYTHONPATH=apps/backend pytest tests/backend/unit/test_xxx.py -v` |
| **Integration** | DB / API / 外部連携の結合 | Repository、API エンドポイント、ミドルウェア | `make test-backend`（全実行）/ focused: `PYTHONPATH=apps/backend pytest tests/backend/integration/test_xxx.py -v` |
| **Browser evidence** | 実画面の表示・操作・Console / Network | UI 導線、レスポンシブ、エラー表示 | `/verify` 軽量ヘルスチェック（ローカル、pre-merge） |
| **Manual** | 自動化困難な確認 | 外部リダイレクト、サンドボックス決済、印刷 | 手動実行 + 証跡スクリーンショット |

#### Critical Path での推奨組み合わせ

| Critical 領域 | Unit | Integration | Browser | Manual |
|:-------------|:----:|:-----------:|:-------:|:------:|
| 申込導線 | o | o | o | - |
| auth / 権限 | o | o | - | - |
| billing 状態遷移 | o | o | - | - |
| callback 整合性 | o | o | - | o |
| 外部連携冪等性 | o | o | - | o |

`o` = 必須、`-` = 不要

### 3. Coverage expectation ルール

| 判定 | Coverage expectation |
|------|---------------------|
| **Critical** | Critical scope = 100%（全パス・全境界をテストで保護） |
| **Non-critical** | Touched scope = 90%（変更した範囲の主要パスを保護） |
| **Mixed** | Critical 部分 = 100% + Touched non-critical = 90% |
| **N/A** | DX / `.claude/` のみの変更、Pencil 調整のみ、文言修正のみ |

#### Touched scope の定義

「Touched scope」とは、この Issue で **新規作成または変更したコード** のうち、テスト可能な部分を指す。

含まれるもの:
- 新規作成した関数・メソッド・クラス
- 変更したビジネスロジック
- 追加・変更した API エンドポイント
- 変更した DB クエリ・リポジトリメソッド

含まれないもの:
- import 文の追加・変更
- 型定義のみの変更
- 設定ファイル（`.env`, `config.py` 等）
- テンプレート・静的ファイル

#### N/A 条件

N/A は独立した分類ではなく、**テスト可能な実行コードが存在しない場合に Non-critical に対して使う例外**。Critical / Mixed の Issue では N/A を選択できない。

以下の **いずれか** に該当する場合、Coverage expectation は N/A:

- `.claude/` / `docs/` / `.github/` のみの変更（テスト可能な実行コードがない）
- Pencil 調整のみの変更（デザイン変更のみ、ロジック変更なし）
- UI の文言・CSS のみの変更（表示テキストやスタイルのみ、ロジック変更なし）

> **注意**: `scripts/` 配下の Python スクリプト等、テスト可能な実行コードを含む変更は N/A ではなく Non-critical（90%）を選択すること。

### 4. Focused test commands テンプレート

`/plan` の検証定義に記載する focused test commands の例:

```bash
# Critical: billing 状態遷移
PYTHONPATH=apps/backend pytest tests/backend/unit/test_invoice_service.py -v
PYTHONPATH=apps/backend pytest tests/backend/integration/test_invoice_api.py -v

# Critical: auth
PYTHONPATH=apps/backend pytest tests/backend/unit/test_auth.py -v

# Non-critical: touched scope（変更したファイルに紐づく test を focused で）
PYTHONPATH=apps/backend pytest tests/backend/unit/test_<changed_file>.py -v

# Frontend
cd apps/frontend && npx vitest run ../../tests/frontend/unit/<changed_module>.test.ts
```

### 5. フロントエンドの保護レイヤー分担

フロントエンドの品質は以下の 3 層で保護する。E2E（Playwright）の CI 回帰自動化は本リポジトリでは現時点では未採用。

| レイヤー | 担当 | 検知対象 |
|---------|------|---------|
| **CI build** | `make test-frontend`（`npm run lint:biome` + `check:segments` + `test:unit`） | compile エラー、型エラー、Vitest unit テスト |
| **Browser evidence** | `/verify` 軽量ヘルスチェック（ローカル） | runtime エラー、Console / Network、UI 表示、状態遷移 |
| **Backend integration** | `make test-backend` の integration テスト | API 正当性、DB 整合性、callback 処理 |

> **将来の再検討**: 申込導線の大規模改修や、build では検知できない回帰が頻発した場合に E2E（Playwright）導入を再検討する。

---

## `/plan` での出力形式

このスキルを読み込んだ場合、`/plan` の検証定義（`.claude/templates/issue-implementation-plan.md` の Critical Path セクション）に以下を必ず含める:

```markdown
### Critical Path / Coverage expectation

| 項目 | 内容 |
|------|------|
| Critical Path 判定 | Critical / Non-critical / Mixed |
| Critical scope | [Critical と判定した領域を列挙] |
| 保護レイヤー | Unit / Integration / Browser evidence / Manual |
| Coverage expectation | Critical = 100% / Touched non-critical = 90% / N/A |
| Focused test commands | [具体的なコマンドを列挙] |
```

---

## 関連ファイル

- [testing-patterns/SKILL.md](../testing-patterns/SKILL.md) - fixture / DB 共有ルール
- [tdd-workflow/SKILL.md](../tdd-workflow/SKILL.md) - RED-GREEN 実行手順
- [verification-before-completion/SKILL.md](../verification-before-completion/SKILL.md) - 完了主張前のゲート
- [rules/tdd-gate.md](../../rules/tdd-gate.md) - TDD 必須 / スキップ判定 SSOT
- [templates/issue-implementation-plan.md](../../templates/issue-implementation-plan.md) - 検証定義テンプレート
