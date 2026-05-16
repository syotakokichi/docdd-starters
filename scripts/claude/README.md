# scripts/claude/

Claude Code / DocDD ワークフローを支えるスクリプト群。

> ⚠️ **証跡カテゴリ mapping table の SSOT は本 README ではない**。真の SSOT は
> [`.claude/templates/issue-implementation-plan.md`](../../.claude/templates/issue-implementation-plan.md)
> 「🗺️ 証跡マッピング表」。本 README は **派生表（human-readable）** として
> 同表を転記したものであり、SSOT が更新されたら本 README と
> `verify-issue-detect.sh` の anchored regex を同時に更新する。
>
> drift の自動検知は Phase F で `make validate-claude` 配下に追加予定（forward reference）。
>
> SSOT 階層:
>
> ```
> 真の SSOT: .claude/templates/issue-implementation-plan.md「🗺️ 証跡マッピング表」
>     ↓ 派生
> 派生表 (human-readable):  scripts/claude/README.md（本ファイル）
>     ↓ 実装
> 実装 (executable):       scripts/claude/verify-issue-detect.sh の anchored regex
>     ↓ 検証
> 検証 (test):             scripts/claude/test/verify-issue-detect.bats fixture
> ```

---

## スクリプト一覧

| ファイル | 役割 | 呼び出し元 |
|---------|------|-----------|
| `detect-capabilities.sh` | gh / codex / pencil / aws 等の利用可否を JSON で出力 | `scripts/bootstrap.sh` |
| `validate-claude-config.sh` | `.claude/` 配下の構成・命名・frontmatter を検証 | `make validate-claude` |
| `validate_claude_frontmatter.py` | skill / command の frontmatter スキーマ検証 | `validate-claude-config.sh` 内部 |
| `verify-issue-detect.sh` | 変更パスから必要証跡カテゴリを列挙する change-aware detector | `make verify-issue-detect`、`verify-issue.sh`（5-2）、5-3（後続 Issue） |
| `verify-issue.sh` | Issue 番号 → PR 解決 → detector → カテゴリ別検証 → 構造化 JSON 出力の 6 ステップ orchestrator | `make verify-issue`、5-3（後続 Issue） |
| `test-hooks.bats` | `.claude/hooks/` の bats fixture | `make test-hooks` |
| `test/verify-issue-detect.bats` | `verify-issue-detect.sh` の bats fixture | `make verify-issue-detect` |
| `test/verify-issue.bats` | `verify-issue.sh` の bats fixture（29 ケース） | `make verify-issue-fixture` |

---

## verify-issue-detect.sh

変更パスを入力に、必要な証跡カテゴリを stdout に列挙する純粋関数。
`/verify` と `make verify-issue`（5-2 で導入済み — 下記 `verify-issue.sh` 節）の前段で使う。

### 使い方

```bash
# 1) stdin（改行区切り）
echo "apps/backend/app/modules/example/domain/foo.py" \
  | scripts/claude/verify-issue-detect.sh --stdin

# 2) 引数
scripts/claude/verify-issue-detect.sh --files \
  apps/backend/app/modules/example/domain/foo.py \
  docs/7-axis/3_DM/DM-User.md

# 3) git merge-base diff（default は main、VERIFY_BASE_REF で上書き可）
scripts/claude/verify-issue-detect.sh --git
VERIFY_BASE_REF=origin/main scripts/claude/verify-issue-detect.sh --git
```

### 出力フォーマット

| `--format` | 内容 |
|-----------|------|
| `flat`（default） | 一行一カテゴリ。重複排除済み。後続フィルタ用 |
| `manifest` | `<path>: <cat1> <cat2> ...` 形式。path → categories の逆引き構造を維持（5-2 / 5-3 の説明責任用） |

### `--git` モードの base ref 解決順

1. `VERIFY_BASE_REF` 環境変数（指定があれば）
2. ローカル `main`
3. `origin/main`
4. すべて欠ければ exit 1（明確なエラーメッセージ）

CI shallow checkout / 別名 default branch / worktree 配下のいずれでも壊れないこと。

> ⚠️ **`--git` のスコープ**: `merge-base..HEAD` の **コミット済み差分のみ** を対象とする。
> staged / working-tree / untracked の未コミット変更は出ない。pre-commit ローカル
> 検出には `--stdin` か `--files` を使う（`/verify` 標準フローでは `/develop`
> でコミット済みのため `--git` で問題ない）。

### Make ターゲット

| ターゲット | 動作 |
|-----------|------|
| `make verify-issue-detect` | bats fixture を実行。bats 不在時は default で WARN（exit 0）、`CI=true` または `VERIFY_DETECT_REQUIRE_BATS=1` 下では fail（exit 1） |
| `make shell-lint` | shellcheck（`--severity=warning`）を `verify-issue-detect.sh` 含む `SHELL_FILES` に対して実行 |
| `make shell-format-check` | shfmt（`-i 2 -ci -bn`）の format 差分を検出 |

---

## 🗺️ 証跡カテゴリ mapping table（派生表）

> **真の SSOT は [`.claude/templates/issue-implementation-plan.md`](../../.claude/templates/issue-implementation-plan.md)「🗺️ 証跡マッピング表」**。
> 本表はそこからの派生（human-readable）であり、`verify-issue-detect.sh` の anchored regex は本表に従う。
> 表記揺れ（旧 SubsCore: `presentation/` / `infrastructure/` ↔ 新 docdd-starters: `api/` / `repositories/`）は両方マッチさせる。

| 変更パス（glob 表記、ドキュメント用） | 証跡カテゴリ | 必須証跡 | 自動検知 |
|------|------------|---------|----------|
| `apps/backend/app/modules/**/domain/**`, `apps/backend/app/modules/**/services/**` | `backend-unit` | ユニットテスト（pytest） | `make test-backend` |
| `apps/backend/app/modules/**/repositories/**`, `apps/backend/app/modules/**/infrastructure/**`, `apps/backend/app/infrastructure/**` | `backend-integration` | 統合テスト（DB / 外部連携） | `make test-backend` |
| `apps/backend/app/modules/**/api/**`, `apps/backend/app/modules/**/presentation/**`, `apps/backend/app/middlewares/**`, `apps/backend/app/shared/**/routes.py` | `api-route` | 統合テスト + API仕様書（6_API）更新 + caller 全件確認 | `make test-backend` + 手動 |
| `apps/backend/app/**/schemas/**`, `apps/backend/app/contracts/**`, `apps/frontend/**/_types/**`, `apps/frontend/src/types/**` | `api-contract` | Frontend 型一致確認 | 手動 |
| `apps/backend/app/kernel/**`, `apps/backend/app/shared/**` | `backend-core` | ユニットテスト + 動作確認 | `make test-backend` + 手動 |
| `apps/backend/alembic/versions/**` | `migration-safety` | up / down / up サイクル | CI |
| `apps/frontend/app/**/page.tsx`, `apps/frontend/app/**/layout.tsx`, `apps/frontend/app/**/_containers/**`, `apps/frontend/app/**/_components/**`, `apps/frontend/src/components/**` | `frontend-ui` | Vitest OR ブラウザ目視 | `make test-frontend` / 手動 |
| `apps/frontend/app/**/_hooks/**`, `apps/frontend/app/**/_lib/**`, `apps/frontend/app/**/_actions/**` | `frontend-logic` | Vitest テスト必須 | `make test-frontend` |
| `apps/frontend/src/lib/**`, `apps/frontend/src/store/**`, `apps/frontend/src/hooks/**` | `frontend-shared` | Vitest テスト必須 | `make test-frontend` |
| `apps/frontend/app/**/globals.css`, `apps/frontend/tailwind.config.*`, `apps/frontend/postcss.config.*` | `frontend-style` | ブラウザ目視 | 手動 |
| `docs/7-axis/**`, `docs/testing/traceability/**` | `docdd` | frontmatter + traceability | `make traceability` |
| `scripts/**`, `Makefile*`, `*.config.*`, `.claude/hooks/**`, `.claude/settings.json`, `.github/**`, `terraform/**` | `dx-config` | 動作確認 + 既存テスト非破壊 | 手動 |
| `.claude/commands/**`, `.claude/rules/**`, `.claude/skills/**`, `.claude/templates/**`, `.claude/references/**` | `dx-docs` | `make validate-claude` + 目視確認 | `make validate-claude` |

> **glob 表記はドキュメント用**。実装は anchored regex（例: `^apps/backend/app/modules/.+/(domain|services)/`）で `verify-issue-detect.sh` 内に固定する。`.+`（vs `[^/]+`）はネストしたモジュール（`modules/<a>/<b>/<layer>/...`）も拾うため。glob を `grep -E` に直渡しはしない。

---

## verify-issue.sh

Issue 番号を起点に 6 ステップを直列実行する orchestrator（Wave 5-2）。
`verify-issue-detect.sh`（5-1）を呼び出してカテゴリを検出し、カテゴリごとの検証を実行して構造化 JSON を出力する。

| ステップ | 内容 |
|---------|------|
| 0 | 前提チェック（`jq` 存在確認） |
| 1 | Issue → PR 解決 + ISSUE-PR 紐付け検証（PR 本文/タイトルの `Closes/Fixes/Resolves #<N>` / `#<N>`） |
| 2 | `verify-issue-detect.sh` でカテゴリ検出（PR あり: `--stdin` / PR なし: `--git` fallback） |
| 3 | カテゴリ → make target を **dedup** して順次実行（stop-on-fail = 続行） |
| 4 | 集約（`pass/fail/skip/manual_required/partial/total` の 5+1 統計） |
| 5 | 構造化 JSON 出力（atomic write + `.latest.json` symlink）+ exit code |

### 使い方

```bash
# 位置引数（SubsCore 流）
scripts/claude/verify-issue.sh 62
# ISSUE env でも可（位置引数が無いとき）
ISSUE=62 scripts/claude/verify-issue.sh
# Makefile 経由
make verify-issue ISSUE=62
```

### 環境変数

| 環境変数 | 既定値 | 効果 |
|---------|:----:|------|
| `VERIFY_ISSUE_OUTPUT` | （mktemp） | 出力 JSON パスを上書き。未指定時は `$(mktemp "$TMPDIR/verify-issue-<N>.XXXXXX").json` |
| `VERIFY_REQUIRE_PR_MATCH` | `1` | `0` で ISSUE-PR 不一致を warning に降格（exit 3 にしない） |
| `VERIFY_ISSUE_DETECTOR` | 同階層の `verify-issue-detect.sh` | detector スクリプトパスを上書き（テスト用） |

### 出力 / exit code

- 出力 JSON の schema SSOT は [`.claude/templates/verify-issue-result.json`](../../.claude/templates/verify-issue-result.json)（5-3 との契約）。`.latest.json` symlink で最新 run を辿れる
- step の stdout/stderr 本文は別ファイルに退避し、JSON には path のみ記録（巨大ログ / 制御文字による JSON 破壊を構造的に回避）
- exit code: `0` 全 PASS（SKIP のみ含む） / `1` 1 件以上 FAIL / `2` 引数不正（ISSUE 未指定 / 非数字 / `0`） / `3` 前提失敗（`jq` 不在 / detector 不在・異常終了 / unknown_category / `gh pr list` 失敗 / ISSUE-PR 不一致）
- detector の `exit 1` は orchestrator 側で `exit 3` + `error.code = "detector_failed"` に変換（detector 本体は 5-1 baseline として改変しない）
- 手動証跡を要するカテゴリ（api-route / api-contract / backend-core / frontend-ui / frontend-style / docdd / dx-config / dx-docs）は自動 step に **加算** で `<category>-manual` プレースホルダ step（`skip_reason: "manual_required"`）を出力し `summary.manual_required_count` に計上。自動 target が PASS しても手動確認は消えない（5-3 が可視化）。migration-safety のみ例外で partial+notes で表現

### Make ターゲット

| ターゲット | 動作 |
|-----------|------|
| `make verify-issue ISSUE=<N> [ARGS=...]` | orchestrator を起動。`ARGS` は将来の opt-in 拡張用 pass-through |
| `make verify-issue-fixture` | bats fixture（29 ケース）を実行。bats 不在時は default で WARN（exit 0）、`CI=true` または `VERIFY_ISSUE_FIXTURE_REQUIRE_BATS=1` 下では fail（exit 1） |

---

## 関連

- [.claude/templates/issue-implementation-plan.md](../../.claude/templates/issue-implementation-plan.md) — **真の SSOT**
- [.claude/skills/verify-input-capture/SKILL.md](../../.claude/skills/verify-input-capture/SKILL.md) — `/verify` Step 1 入力固定
- [.claude/rules/cli-first.md](../../.claude/rules/cli-first.md) — CLI ファースト原則
- [.claude/templates/verify-issue-result.json](../../.claude/templates/verify-issue-result.json) — `verify-issue.sh` 出力 JSON schema SSOT（5-3 契約）
- [Makefile](../../Makefile) — `verify-issue` / `verify-issue-fixture` / `verify-issue-detect` / `shell-lint` / `shell-format-check` / `test-hooks` / `validate-claude` ターゲット
