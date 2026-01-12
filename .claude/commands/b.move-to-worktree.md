Issue $ARGUMENTS 用の worktree ディレクトリに移動してください。

---

## 手順

### 1. Worktree の確認

```bash
# 既存のworktreeを一覧表示
git worktree list
```

### 2. Worktree ディレクトリに移動

```bash
# worktreeディレクトリに移動
cd ../<project>-issue-$ARGUMENTS
```

または親ディレクトリからの絶対パス:

```bash
cd /path/to/parent/<project>-issue-$ARGUMENTS
```

### 3. 移動の確認

```bash
# 現在のディレクトリを確認
pwd

# 現在のブランチを確認
git branch --show-current

# ステータスを確認
git status
```

---

## 注意事項

- Worktree が存在しない場合は先に `/a $ARGUMENTS` で作成
- 移動後は新しい Claude Code セッションを開始することを推奨
- 各 worktree は独立した作業環境として機能

## 関連コマンド

- `/a`: worktree 作成
- `/c`: worktree 削除
- `/6`: PR マージ & クリーンアップ

ARGUMENTS: issue_number

Example usage: `/b 123`
