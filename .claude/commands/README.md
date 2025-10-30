# Claude Commands - 並列開発フロー

このディレクトリには、ClubPayプロジェクトの開発を効率化するためのカスタムコマンドが含まれています。

## 並列開発の完全フロー

複数のIssueを同時に進行させる際の推奨ワークフローです。

### 1. Worktree作成
```bash
/a 116
```
Issue #116用の新しいworktreeを作成します。

### 2. Worktreeに移動
```bash
/b 116
```
作成したworktreeディレクトリに移動します。

### 3. 通常の開発フロー（1-5）
```bash
/1  # Issue計画 - GitHub Issueから実装計画を立案
/2  # ブランチ作成（既にworktreeで作成済みならスキップ）
/3  # 実装 - 計画に基づいて実装
/4  # PR作成 - GitHub Pull Requestを作成
/5  # マージ＆クリーンアップ - PRマージ後の後処理
```

### 4. Worktree削除
```bash
/c 116
```
作業完了後、worktreeを削除します。

## 実際の並列作業例

### ターミナル1（メインタスク）
```bash
# Issue #115の作業継続
/3  # 実装中
```

### ターミナル2（新しいタスク）
```bash
/a 116     # worktree作成
/b 116     # worktreeへ移動
claude     # 新しいClaude Codeセッション開始
/1         # Issue計画
/3         # 実装
/4         # PR作成
# ...レビュー・マージ後...
/c 116     # worktree削除
```

## コマンド一覧

### 基本開発コマンド（1-5）
| コマンド | 説明 | ファイル |
|---------|------|----------|
| `/1` | GitHub Issueから実装計画を立案 | 1.plan-github-issue.md |
| `/2` | ブランチ作成とIssue紐付け | 2.create-branch.md |
| `/3` | 実装フェーズ開始 | 3.fix-github-issue.md |
| `/4` | Pull Request作成 | 4.create-pr.md |
| `/5` | マージ後のクリーンアップ | 5.merge-and-cleanup.md |

### Worktree管理コマンド（a-c）
| コマンド | 説明 | ファイル |
|---------|------|----------|
| `/a` | 新しいworktree作成 | a.create-worktree.md |
| `/b` | worktreeへ移動 | b.merge-and-cleanup.md |
| `/c` | worktree削除 | c.remove-worktree.md |

### Git操作コマンド
| コマンド | 説明 | ファイル |
|---------|------|----------|
| `/commit-and-push` | 変更をコミットしてプッシュ | commit-and-push |
| `/update-github-issue` | GitHub Issueのステータス更新 | update-github-issue |

### テスト関連コマンド
| コマンド | 説明 | ファイル |
|---------|------|----------|
| `/run-tests` | テストスイートの実行 | run-tests |
| `/sync-test-sheets` | Google Sheetsとテストデータを同期 | sync-test-sheets |


## メリット

- **並列開発**: 複数のIssueを同時進行可能
- **コンテキスト分離**: 各worktreeで独立した作業環境
- **効率化**: 定型作業の自動化
- **一貫性**: 統一されたワークフロー

## 注意事項

- worktreeはGit 2.5以降で利用可能
- 各worktreeは独立したディレクトリとして扱われる
- 不要になったworktreeは必ず `/c` コマンドで削除する
