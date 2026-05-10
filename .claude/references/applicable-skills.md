# 適用スキル一覧

Issue の内容に応じて、該当するスキルだけを読み込む SSOT。

> **対象範囲**: ユーザー workflow から選択される **flat 命名 skill のみ**（ドメインスキル + cross-cutting skill）。`assign-*` / `delegate-*` / `ref-*` / `run-*` の prefix 命名 meta skill は workflow 選択対象外のため本表には含めない（決定木 SSOT は [`.claude/skills/README.md`](../skills/README.md)）。

## ドメインスキル（Issue の内容で選択）

| Issue involves... | Applicable Skill | Path |
|-------------------|------------------|------|
| Backend API / FastAPI | backend-patterns | [`.claude/skills/backend-patterns/SKILL.md`](../skills/backend-patterns/SKILL.md) |
| Frontend / Next.js / UI | frontend-patterns | [`.claude/skills/frontend-patterns/SKILL.md`](../skills/frontend-patterns/SKILL.md) |
| Test implementation | testing-patterns | [`.claude/skills/testing-patterns/SKILL.md`](../skills/testing-patterns/SKILL.md) |
| DocDD documents / 7-axis | docdd-workflow | [`.claude/skills/docdd-workflow/SKILL.md`](../skills/docdd-workflow/SKILL.md) |
| UI design / Pencil.dev / デザイントークン | design | [`.claude/skills/design/SKILL.md`](../skills/design/SKILL.md) |
| Traceability map / 影響範囲検知 | traceability-automation | [`.claude/skills/traceability-automation/SKILL.md`](../skills/traceability-automation/SKILL.md) |
| Marp スライド / 資料作成 | presentation | [`.claude/skills/presentation/SKILL.md`](../skills/presentation/SKILL.md) |

## Cross-Cutting Skills（フロー横断で適用）

ドメインに依存せず、コマンド側から必要時にロードする横断スキル。

| Always applies when... | Applicable Skill | Path |
|------------------------|------------------|------|
| Planning issue implementation (`/plan`) | planning-quality | [`.claude/skills/planning-quality/SKILL.md`](../skills/planning-quality/SKILL.md) |
| Sizing issues (`/issue`, `/plan`, `/brainstorm`) | issue-sizing | [`.claude/skills/issue-sizing/SKILL.md`](../skills/issue-sizing/SKILL.md) |
| Organizing agent teams / context-fresh strategy (`/plan`, `/develop`, `/verify`, `/review`) | agent-teams | [`.claude/skills/agent-teams/SKILL.md`](../skills/agent-teams/SKILL.md) |
| Parallel development with worktrees (`/worktree`, `/merge`, `/discard-worktree`) | parallel-development | [`.claude/skills/parallel-development/SKILL.md`](../skills/parallel-development/SKILL.md) |
| `/verify` Step 1 input capture (issue number validation / merge-base diff / execution context) | verify-input-capture | [`.claude/skills/verify-input-capture/SKILL.md`](../skills/verify-input-capture/SKILL.md) |
| TDD workflow / RED-GREEN cycle / 証跡フォーマット (`/tdd`, `/develop`, `/verify`) | tdd-workflow | [`.claude/skills/tdd-workflow/SKILL.md`](../skills/tdd-workflow/SKILL.md) |
| Critical Path 判定・保護レイヤー選択・Coverage expectation (`/plan` Phase 1.3 で Critical/Mixed と判定された場合) | test-design | [`.claude/skills/test-design/SKILL.md`](../skills/test-design/SKILL.md) |
| 完了主張前の 5 ステップゲート（IDENTIFY/RUN/READ/VERIFY/CLAIM） (`/develop` Phase 3, `/verify`, `/pr`) | verification-before-completion | [`.claude/skills/verification-before-completion/SKILL.md`](../skills/verification-before-completion/SKILL.md) |

## 使い方

### `/plan` Phase 1

Issue の内容に応じて、上の表からスキルを選び `Read` する:

```
| Issue involves... | Applicable Skill | Path |
|...
```

選んだスキルの SKILL.md を読み込み、計画立案に反映する。複数該当する場合は両方読み込む。

### `/issue` 起票時

サイズチェックに `issue-sizing` スキル、計画品質基準に `planning-quality` スキルを参照する。

### `/develop` `/verify` `/review` 実装・検証フェーズ

レイヤー横断・コンテキストフレッシュ判断に `agent-teams` スキルを参照する。

## 関連ファイル

- [`.claude/skills/README.md`](../skills/README.md) - skill 全体一覧（prefix meta skill 含む）
- [`.claude/commands/plan.md`](../commands/plan.md) - `/plan` Phase 1 で本ファイルを参照
- [`.claude/commands/issue.md`](../commands/issue.md) - `/issue` でサイズチェック参照
- [`.claude/commands/verify.md`](../commands/verify.md) - `/verify` Step 1 で `verify-input-capture` を参照
