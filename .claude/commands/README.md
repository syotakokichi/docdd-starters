# Claude Commands - 並列開発フロー

このディレクトリには、開発を効率化するためのカスタムコマンドが含まれています。

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

### 3. 通常の開発フロー（1-7）
```bash
/1  # Issue作成 - 新しいGitHub Issueを作成
/2  # 計画立案 - GitHub Issueから実装計画を立案（エージェントチーム活用可）
/3  # ブランチ作成（既にworktreeで作成済みならスキップ）
/4  # 実装 - 進行中ラベル設定 + 計画に基づいて実装
/5  # 実装検証 - PR作成前の品質ゲート（エージェントチーム並列検証）
/6  # PR作成 - GitHub Pull Requestを作成
/7  # マージ＆クリーンアップ - PRマージ後の後処理
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
/4 115  # 実装中
```

### ターミナル2（新しいタスク）
```bash
/a 116     # worktree作成
/b 116     # worktreeへ移動
claude     # 新しいClaude Codeセッション開始
/2 116     # 計画立案
/4 116     # 実装
/5 116     # PR作成
# ...レビュー・マージ後...
/6 116     # マージ＆クリーンアップ
```

## コマンド一覧

### 基本開発コマンド（1-7）
| コマンド | 説明 | ファイル |
|---------|------|----------|
| `/1` | 新しいGitHub Issueを作成 | 1.create-issue.md |
| `/2` | GitHub Issueから実装計画を立案 | 2.plan-github-issue.md |
| `/3` | ブランチ作成とIssue紐付け | 3.create-branch.md |
| `/4` | 実装フェーズ開始（進行中ラベル設定） | 4.fix-github-issue.md |
| `/5` | 実装検証（品質ゲート） | 5.verify-implementation.md |
| `/6` | Pull Request作成 | 6.create-pr.md |
| `/7` | マージ後のクリーンアップ | 7.merge-and-cleanup.md |

### Worktree管理コマンド（a-c）
| コマンド | 説明 | ファイル |
|---------|------|----------|
| `/a` | 新しいworktree作成 | a.create-worktree.md |
| `/b` | worktreeへ移動 | b.move-to-worktree.md |
| `/c` | worktree削除 | c.remove-worktree.md |

### Git操作コマンド
| コマンド | 説明 | ファイル |
|---------|------|----------|
| `/commit-and-push` | 変更をコミットしてプッシュ | commit-and-push.md |

### テスト関連コマンド
| コマンド | 説明 | ファイル |
|---------|------|----------|
| `/run-tests` | テストスイートの実行 | run-tests.md |

### ユーティリティコマンド
| コマンド | 説明 | ファイル |
|---------|------|----------|
| `/discuss` | 実装・設計の壁打ちセッション | discuss.md |
| `/skill-create` | 新しいスキルを作成 | skill-create.md |
| `/update-issue` | Issue本文を実装変更に合わせて更新 | update-issue.md |
| `/slide` | Marpスライド作成の壁打ち | slide.md |

## メリット

- **並列開発**: 複数のIssueを同時進行可能
- **コンテキスト分離**: 各worktreeで独立した作業環境
- **効率化**: 定型作業の自動化
- **一貫性**: 統一されたワークフロー

## 注意事項

- worktreeはGit 2.5以降で利用可能
- 各worktreeは独立したディレクトリとして扱われる
- 不要になったworktreeは必ず `/c` コマンドで削除する
