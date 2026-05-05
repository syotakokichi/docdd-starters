# Claude Commands - 並列開発フロー

このディレクトリには、開発を効率化するためのカスタムコマンドが含まれています。

旧コマンド（`/1`–`/7`, `/a`–`/c`, `/run-tests`）からの移行案内: [docs/guides/migration-from-legacy-commands.md](../../docs/guides/migration-from-legacy-commands.md)
コマンド名の SSOT: [.claude/rules/terminology.md](../rules/terminology.md)

## 開発フロー（canonical）

Issue 駆動開発の標準フローです。

```bash
/issue                # Issue作成 - 新しい GitHub Issue を作成
/plan <N>             # 計画立案 - 実装計画を Issue 本文に追記
/worktree <N>         # worktree 作成 + ブランチ命名（並列開発の起点）
/develop <N>          # 実装 - 進行中ラベル設定 + 実装
/verify <N>           # 実装検証 - 品質ゲート + Codex 差分レビュー
/review <N>           # 独立レビュー - 実装文脈外からの見落とし検出
/pr <N>               # PR 作成 - GitHub Pull Request を作成
/merge <N>            # マージ + worktree クリーンアップ
```

## 並列開発の完全フロー

複数の Issue を同時進行する場合の推奨ワークフロー。

### ターミナル 1（メインタスク）

```bash
# Issue #115 の作業継続
/develop 115
```

### ターミナル 2（新しいタスク）

```bash
/worktree 116    # worktree 作成 + ブランチセットアップ + 別ウィンドウ起動
# 別エディタウィンドウに切り替え
/plan 116        # 計画立案
/develop 116     # 実装
/verify 116      # 実装検証
/review 116      # 独立レビュー（新セッション推奨）
/pr 116          # PR 作成
# レビュー・マージ後、メインリポジトリに戻る
/merge 116       # マージ + worktree クリーンアップ
```

未マージのまま破棄する場合: `/discard-worktree 116`

## コマンド一覧

### 開発フローコマンド

| コマンド | 説明 | ファイル |
|---------|------|----------|
| `/issue` | 新しい GitHub Issue を作成 | issue.md |
| `/plan` | GitHub Issue から実装計画を立案 | plan.md |
| `/worktree` | Issue 用の worktree 環境を作成 | worktree.md |
| `/develop` | 実装フェーズ開始（進行中ラベル設定） | develop.md |
| `/verify` | 実装検証（品質ゲート） | verify.md |
| `/review` | 独立レビュー（実装文脈外） | review.md |
| `/pr` | Pull Request 作成 | pr.md |
| `/merge` | PR マージ + worktree クリーンアップ | merge.md |
| `/discard-worktree` | 未マージ worktree の破棄 | discard-worktree.md |

### Git 操作コマンド

| コマンド | 説明 | ファイル |
|---------|------|----------|
| `/commit-and-push` | 変更をコミットしてプッシュ | commit-and-push.md |

### ユーティリティコマンド

| コマンド | 説明 | ファイル |
|---------|------|----------|
| `/brainstorm` | 早期段階の壁打ち / アイデア整理 | brainstorm.md |
| `/discuss` | 実装・設計の壁打ちセッション | discuss.md |
| `/skill-create` | 新しいスキルを作成 | skill-create.md |
| `/update-issue` | Issue 本文を実装変更に合わせて更新 | update-issue.md |
| `/tdd` | TDD ワークフロー（後続 Issue で本実装） | tdd.md |
| `/slide` | Marp スライド作成の壁打ち | slide.md |

> テスト実行は Makefile target を使用する: `make test` / `make test-backend` / `make test-frontend` / `make traceability` / `make validate-claude`

## メリット

- **並列開発**: 複数の Issue を同時進行可能
- **コンテキスト分離**: 各 worktree で独立した作業環境
- **効率化**: 定型作業の自動化
- **一貫性**: 統一されたワークフロー

## 注意事項

- worktree は Git 2.5 以降で利用可能
- 各 worktree は独立したディレクトリとして扱われる
- 不要になった worktree は `/merge`（マージ完了後）または `/discard-worktree`（破棄）で削除する
