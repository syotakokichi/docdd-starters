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
| `validate-claude-config.sh` | `.claude/` 配下の構成・命名・frontmatter を検証（baseline / `--strict`） | `make validate-claude`、`make validate-claude-strict` |
| `validate_claude_frontmatter.py` | skill / command の frontmatter スキーマ検証（`--strict` / `--dir`） | `validate-claude-config.sh` 内部 |
| `verify-issue-detect.sh` | 変更パスから必要証跡カテゴリを列挙する change-aware detector | `make verify-issue-detect`、`verify-issue.sh`（5-2）、5-3（後続 Issue） |
| `verify-issue.sh` | Issue 番号 → PR 解決 → detector → カテゴリ別検証 → 構造化 JSON 出力の 6 ステップ orchestrator | `make verify-issue`、5-3（後続 Issue） |
| `test-hooks.bats` | `.claude/hooks/` の bats fixture | `make test-hooks` |
| `test/verify-issue-detect.bats` | `verify-issue-detect.sh` の bats fixture | `make verify-issue-detect` |
| `test/verify-issue.bats` | `verify-issue.sh` の bats fixture（29 ケース） | `make verify-issue-fixture` |
| `test/harness-regression.bats` | `.claude/` harness 不変条件の回帰スイート（V6 カタログ 1〜10） | `make test-harness` |

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

## validate-claude-config.sh — strict モード / harness 回帰スイート（Wave 6-1）

### strict モード運用

`validate-claude-config.sh` は 2 モードで動作する。

| モード | 起動 | 挙動 | exit |
|--------|------|------|:----:|
| baseline（既定） | `make validate-claude` | frontmatter 欠落 = warning | warning があっても 0 |
| strict | `make validate-claude-strict`（`validate-claude-config.sh --strict`） | 構造/必須不変条件の欠落（frontmatter 欠落 / settings.json 不正 / hook 実行不可 等）を **failure に昇格** | 昇格対象が 1 件でもあれば 1 |

strict 昇格の対象は **構造・必須不変条件**（SKILL.md の `name`/`description` frontmatter 欠落、settings.json の JSON 構造、hook 実行可能性）に限る。

### `args` 警告の正当化（DoD #4 — 仕様であり昇格しない）

`make validate-claude-strict` は現状の `.claude/` 構成で **exit 0（warnings 16 件）** になる。

この 16 件は `commands/*.md: missing recommended fields: args` であり、**strict でも failure に昇格しない**。
理由: `args` は **recommended（informational）field** であり、`validate_claude_frontmatter.py` 内で `record` を経由せず警告カウントに直加算されるため、strict 昇格パス（`record WARN → FAIL (strict)`）を通らない設計になっている。

これは**見落としではなく仕様**である。recommended field の不足は情報提供に留め、strict が fail させるのは「構造/必須不変条件の破壊」のみとする（baseline のチェック内容は再設計しない）。

### harness 回帰スイート

`scripts/claude/test/harness-regression.bats` は `.claude/` harness の **不変条件**を継続的に検証する回帰スイート。

```bash
make test-harness                       # bats 経由で全 11 ケース実行
bats scripts/claude/test/harness-regression.bats   # 直接実行
```

検証する不変条件カタログ（V6 1〜10）:

1. `.claude/commands/*.md` が strict frontmatter を通過
2. `.claude/skills/**/SKILL.md` が strict 通過（`name` == 親ディレクトリ名）
3. `validate-claude-config.sh --strict` の e2e（現状 `.claude/` 全体が strict 通過）
4. `make validate-claude-strict` が存在し exit 0 かつ STRICT モードで実行
5. `settings.json` が valid JSON + `permissions`/`hooks` が配列
6. settings.json の全 hook script が存在し実行可能
7. 必須 hook binding（Bash PreToolUse / Write\|Edit PostToolUse）
8. strict 昇格 false-GREEN ガード（(a) python `--dir` fixture / (b) temp `.claude/` skeleton + `cd`）
9. prompt files に suspicious invisible Unicode 無し
10. `terminology.md` の canonical `/<cmd>` に対応する `commands/<cmd>.md` が存在

> **false-GREEN ガード**（上流 #347/#349 の学び）: strict FAIL を「exit code ≠ 0」だけで判定しない。
> helper / python 不在の異常終了も非 0 で終わるため、それを GREEN と誤認しないよう
> 出力マーカー（`no frontmatter` / `FAIL (strict)`）も併せて grep する。

### bats 不在時の挙動

`make test-harness` は既存 `verify-issue-fixture` パターンに準拠する。

| 環境 | 挙動 |
|------|------|
| bats あり | `harness-regression.bats` を実行 |
| bats なし・ローカル | WARN を出して skip（exit 0） |
| bats なし・`CI=true` または `HARNESS_REQUIRE_BATS=1` | ERROR で fail（exit 1） |

### strict は CI 安全網（backstop）— ローカル baseline 経路は意図的に非変更

本 Issue（Wave 6-1）の strict 配線は **CI（PR マージ境界）側の安全網**であり、ローカルの proof 経路は **意図的に baseline のまま**にしている。

| 経路 | モード | 理由 |
|------|--------|------|
| CI `docdd-validation` job | strict（`make validate-claude-strict`）+ baseline | PR マージ境界の authoritative gate |
| ローカル `make verify-issue` の dx-docs 経路 / `/develop` `/verify` `/pr` | baseline（`make validate-claude`） | verify-issue 本体ロジックの改変は本 Issue の Out-of-scope |

ローカルで strict を事前確認したい場合は **`make validate-claude-strict` を手動実行**する。

> これは「見落とした gap」ではなく**設計上の意図的境界**である。ローカル proof command の universal strict 化は
> 安全網完成後の独立改善であり、Core Track 完了をブロックしない（後続 Issue 候補・Core Track 外）。

---

## 関連

- [.claude/templates/issue-implementation-plan.md](../../.claude/templates/issue-implementation-plan.md) — **真の SSOT**
- [.claude/skills/verify-input-capture/SKILL.md](../../.claude/skills/verify-input-capture/SKILL.md) — `/verify` Step 1 入力固定
- [.claude/rules/cli-first.md](../../.claude/rules/cli-first.md) — CLI ファースト原則
- [.claude/templates/verify-issue-result.json](../../.claude/templates/verify-issue-result.json) — `verify-issue.sh` 出力 JSON schema SSOT（5-3 契約）
- [Makefile](../../Makefile) — `verify-issue` / `verify-issue-fixture` / `verify-issue-detect` / `shell-lint` / `shell-format-check` / `test-hooks` / `test-harness` / `validate-claude` / `validate-claude-strict` ターゲット
