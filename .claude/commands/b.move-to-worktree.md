---
description: '[deprecated] /worktree に移行しました（既存 worktree への移動は git worktree list を使用）。'
argument-hint: "<issue-number>"
disable-model-invocation: true
---

# [deprecated] /b.move-to-worktree

このコマンドは **`/worktree`** に置き換わりました。

> ⚠️ **このコマンドはここで処理を停止します。自動転送は行いません。**
> 用途に応じてユーザーが手動で実行してください:
> - **未作成** → `/worktree $ARGUMENTS`（新規 worktree を作成）
> - **既存 worktree への移動** → `git worktree list` でパス確認後、ターミナルで `cd <path>`（`/worktree` を再実行すると `git worktree add` エラーになるため不可）

詳細: `.claude/commands/worktree.md`

> 削除予定: Phase E 完了 + 1 週間後（Issue F-1 で物理削除）
