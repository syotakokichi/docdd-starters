# Bootstrap Guide

fork 直後のユーザーが最初の `/issue` を実行するまでに必要なセットアップをまとめます。

## 対応 OS

| OS | サポート |
|----|:--------:|
| macOS | ✅ |
| Linux | ✅ |
| WSL (Windows Subsystem for Linux) | ✅ |
| Pure Windows (PowerShell / cmd) | ❌ |

Pure Windows 環境は非対応です。WSL を利用してください。

## 前提ツール

| ツール | 用途 | インストール例 |
|-------|------|---------------|
| `git` | バージョン管理 | プラットフォーム標準 |
| `gh` (GitHub CLI) | Issue / Label / Projects 操作 | <https://cli.github.com/> |
| `jq` | JSON 処理 | `brew install jq` / `apt install jq` |

`gh auth status` が成功する状態にしておく必要があります。

## 手順

```bash
# 1. fork したリポジトリを clone
git clone https://github.com/<your-account>/docdd-starters.git
cd docdd-starters

# 2. GitHub にログイン
gh auth login

# 3. bootstrap を実行
make bootstrap
```

`make bootstrap` は以下を実行します:

1. **preflight**: `gh` / `jq` / `git` / `gh auth` / `origin` fork / `labels.json` の構文をチェック
2. **capability 検出**: `scripts/claude/detect-capabilities.sh` を実行し、結果を `/tmp/docdd-capabilities.json` に保存（stderr に pretty-print）
3. **ラベル収束**: `.github/labels.json` に定義された 22 ラベル（canonical 英語 13 + 日本語互換 9）を `gh label create --force` で作成 / 更新

2 回連続で実行しても repo 配下に untracked file は作成されません（`git status --porcelain` が空のまま）。

## Capability JSON の読み方

`/tmp/docdd-capabilities.json` は schema v1 準拠の JSON です。各 capability の `state` は 3 値:

| state | 意味 | consumer 側の扱い |
|-------|------|------------------|
| `available` | 検出成功・利用可能 | 通常通り利用 |
| `unavailable` | 明示的に未導入 | gracefully skip、warning |
| `unknown` | 判定不能（scope 不足・検出手段なし） | skip + 再確認を促す |

`owner_projects_count.value` は **観測値** です（設定値ではない点に注意）。`gh project list --owner <login> --limit 200` で取得しているため、200 を超える projects がある環境では最大 200 で頭打ちになります。

### 主要 capability

| capability | 説明 |
|-----------|------|
| `gh_installed` | `command -v gh` |
| `gh_authenticated` | `gh auth status` |
| `repo_write_access` | `gh api repos/:owner/:repo -q .permissions.push` |
| `projects_api_available` | `gh project list --owner :login --limit 200 --format json` |
| `owner_projects_count` | 上記レスポンスの `.projects | length`（観測上限 200） |
| `codex_cli` | `command -v codex && codex --version` |
| `mcp_servers` | `.claude/settings.json` / `.claude/settings.local.json` / `~/.claude.json` |
| `pencil_mcp` | `mcp_servers` の name に `pencil` を含むか |
| `computer_use` | 設定ファイル内に `computer-use` 系の定義があるか |

## トラブルシュート

### `gh CLI が見つかりません`

<https://cli.github.com/> から gh をインストールしてください。

### `jq が見つかりません`

```bash
brew install jq        # macOS
sudo apt install jq    # Debian/Ubuntu
```

### `gh auth login を実行して GitHub にログインしてください`

```bash
gh auth login
```

### `origin owner ... が gh ログインユーザー ... と一致しません`

`origin` が upstream を指している可能性があります:

```bash
git remote -v
git remote set-url origin https://github.com/<your-account>/docdd-starters.git
```

意図しない repository に label を書き込む事故を防ぐため、一致しない場合は bootstrap を中断します。

### Projects が未作成

bootstrap は Projects の自動作成を行いません。利用する場合は GitHub Web UI で作成してください。Projects が無くても bootstrap は成功します（`projects_api_available.state` が `unknown` または `unavailable` になるだけ）。

### ラベルが作成されたか確認したい

```bash
gh label list -L 200
```

`.github/labels.json` の `managed_labels` 全件と、既存ラベル（`bug`, `documentation` 等 GitHub デフォルト分）が並んで表示されれば成功です。

### デバッグ出力を見たい

`make bootstrap` の stdout は空です。ログ / JSON は stderr に出ます:

```bash
make bootstrap 2>&1 | less
```

## 次のステップ

bootstrap 完了後は、以下の流れで開発を開始できます:

```bash
# Issue 作成前の discovery（必須）
/brainstorm

# Issue 作成（Claude Code スラッシュコマンド）
/issue

# 計画立案
/plan <issue-number>

# Worktree 作成 + ブランチセットアップ
/worktree <issue-number>
```

詳細は [.claude/commands/README.md](../../.claude/commands/README.md) を参照してください。
