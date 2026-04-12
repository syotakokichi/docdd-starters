# Capability Matrix (Phase 0-F × Issue)

Epic #23 の全 21 Issue について、必要な capability と fallback 挙動をまとめます。

- `Required` は [`scripts/claude/detect-capabilities.sh`](../../scripts/claude/detect-capabilities.sh) が出力する capability 名で記述
- `Fallback` は capability が `unavailable` / `unknown` だった場合の consumer 側の期待挙動
- 本 Issue (#24) の時点では **契約定義のみ**。consumer 側の実装は Phase 1 Issue 1-1 以降で順次接続されます（ADR-05）

## Phase 0 — Bootstrap & capability detection

| Issue | Track | Required | Fallback | Notes |
|:-----:|:-----:|----------|----------|-------|
| 0-1 | Core | `gh_installed`, `jq`, `git` | preflight で error out（明確なエラーメッセージで停止） | 本 Issue |
| 0-2 | Core | `gh_authenticated` | `gh auth login` を案内して停止 | Phase 0 preflight 拡張 |

## Phase 1 — Core automation

| Issue | Track | Required | Fallback | Notes |
|:-----:|:-----:|----------|----------|-------|
| 1-1 | Core | `gh_authenticated`, `repo_write_access` | capability 参照実装の初出 | consumer 接続の最初 |
| 1-2 | Core | — | `make shell-lint` 用 shellcheck 統合 | shellcheck 未導入環境は skip + warn |
| 1-3 | Core | `projects_api_available` | `unknown`/`unavailable` なら Projects 連携を skip、Issue ラベルのみで代替 | GitHub Projects 連携 |
| 1-4 | Core | `codex_cli` | `unavailable` なら Codex レビューステップを skip + warn | `/2` のエージェントレビュー |
| 1-5 | Core | `gh_authenticated` | `unavailable` なら PR コマンドを停止 | `/6` PR 作成 |

## Phase 2 — Canonicalization

| Issue | Track | Required | Fallback | Notes |
|:-----:|:-----:|----------|----------|-------|
| 2-1 | Core | `.github/labels.json` | `legacy_alias_map` を使って既存日本語ラベルを canonical 英語ラベルへ機械的に移行 | `/1` / `/2` の canonical 化 |
| 2-2 | Core | `gh_authenticated` | unavailable で停止 | Issue template 整備 |
| 2-3 | Core | — | rules 更新のみ | commit-messages / branch-naming の英語化 |

## Phase 3 — Traceability automation

| Issue | Track | Required | Fallback | Notes |
|:-----:|:-----:|----------|----------|-------|
| 3-1 | Core | — | 静的スクリプトのみ | `validate_traceability_map.py` 拡張 |
| 3-2 | Core | — | 静的スクリプトのみ | 7-axis frontmatter lint |
| 3-3 | Core | `gh_authenticated` | PR コメント fallback（失敗時 warn） | CI への統合 |

## Phase 4 — Agent teams

| Issue | Track | Required | Fallback | Notes |
|:-----:|:-----:|----------|----------|-------|
| 4-1 | Core | `codex_cli` | `unavailable` なら単独 Claude 実行に退避 | `/5` verify quality-gate |
| 4-2 | Core | — | ロール定義のみ | agent-teams rules 拡張 |

## Optional A — Pencil design integration

| Issue | Track | Required | Fallback | Notes |
|:-----:|:-----:|----------|----------|-------|
| A-1 | Optional | `mcp_servers`, `pencil_mcp` | `unavailable` なら design スキルを doc-only で動作 | Pencil MCP 未設定でも可 |
| A-2 | Optional | `pencil_mcp` | unavailable で skip | `/2` で Pencil 差分チェック |

## Optional B — Computer Use automation

| Issue | Track | Required | Fallback | Notes |
|:-----:|:-----:|----------|----------|-------|
| B-1 | Optional | `computer_use` | `unavailable` なら UI 検証を手動に案内 | `/4` の UI 確認自動化 |
| B-2 | Optional | `computer_use` | 同上 | `/5` の UI 検証自動化 |

## Optional C — MCP ecosystem extensions

| Issue | Track | Required | Fallback | Notes |
|:-----:|:-----:|----------|----------|-------|
| C-1 | Optional | `mcp_servers` | doc-only（未設定でも可） | Gmail / Calendar / Notion 連携ガイド |
| C-2 | Optional | `mcp_servers` | 同上 | 追加 MCP server の onboarding テンプレ |

## Phase F — Finalization

| Issue | Track | Required | Fallback | Notes |
|:-----:|:-----:|----------|----------|-------|
| F-1 | Core | 全 capability | 全 Fallback 経路を `make bootstrap` → `/1` シナリオで E2E 検証 | リリース前最終チェック |

## 凡例

- **Core**: fork 直後の最短経路で必要な機能
- **Optional**: 外部ツール連携で強化される機能。未導入でも Core パスは成立する
- **Fallback**: `state` が `unavailable` または `unknown` の場合の consumer 側の期待挙動

## 関連リンク

- [scripts/claude/detect-capabilities.sh](../../scripts/claude/detect-capabilities.sh)
- [scripts/bootstrap.sh](../../scripts/bootstrap.sh)
- [docs/guides/bootstrap.md](../../docs/guides/bootstrap.md)
- [.github/labels.json](../../.github/labels.json)
