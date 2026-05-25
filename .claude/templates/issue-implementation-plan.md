# Issue 実装計画テンプレート

`/plan` Phase 4 が Issue 本文に追記するテンプレート。元の Issue 本文（背景・目的・スコープ・受け入れ条件）はそのまま残し、以下を追記する。

## セクション構造インデックス

| 区分 | 由来 | 編集主体 | 備考 |
|------|------|---------|------|
| `## 背景` / `## 目的` / `## Brainstorm 結論` / `## スコープ` / `## 受け入れ条件` | 元 Issue 本文（`/issue` で記入） | ユーザー | `/plan` は**保全**する（書き換え禁止） |
| `## 📚 リサーチ結果` 〜 `## ✅ 完了条件` | `/plan` Phase 4 が下記コードフェンスに従って追記 | プランナー | heading 順序・必須項目を**そのまま反映** |
| `## 📋 後続 Issue で導入予定（forward reference の隔離）` | `/plan` Phase 4 が末尾に追加（任意） | プランナー | 未存在 path への参照を末尾に隔離 |

> **heading 反映ルール**: `/plan` Phase 4 はコードフェンス内の `## ` heading 順序を Issue 本文へ literal に反映する。HTML コメント（`<!-- ... -->`）で埋め込まれた条件付き表示ガイダンスは Issue 本文に出さず、プランナーの判断材料として用いる。

```markdown
---

## 📚 リサーチ結果
[調査した公式ドキュメント、ベストプラクティス、参考実装]

## 🎯 影響範囲
[変更対象ファイル、依存関係、副作用]

### 依存先・波及範囲
変更起点から下流まで、少なくとも以下を表で明記する。

| 変更起点 | 波及先 | 確認内容 |
|---------|--------|---------|
| path/to/source | path/to/consumer | request/response/state/route の整合性 |

### 非対象だが影響確認が必要な箇所
- [このIssueでは直接実装しないが、壊していないことを確認すべき画面・API・導線]

### 📄 DocDD更新対象
変更対象から逆引きして、更新が必要な DocDD ドキュメントを特定する。

| 変更レイヤー | 確認先 | 更新要否 |
|------------|--------|:--------:|
| API層（FastAPI routes） | `docs/7-axis/6_API/` の該当 yaml | ✅/— |
| Model/Schema層 | `docs/7-axis/3_DM/` の該当 DM-*.md | ✅/— |
| Service層（ビジネスルール変更） | `docs/7-axis/4_SR/` の該当 SR-*.md | ✅/— |
| UseCase / Flow変更 | `docs/7-axis/2_UC/` の該当 UC-*.md | ✅/— |
| TC / traceability | `docs/7-axis/7_TC/` + `docs/testing/traceability/` | ✅/— |

## 🗺️ 証跡マッピング表

<!-- 全行チェック方式: 全行コピーし、該当行に ✅ + 対象パス/理由、非該当行に — を記入する -->

| 変更パス | 証跡カテゴリ | 必須証跡 | 自動検知 | 該当 | 対象パス/理由 |
|---------|------------|---------|:--------:|:----:|-------------|
| `apps/backend/app/modules/**/domain/**`, `apps/backend/app/modules/**/services/**` | backend-unit | ユニットテスト（pytest） | make test-backend | | |
| `apps/backend/app/modules/**/infrastructure/**` | backend-integration | 統合テスト（DB/外部連携） | make test-backend | | |
| `apps/backend/app/modules/**/presentation/**`, `apps/backend/app/shared/**/routes.py` | api-route | 統合テスト + API仕様書(6_API)更新 + caller全件確認 | make test-backend + 手動 | | |
| `apps/backend/app/**/schemas/**`, `apps/frontend/**/_types/**` | api-contract | Frontend 型一致確認 | 手動 | | |
| `apps/backend/app/kernel/**` | backend-core | ユニットテスト + 動作確認 | make test-backend + 手動 | | |
| `apps/backend/alembic/versions/**` | migration-safety | up/down/up サイクル | CI | | |
| `apps/frontend/app/**/page.tsx`, `apps/frontend/app/**/layout.tsx`, `apps/frontend/app/**/_containers/**`, `apps/frontend/app/**/_components/**`, `apps/frontend/src/components/**` | frontend-ui | Vitest OR ブラウザ目視 | make test-frontend / 手動 | | |
| `apps/frontend/app/**/_hooks/**`, `apps/frontend/app/**/_lib/**` | frontend-logic | Vitest テスト必須 | make test-frontend | | |
| `apps/frontend/src/lib/**`, `apps/frontend/src/store/**`, `apps/frontend/src/hooks/**` | frontend-shared | Vitest テスト必須 | make test-frontend | | |
| `apps/frontend/app/**/globals.css`, `apps/frontend/tailwind.config.*`, `apps/frontend/postcss.config.*` | frontend-style | ブラウザ目視 | 手動 | | |
| `docs/7-axis/**`, `docs/testing/traceability/**` | docdd | frontmatter + traceability | make traceability | | |
| `scripts/**`, `Makefile*`, `*.config.*`, `.claude/hooks/**`, `.claude/settings.json`, `.github/**`, `terraform/**` | dx-config | 動作確認 + 既存テスト非破壊 | 手動 | | |
| `.claude/commands/**`, `.claude/rules/**`, `.claude/skills/**`, `.claude/templates/**`, `.claude/references/**` | dx-docs | validate-claude + 目視確認 | make validate-claude | | |

## 🖥️ UI State Matrix

<!-- 適用条件: apps/frontend/app/**/page.tsx, apps/frontend/app/**/layout.tsx, apps/frontend/app/**/_containers/**, apps/frontend/app/**/_components/**, apps/frontend/src/components/** のいずれかを変更する場合に記入する。非該当なら「UI 変更なし — 適用外」と記載 -->
<!-- N/A 可。ただし理由必須（例: N/A — 一覧ページのため送信中状態なし） -->

| 状態 | トリガー | 期待 UI | 検証方法 | 該当 | 備考 |
|------|---------|--------|:--------:|:----:|------|
| Loading（初期表示） | データ初回フェッチ中 | Skeleton / Spinner | ブラウザ | | |
| Loading（送信中） | フォーム送信 / アクション実行中 | ボタン disabled + 「処理中...」 | ブラウザ | | |
| Empty（フィルタなし） | データ 0 件 | 「まだ○○がありません」 | ブラウザ | | |
| Empty（フィルタあり） | 検索結果 0 件 | 「該当する○○がありません」 | ブラウザ | | |
| Error（API / ネットワーク） | API 5xx / ネットワーク障害 | エラーメッセージ表示 | ブラウザ | | |
| Error（バリデーション / ビジネスルール） | 入力不正 / 無効・期限切れ / ルール違反 | フィールドエラー or メッセージ | ブラウザ | | |
| Success | 正常データ | 主導線の正常表示 | ブラウザ | | |
| 権限なし | 権限不足 | 403 ページ or メッセージ | ブラウザ | | |
| Route resilience | Reload / Back / URL欠落 | 状態復元 or 適切なフォールバック | ブラウザ | | |

## 📏 サイズチェック

<!-- 超過時ガイダンス: 2 つ以上 ❌ の場合は計画を確定せず、ユーザーに分割案を提示する。
  分割の方針: ドメイン概念ごとの縦スライスを優先（.claude/rules/issue-sizing.md「縦スライスの原則」参照）。
  分割案を提示する場合は、本表の直後に「## 🪓 分割提案」セクションを追加し、子 Issue 候補を列挙する -->

| 指標 | 値 | 上限 | 判定 |
|------|:--:|:----:|:----:|
| 変更対象ファイル | ? | 20 | |
| 実装タスク数 | ? | 8 | |
| 起因 Issue / 負債 | ? | 1 | |
| Phase 数 | ? | 1 | |
| API/型の契約変更点 | ? | 3 | |
| 下流呼び出し元数 | ? | 5 | |

> 詳細: `.claude/rules/issue-sizing.md`

## ⚠️ 重要ポイント
[特に注意が必要な箇所 - 🔴Critical / 🟠High / 🟡Medium / 🟢Low]

## 🚨 リスク・注意点

<!-- ⚠️ 重要ポイントとの違い: 「⚠️ 重要ポイント」は実装時の注意フラグ（粒度: 1 行の指摘）。
  「🚨 リスク・注意点」は壊れたら困る箇所への対策（粒度: 影響範囲 + 対策 + ロールバック）。
  N/A 可（例: ドキュメント整備のみで壊れる対象がない場合）。N/A の場合は理由を明記 -->

### 既存機能への影響

| リスク | 影響範囲 | 対策 |
|---|---|---|
| [リスク1の概要] | [影響を受ける画面 / API / DB] | [リスクを抑える具体策] |

### 移行手順（既存 Issue / 既存実装に対して）

- [遡及書き換えが必要な範囲を列挙、なければ「該当なし」と記載]
- [移行が必要な場合は段階的ステップを記述]

### ロールバック方法

- [revert 手順 / feature flag / 段階的リリース等]

## 📋 実装タスク
- [ ] タスク1
- [ ] タスク2
- [ ] タスク3

## ✅ 検証定義

| ID | 対象/観点 | コマンド/操作 | 期待結果 | PASS条件 | 備考/証跡 |
|----|----------|-------------|---------|---------|---------|
| V1 | frontmatter validator | `make validate-claude` | 全 PASS（warning は許容） | exit 0 | baseline モード |
| V2 | traceability | `make traceability` | sample_map.json 整合 | exit 0 | DocDD 変更時に必須 |

### TDD 判定（/develop 実装前に記録する）

<!-- 条件付き表示ロジック:
  - TDD 必須の場合: 「想定 RED コマンド」「想定 GREEN コマンド」に focused pytest / vitest コマンドを具体値で記入する
  - TDD スキップの場合: 「想定 RED コマンド」「想定 GREEN コマンド」に「該当なし」と書く（空欄禁止）
  - 空欄禁止: 必須 / スキップ（理由）のどちらかを記載すること。空欄 = 証跡漏れとして扱う -->

| 項目 | 内容 |
|------|------|
| TDD 判定 | 必須 / スキップ（理由: ）|
| 対象領域 | Backend service / API 契約変更 / Frontend pure logic / 認証 / 状態遷移 / バグ修正 / 該当なし |
| 想定 RED コマンド | `make test-backend` / `make test-frontend` または focused pytest / vitest コマンド（スキップ時は「該当なし」） |
| 想定 GREEN コマンド | `make test-backend` / `make test-frontend` または focused pytest / vitest コマンド（スキップ時は「該当なし」） |

> **判断基準 SSOT**: [`.claude/rules/tdd-gate.md`](../rules/tdd-gate.md)（必須領域・スキップ条件・Critical Path 連携）。RED-GREEN サイクル・パターン集・証跡フォーマットは [`.claude/skills/tdd-workflow/SKILL.md`](../skills/tdd-workflow/SKILL.md) を参照。

### Critical Path / Coverage expectation

<!-- 判定基準・保護レイヤー選択・Coverage expectation の SSOT は .claude/skills/test-design/SKILL.md。
  Critical / Mixed と判定した場合は同 skill を Read してから保護レイヤーと Focused test commands を埋める。
  簡易リファレンス:
    Critical Path 判定（3 値）:
      Critical: 状態遷移・外部連携・callback・認証・申込導線を含む
      Non-critical: 上記に該当しない（UI文言、CSS、DX等）
      Mixed: Critical + Non-critical が混在
    Coverage expectation の N/A 条件（Non-critical で実行コードを含まない場合の例外）:
      .claude/ / docs/ のみの変更、デザイン調整のみ、文言修正のみ
      → Critical / Mixed では N/A を選択不可
-->

| 項目 | 内容 |
|------|------|
| Critical Path 判定 | Critical / Non-critical / Mixed |
| Critical scope | Critical と判定した領域を列挙（Non-critical の場合は「なし」） |
| 保護レイヤー | Unit / Integration / Browser evidence / Manual |
| Coverage expectation | Critical = 100% / Non-critical touched scope = 90% / Mixed = critical 100% + touched non-critical 90% / N/A（Non-critical で実行コードなしの場合のみ） |
| Focused test commands | /plan の計画から転記 |

> **判定 SSOT**: [`.claude/skills/test-design/SKILL.md`](../skills/test-design/SKILL.md)（保護レイヤー選択 / Coverage expectation の詳細表）

### Issue 固有の検証定義

| ID | 対象/観点 | コマンド/操作 | 期待結果 | PASS条件 | 備考/証跡 |
|----|----------|-------------|---------|---------|---------|
| V3 | [対象] | [コマンド or 操作手順] | [期待する出力・状態] | [合否の判定基準] | [証跡URL・コマンド結果] |

## 🔗 参照スキル
- backend-patterns
- frontend-patterns
- testing-patterns
- docdd-workflow
- design

> 一覧: `.claude/skills/README.md`

## 📖 参照ドキュメント

### プロジェクト内
- [関連するプロジェクト内ドキュメントへのリンク]

### 外部リファレンス
- [調査した公式ドキュメント、ベストプラクティス記事へのリンク]
- [参考にしたGitHubリポジトリ、技術ブログ等]

## 🔄 後続Issue（必要な場合）
[Phase 1 で確認した既存Issueを踏まえ、後続作業の方針を記載]

判断結果:
- [ ] 既存Issue #XXX に統合 / 新規Issue #XXX を作成 / 後続なし

> 判断基準: PR差分300行以下なら統合OK。既存の関連Issueがあればそちらに統合を優先。

**本Issue完了後に作成する後続Issue:**
- [ ] 後続Issue-X: [内容]（なければ「後続なし」と記載）

## ✅ 完了条件
- [ ] 全テストがパス（`make test` または変更レイヤー対応の `make test-backend` / `make test-frontend`）
- [ ] `make validate-claude` PASS
- [ ] DocDD 更新が必要な場合は `make traceability` PASS
- [ ] レビュー承認

（ADRセクション - アーキテクチャ決定がある場合）
（DocDD 7軸セクション - 新機能の場合）
```

> 3 ブロック trailer は `.claude/rules/command-trailer.md` 参照（`/develop` 〜 `/merge` の trailer 出力 SSOT）。

---

## 📋 後続 Issue で導入予定（forward reference の隔離）

> 本テンプレートに含まれる検証定義表は最小構成。下記の項目は後続 Issue で skill / script として整備予定。本 Issue の `/plan` 段階では既存 rule のみを参照する。

| 参照先（未存在） | 用途 | 予定 Issue |
|--------------|------|----------|
| `scripts/claude/verify-issue.sh`, `scripts/claude/quality-gate.sh` | Issue 単位の品質ゲート自動化 | 後続 Issue（5-1 / D-1 想定） |
| `.claude/rules/multi-model-review.md` | 3 reviewer 並列レビュー | 後続 Issue（D-1 想定） |
