# Agent Teams - エージェントチーム運用ルール

> **本ファイルは薄いポインタ**です。実体は [`.claude/skills/agent-teams/SKILL.md`](../skills/agent-teams/SKILL.md) に集約されています。

## 基本原則

Claude Code のエージェントチーム機能を活用し、**議論・検証・並列作業**で品質と効率を上げる。
トークンコストは高いため、**単一ファイル修正・順序依存タスク・同一ファイル編集**には使わない。

## 3 実行粒度（早見表）

| 粒度 | 適用場面 | 代表ツール |
|------|---------|----------|
| 単一セッション | 1 レイヤーで完結 | 通常作業 |
| サブエージェント | 結果を返すだけの調査・検索・並列タスク | Task / Agent ツール |
| エージェントチーム | 議論・整合性検証・複数レイヤー並列実装 | Agent Teams |

## コンテキストフレッシュ原則（要点）

- `/verify` で 2 レイヤー以上を扱う場合は新規サブエージェント spawn 必須
- `/review` は常に別セッション必須
- 修正後の再検証も新しいサブエージェントを spawn する

詳細パターン（10 種類のユースケース）・Canonical 7 verb フェーズ別ガイド・バックエンド / フロントエンド検証テンプレート・Task System の依存関係制御は [`.claude/skills/agent-teams/SKILL.md`](../skills/agent-teams/SKILL.md) を参照してください。

## 関連

- [`.claude/skills/agent-teams/SKILL.md`](../skills/agent-teams/SKILL.md) — エージェントチーム運用 SSOT
- [`.claude/skills/parallel-development/SKILL.md`](../skills/parallel-development/SKILL.md) — 並列開発（worktree）運用ルール
- [`completion-quality.md`](./completion-quality.md) — 完了品質ルール
- [`issue-workflow.md`](./issue-workflow.md) — Issue 駆動開発フロー
