# Planning Quality - 計画立案品質ルール

Issue 実装計画の **構造 SSOT** は [`.claude/templates/issue-implementation-plan.md`](../templates/issue-implementation-plan.md) に集約されています。本ファイルは `/plan` が遵守する **コア原則** と **フェーズ構成** のみを定義します。

## コア原則

1. **リサーチ必須**: 公式ドキュメント・ベストプラクティスを調査し、参照リンクを Issue 本文（`📚 リサーチ結果`）に記録する
2. **縦スライス遵守**: 1 Issue = 1 つのドメイン概念で完結させる。サイズ上限を超える場合は分割（[`issue-sizing.md`](./issue-sizing.md)）
3. **トレーサビリティ必須**: 関連する BR/UC/SR/API/TC の ID と DocDD 更新要否を 7 軸テーブルに記入する（[`docdd-frontmatter.md`](./docdd-frontmatter.md)）

## `/plan` フェーズの役割

| Phase | 役割 | 参照 |
|-------|------|------|
| 0 | Issue ステータス確認 | [`commands/plan.md`](../commands/plan.md) Phase 0 |
| 1 | 理解・適用スキル選択 | [`skills/README.md`](../skills/README.md) |
| 1.2 | 依存先・呼び出し元トレース | テンプレ「依存先・波及範囲」 |
| 1.2.5 | 証跡マッピング表 + UI State Matrix | テンプレ該当節 |
| 1.3 | Critical Path 判定 | テンプレ「Critical Path / Coverage expectation」 |
| 1.5 | UI 設計確認（UI 変更時） | [`project-workflow.md`](./project-workflow.md) |
| 1.6 | サイズチェック | [`issue-sizing.md`](./issue-sizing.md) |
| 2 | ユーザー相談 | — |
| 3 | リサーチ | [`agent-teams.md`](./agent-teams.md) |
| 4 | Issue 本文更新（テンプレ反映） | テンプレ全体 |
| 5 | Codex 計画レビュー | [`codex-review.md`](./codex-review.md) |

## 旧コンテンツ移植判断（Issue #51 T2 記録）

旧ファイルにあった「アンチパターン / OK 例」（曖昧な計画 vs 具体的な計画の例示）の扱い:

- **判断**: 削除
- **理由**: テンプレ側のセクション構造（影響範囲 / 実装タスク / 検証定義 / TDD 判定 / Critical Path）が「具体的な計画」の構造を強制しており、OK 例は冗長。`/plan` Phase 4 がテンプレ heading を literal に反映するため、抽象論で書く余地がない
- **代替**: テンプレ自体が「OK 例」として機能する。実例は Closed Issue（gh issue list --state closed --label '実装計画'）を参照

## 関連

- [`.claude/templates/issue-implementation-plan.md`](../templates/issue-implementation-plan.md) — 構造 SSOT
- [`.claude/commands/plan.md`](../commands/plan.md) — `/plan` 手順 SSOT
- [`issue-sizing.md`](./issue-sizing.md) — サイズ上限・縦スライス原則
- [`codex-review.md`](./codex-review.md) — Codex CLI レビュー運用
