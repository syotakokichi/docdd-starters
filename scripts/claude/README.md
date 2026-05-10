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
| `verify-issue-detect.sh` | 変更パスから必要証跡カテゴリを列挙する change-aware detector | `make verify-issue-detect`、5-2 / 5-3（後続 Issue） |
| `test-hooks.bats` | `.claude/hooks/` の bats fixture | `make test-hooks` |
| `test/verify-issue-detect.bats` | `verify-issue-detect.sh` の bats fixture | `make verify-issue-detect` |

---

## verify-issue-detect.sh

変更パスを入力に、必要な証跡カテゴリを stdout に列挙する純粋関数。
`/verify` と `make verify-issue`（5-2 で導入予定）の前段で使う。

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

> **glob 表記はドキュメント用**。実装は anchored regex（例: `^apps/backend/app/modules/[^/]+/(domain|services)/`）で `verify-issue-detect.sh` 内に固定する。glob を `grep -E` に直渡しはしない。

---

## 関連

- [.claude/templates/issue-implementation-plan.md](../../.claude/templates/issue-implementation-plan.md) — **真の SSOT**
- [.claude/skills/verify-input-capture/SKILL.md](../../.claude/skills/verify-input-capture/SKILL.md) — `/verify` Step 1 入力固定
- [.claude/rules/cli-first.md](../../.claude/rules/cli-first.md) — CLI ファースト原則
- [Makefile](../../Makefile) — `verify-issue-detect` / `shell-lint` / `shell-format-check` / `test-hooks` / `validate-claude` ターゲット
