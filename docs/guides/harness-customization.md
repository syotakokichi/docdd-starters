# Claude Code ハーネス カスタマイズガイド

fork 先プロジェクトが `.claude/settings.json` と hooks を自分の環境に合わせて拡張するための手順書です。

## 概要

docdd-starters は **最小限の安全網（baseline）** を提供します。

| レイヤー | 役割 | ファイル |
|---------|------|---------|
| **settings.json** | allow / ask / deny のパーミッション | `.claude/settings.json` |
| **hooks** | PreToolUse / PostToolUse のガードレール | `.claude/hooks/*.sh` |
| **settings.local.json** | 個人/プロジェクト固有の上書き | `.claude/settings.local.json` |

## settings.json vs settings.local.json

| | settings.json | settings.local.json |
|---|---|---|
| **管理** | Git にコミット（チーム共有） | `.gitignore` 対象（個人設定） |
| **用途** | baseline ポリシー | 個人の追加 allow / deny 上書き |
| **優先度** | ベース | settings.json を上書き |

### 上書きの例

baseline で `gh api` が deny されているが、CI スクリプトで必要な場合:

```json
// .claude/settings.local.json
{
  "permissions": {
    "allow": [
      "Bash(gh api repos/myorg/myrepo:*)"
    ]
  }
}
```

## Baseline 構成

### allow（約 100 項目）

読み取り系 git / gh サブコマンド / テスト・リント / 一般的な CLI ツール。

### ask（約 20 項目）

確認が必要な操作:

- `git push --force-with-lease` / `git reset --hard` / `git push --delete`
- `gh pr merge` / `gh pr close`
- `make deploy-*` / `make tf-apply` / `make tf-destroy`
- `rm` / `mv`

### deny（1 項目）

- `gh api` — 任意のエンドポイントを叩けるバイパス経路。個別サブコマンド（`gh issue`, `gh pr` 等）は allow 済み。

## hooks 構成

### 1. block-dangerous.sh（PreToolUse + Bash）

| 種別 | パターン | 動作 |
|------|---------|------|
| **Hard block** | `sudo` | block |
| **Hard block** | `git push --force` / `-f`（`--force-with-lease` 除外） | block |
| **Hard block** | `rm -rf /` | block |
| **Hard block** | `gh api` | block |
| **Ask** | `git reset --hard` | ask 昇格 |
| **Ask** | `git push --delete` / `--mirror` / `:refspec` | ask 昇格 |
| **Ask** | `psql`/`mysql` + `DROP`/`TRUNCATE` | ask 昇格 |
| **Ask** | `rm` + 危険パス | ask 昇格 |
| **Ask** | `make deploy-*` | ask 昇格 |
| **Ask** | `gh pr merge` | ask 昇格 |

### 2. protect-files.sh（PreToolUse + Write/Edit/MultiEdit）

| パターン | 動作 | 例外 |
|---------|------|------|
| `.env*` | block | `.env.example`, `.env.sample` |
| `.git/` | block | — |
| `*.pem`, `*.key` | block | — |
| `id_rsa*` | block | — |

### 3. detect-quality-issues.sh（PostToolUse + Write/Edit/MultiEdit）

diff 内容のみを検査し、以下のパターンに警告を出す:

| パターン | 意味 |
|---------|------|
| `test.skip` / `describe.skip` / `it.skip` | テストスキップ |
| `.only` | テスト限定実行 |
| `eslint-disable` | リントルール無効化 |
| `@ts-ignore` / `@ts-nocheck` | TypeScript 型チェック回避 |
| `strict: false` | strict モード無効化 |
| `pytest.mark.skip`（reason なし） | reason なしの pytest スキップ |
| `noqa`（コードなし） | blanket noqa |
| 不可視 Unicode 文字 | プロンプトインジェクション対策 |

## カスタマイズ方法

### パターン 1: プロジェクト固有のコマンドを allow に追加

```json
// settings.json の permissions.allow に追加
"Bash(alembic:*)",
"Bash(make migrate:*)",
"Bash(terraform plan:*)"
```

### パターン 2: Docker 操作を追加

```json
// settings.json の permissions.allow に追加
"Bash(docker exec:*)",
"Bash(docker compose exec:*)",
"Bash(docker compose logs:*)"
```

### パターン 3: 特定のデプロイを allow に昇格

ask から allow に移動する場合、ask から削除して allow に追加:

```json
{
  "permissions": {
    "allow": [
      "Bash(make deploy-stg:*)"
    ]
  }
}
```

### パターン 4: hooks にプロジェクト固有ルールを追加

`block-dangerous.sh` に追加パターンを入れる場合:

```bash
# ─── Project-specific blocks ──────────────────────────────────
# Example: block direct database access in production
if echo "$COMMAND" | grep -qE 'psql.*production'; then
  echo '{"decision":"block","reason":"Direct production database access is blocked."}'
  exit 0
fi
```

### パターン 5: detect-quality-issues.sh に検出パターンを追加

```bash
# Example: warn on console.log in production code
if echo "$DIFF_CONTENT" | grep -qE 'console\.log\('; then
  WARNINGS="${WARNINGS}\n- console.log detected: remove before merging"
fi
```

## hooks 出力フォーマット

hooks が Claude Code と通信するための JSON フォーマット:

### PreToolUse hooks

```bash
# Block（完全拒否）
echo '{"decision":"block","reason":"Explanation of why this is blocked."}'

# Ask（ユーザー確認を要求）
echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"Explanation."}}'

# Allow（何も出力しない）
exit 0
```

### PostToolUse hooks

```bash
# Warning（システムメッセージとして表示）
echo '{"systemMessage":"Warning: description of the issue."}'

# Clean（何も出力しない）
exit 0
```

## トラブルシューティング

### hooks が動作しない

1. 実行権限を確認: `ls -la .claude/hooks/*.sh`
2. `chmod +x .claude/hooks/*.sh` で権限を付与
3. `jq` がインストールされているか確認: `which jq`

### settings.local.json が反映されない

- JSON の構文エラーがないか確認: `jq . .claude/settings.local.json`
- `permissions` キーの構造が正しいか確認

### Unicode 検出が動作しない

- `python3` が PATH 上にあるか確認: `which python3`
- python3 が存在しない場合、Unicode 検出はスキップされます（他の検出は動作します）

## 関連ファイル

- [.claude/settings.json](../../.claude/settings.json) — baseline ポリシー
- [.claude/hooks/](../../.claude/hooks/) — hook スクリプト
- [.claude/rules/](../../.claude/rules/) — コーディング規約
