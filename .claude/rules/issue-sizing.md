# Issue サイジングルール

> **本ファイルは薄いポインタ**です。実体は [`.claude/skills/issue-sizing/SKILL.md`](../skills/issue-sizing/SKILL.md) に集約されています。

## 基本原則

**1 Issue = 1 PR でレビュー可能なサイズに収める。**

Issue は「縦スライス」（1つの機能・概念が完結する単位）で切る。
「横スライス」（1レイヤーをまとめて対応）や「負債まとめて返済」は禁止。

## サイズ上限（早見表）

| 指標 | 上限 |
|------|:----:|
| 変更対象ファイル | **20ファイル** |
| 実装タスク数 | **8タスク** |
| 起因 Issue / 負債 | **1つ** |
| Phase 数 | **1** |

詳細・分割判断フロー・負債返済の進め方・Umbrella / 観察集約パターン・例外規定はすべて [`.claude/skills/issue-sizing/SKILL.md`](../skills/issue-sizing/SKILL.md) を参照してください。

## 関連

- [`.claude/skills/issue-sizing/SKILL.md`](../skills/issue-sizing/SKILL.md) — サイジング SSOT（縦スライス原則・分割フロー・Umbrella / 観察集約パターン）
- [`planning-quality.md`](./planning-quality.md) → [`.claude/skills/planning-quality/SKILL.md`](../skills/planning-quality/SKILL.md) — 計画品質ルール
- [`issue-workflow.md`](./issue-workflow.md) — Issue 駆動開発フロー
- [`project-workflow.md`](./project-workflow.md) — GitHub Projects 運用ルール
