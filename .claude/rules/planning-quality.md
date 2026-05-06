# Planning Quality - 計画立案品質ルール

> **本ファイルは薄いポインタ**です。実体は以下に集約されています:
>
> - **品質基準 SSOT**: [`.claude/skills/planning-quality/SKILL.md`](../skills/planning-quality/SKILL.md)（リサーチ・依存先トレース・観点別チェック・DocDD 更新要否・サイズチェック・Codex レビュー）
> - **構造 SSOT**: [`.claude/templates/issue-implementation-plan.md`](../templates/issue-implementation-plan.md)（Issue 本文の heading 順序・セクション構成）

## コア原則

1. **リサーチ必須**: 公式ドキュメント・ベストプラクティスを調査し、参照リンクを Issue 本文（`📚 リサーチ結果`）に記録する
2. **縦スライス遵守**: 1 Issue = 1 つのドメイン概念で完結させる。サイズ上限を超える場合は分割（[`issue-sizing.md`](./issue-sizing.md) → [`skills/issue-sizing`](../skills/issue-sizing/SKILL.md)）
3. **トレーサビリティ必須**: 関連する BR/UC/SR/API/TC の ID と DocDD 更新要否を 7 軸テーブルに記入する（[`docdd-frontmatter.md`](./docdd-frontmatter.md)）

## `/plan` フェーズの役割（参照早見表）

| Phase | 役割 | 参照 |
|-------|------|------|
| 0 | Issue ステータス確認 | [`commands/plan.md`](../commands/plan.md) Phase 0 |
| 1 | 理解・適用スキル選択 | [`references/applicable-skills.md`](../references/applicable-skills.md) |
| 1.2 | 依存先・呼び出し元トレース | テンプレ「依存先・波及範囲」 |
| 1.2.5 | 証跡マッピング表 + UI State Matrix | テンプレ該当節 |
| 1.3 | Critical Path 判定 | テンプレ「Critical Path / Coverage expectation」 |
| 1.5 | UI 設計確認（UI 変更時） | [`project-workflow.md`](./project-workflow.md) |
| 1.6 | サイズチェック | [`skills/issue-sizing`](../skills/issue-sizing/SKILL.md) |
| 2 | ユーザー相談 | — |
| 3 | リサーチ | [`skills/agent-teams`](../skills/agent-teams/SKILL.md) |
| 4 | Issue 本文更新（テンプレ反映） | テンプレ全体 |
| 5 | Codex 計画レビュー | [`codex-review.md`](./codex-review.md) |

## 関連

- [`.claude/skills/planning-quality/SKILL.md`](../skills/planning-quality/SKILL.md) — 品質基準 SSOT
- [`.claude/templates/issue-implementation-plan.md`](../templates/issue-implementation-plan.md) — 構造 SSOT
- [`.claude/commands/plan.md`](../commands/plan.md) — `/plan` 手順 SSOT
- [`issue-sizing.md`](./issue-sizing.md) — サイズ上限・縦スライス原則（→ [`skills/issue-sizing`](../skills/issue-sizing/SKILL.md)）
- [`codex-review.md`](./codex-review.md) — Codex CLI レビュー運用
