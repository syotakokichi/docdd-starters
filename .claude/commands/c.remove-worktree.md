---
description: '[deprecated] /discard-worktree に移行しました（用途: 未マージ破棄のみ）。'
argument-hint: "<issue-number>"
disable-model-invocation: true
---

# [deprecated] /c.remove-worktree

このコマンドは **`/discard-worktree`** に置き換わりました。

> ⚠️ **このコマンドはここで処理を停止します。自動転送は行いません。**
> 用途に応じてユーザーが手動で実行してください:
> - **未マージの破棄** → `/discard-worktree $ARGUMENTS`
> - **PR マージ後の cleanup** → `/merge` 内で実行（`/discard-worktree` ではない）

詳細: `.claude/commands/discard-worktree.md` / `.claude/commands/merge.md`

> 削除予定: Phase E 完了 + 1 週間後（Issue F-1 で物理削除）
