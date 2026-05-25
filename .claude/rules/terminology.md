# Terminology - 用語 SSOT

DocDD Starter Kit における **canonical な用語の単一の真実の源（Single Source of Truth）**。
コマンド名・Phase 名・Wave 名・7 軸の正式表記をここで固定する。本ドキュメントと矛盾する記載を見つけたら、本ドキュメント側を正として書き換える。

> 本ドキュメントは [docs/guides/migration-from-legacy-commands.md](../../docs/guides/migration-from-legacy-commands.md) の上流 SSOT。マッピング表が両方に存在するが、移行ガイド側は派生物として「SSOT: `.claude/rules/terminology.md`」を明示する。

---

## スラッシュコマンド（canonical）

開発フロー順:

| canonical | 役割 | 実体ファイル |
|-----------|------|-------------|
| `/issue` | Issue 作成 | [.claude/commands/issue.md](../commands/issue.md) |
| `/plan` | 実装計画立案 + Codex 計画レビュー | [.claude/commands/plan.md](../commands/plan.md) |
| `/worktree` | worktree 作成 + ブランチ命名（並列開発の起点） | [.claude/commands/worktree.md](../commands/worktree.md) |
| `/develop` | 実装フェーズ（進行中ラベル設定 + 実装） | [.claude/commands/develop.md](../commands/develop.md) |
| `/verify` | 実装検証（品質ゲート + Codex 差分レビュー） | [.claude/commands/verify.md](../commands/verify.md) |
| `/review` | 独立レビュー（実装文脈外からの見落とし検出） | [.claude/commands/review.md](../commands/review.md) |
| `/pr` | PR 作成 | [.claude/commands/pr.md](../commands/pr.md) |
| `/merge` | PR マージ + worktree クリーンアップ | [.claude/commands/merge.md](../commands/merge.md) |
| `/discard-worktree` | 未マージ worktree の破棄 | [.claude/commands/discard-worktree.md](../commands/discard-worktree.md) |

ユーティリティ:

| canonical | 役割 | 実体ファイル |
|-----------|------|-------------|
| `/brainstorm` | 早期段階の壁打ち / アイデア整理 | [.claude/commands/brainstorm.md](../commands/brainstorm.md) |
| `/discuss` | 実装・設計の壁打ちセッション | [.claude/commands/discuss.md](../commands/discuss.md) |
| `/update-issue` | Issue 本文を実装変更に合わせて更新 | [.claude/commands/update-issue.md](../commands/update-issue.md) |
| `/skill-create` | 新しい skill を作成 | [.claude/commands/skill-create.md](../commands/skill-create.md) |
| `/tdd` | TDD ワークフロー（後続 Issue で本実装） | [.claude/commands/tdd.md](../commands/tdd.md) |
| `/slide` | Marp スライドの壁打ち | [.claude/commands/slide.md](../commands/slide.md) |
| `/commit-and-push` | 変更をコミットしてプッシュ | [.claude/commands/commit-and-push.md](../commands/commit-and-push.md) |

> テスト実行は Makefile target を使う: `make test` / `make test-backend` / `make test-frontend` / `make traceability` / `make validate-claude`
> 旧 `/run-tests` コマンドは削除済み。

---

## Legacy → canonical マッピング

| Legacy | Canonical | 注釈 |
|--------|-----------|------|
| `/1` | `/issue` | |
| `/2` | `/plan` | |
| `/3` | `/worktree` | ブランチ作成は worktree に統合済み |
| `/4` | `/develop` | |
| `/5` | `/verify` | |
| `/6` | `/pr` | |
| `/7` | `/merge` | |
| `/a` | `/worktree` | |
| `/b` | `/worktree`（新規）/ `git worktree list` + `cd`（既存移動） | |
| `/c` | `/discard-worktree` | 未マージ破棄のみ。マージ後 cleanup は `/merge` 内で実行 |
| `/run-tests` | `make test` / `make test-backend` / `make test-frontend` | プロジェクト Makefile の test 系ターゲット |

> 旧コマンドは Phase F-1（Issue #45）で物理削除済み。詳細は [docs/guides/migration-from-legacy-commands.md](../../docs/guides/migration-from-legacy-commands.md)。

---

## Wave / Phase 名

Wave / Phase は Epic #23（DocDD Starter Kit のロードマップ、CLOSED/COMPLETED）+ Epic #69（上流参照ハーネス追従、進行中）における作業区分。Epic 番号で disambiguate して両方の Wave / Phase を併存させる。

| 名称 | 意味 |
|------|------|
| **Wave 1 (Epic #23): Bootstrap & Capability** | Phase 0（preflight + capability detection）。fork 直後のセットアップ |
| **Wave 2 (Epic #23): Canonical Commands** | Phase 1〜2（Issue 駆動コマンドの canonical 化、ラベル整備） |
| **Wave 3 (Epic #23): Traceability & Quality** | Phase 3〜4（7 軸 traceability 検証 + agent teams） |
| **Wave 4 (Epic #23): Optional Integrations** | Optional A/B/C（Pencil / Computer Use / 追加 MCP） |
| **Phase F (Epic #23): Finalization** | リリース前最終チェック（E2E 検証 + cutover） |
| **Wave 0 (Epic #69): Re-baseline Audit** | 上流参照ハーネス baseline SHA `501049a` の drift 全件を 4 区分分類 + 採否台帳 v0.1 起票 |
| **Wave 1 (Epic #69): 安全 hardening クラスタ** | hooks 強化（block-dangerous / protect-files / validate-merge-cwd / develop-precommit-gate / gh-safe-comment）+ non-negotiable-gates rule |
| **Wave 2 (Epic #69): agents / references 再ベースライン** | 汎用化可能な agents 移植 + AskUserQuestion / 3-layer-architecture / agent-essence 等 references 反映 |
| **Wave 3 (Epic #69): multi-model-review 拡張 + MCP setup** | review-orchestrator / llm-debate / multi-model-review rule + mcp-setup reference |
| **Wave 4 (Epic #69): 定常追従ツール化** | manifest-diff / `make audit-upstream` / capability-matrix Phase G / skill-registry 自動生成 |
| **Finish (Epic #69): E-1** | README / CLAUDE.md / quickstart / customization 仕上げ（W1 + 採用済み Optional Wave 確定後） |

> Phase 細分（例: Phase F-1 = legacy shim 物理削除 [Epic #23] / Wave 0 = audit-only [Epic #69]）は各 Epic 本文を参照。新規参照は必ず Epic 番号で disambiguate して書く（書式は上表の `Wave N + 半角スペース + ASCII paren + Epic #番号 + ASCII paren` を踏襲）。

---

## DocDD 7 軸 — 正式表記

| 略号 | 正式名称 | パス |
|------|---------|------|
| BR | Business Requirement | `docs/7-axis/1_BR/` |
| UC | Use Case | `docs/7-axis/2_UC/` |
| DM | Data Model | `docs/7-axis/3_DM/` |
| SR / NSR | (Non-)Functional System Requirement | `docs/7-axis/4_SR/` |
| EXT | External Integration | `docs/7-axis/5_EXT/` |
| API | API Specification | `docs/7-axis/6_API/` |
| TC | Test Case | `docs/7-axis/7_TC/` |

> traceability map は `docs/testing/traceability/<domain>_map.json` に配置し、`make traceability` で検証する。

---

## 用語の追加・変更ルール

1. **新しい canonical 名を導入する場合**: まず本ドキュメントを更新し、次に依存ドキュメント（`commands/README.md`, `CLAUDE.md`, 各 SKILL / rules）を本ドキュメントに合わせて書き換える。
2. **本ドキュメントを変更する場合**: 派生物（[migration-from-legacy-commands.md](../../docs/guides/migration-from-legacy-commands.md), `commands/README.md` 等）も同じ PR 内で更新する。drift を残さない。
3. **コマンド削除・リネーム時**: `make validate-claude` PASS と全体の参照 grep（``rg -nP '`/<old>\b'`` 等）が 0 hit になることを確認する。

---

## 関連

- [docs/guides/migration-from-legacy-commands.md](../../docs/guides/migration-from-legacy-commands.md) — legacy → canonical 移行ガイド（本ドキュメントの派生物）
- [.claude/commands/README.md](../commands/README.md) — コマンド一覧
- [.claude/CLAUDE.md](../CLAUDE.md) — プロジェクト全体ガイド
