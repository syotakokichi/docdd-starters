# Migration from Legacy Commands

旧コマンド体系（`/1`–`/7`, `/a`–`/c`, `/run-tests`）から canonical コマンド体系への移行ガイドです。

> **SSOT**: コマンド名の単一の真実の源は [.claude/rules/terminology.md](../../.claude/rules/terminology.md)。本ドキュメントはその派生物として、移行コンテキストを補足説明する。

---

## 概要

Phase F-1（Issue #45）で旧コマンド体系を物理削除し、SubsCore 同型の canonical コマンド体系に統一しました。

**旧コマンド（削除済み）:**
- `/1` 〜 `/7`（Issue 駆動開発フロー）
- `/a` / `/b` / `/c`（Worktree 管理）
- `/run-tests`（テスト実行案内）

**新コマンド（canonical）:**
- `/issue` / `/plan` / `/worktree` / `/develop` / `/verify` / `/review` / `/pr` / `/merge` / `/discard-worktree`
- テスト実行は `make` ターゲットへ移行

---

## 対応表

> SSOT: [.claude/rules/terminology.md](../../.claude/rules/terminology.md)

| Legacy | Canonical | 注釈 |
|--------|-----------|------|
| `/1` | `/issue` | Issue 作成 |
| `/2` | `/plan` | 計画立案 |
| `/3` | `/worktree` | ブランチ作成は `/worktree` に統合済み |
| `/4` | `/develop` | 実装フェーズ |
| `/5` | `/verify` | 実装検証 |
| `/6` | `/pr` | PR 作成 |
| `/7` | `/merge` | PR マージ + worktree クリーンアップ |
| `/a` | `/worktree` | worktree 作成 |
| `/b` | `/worktree`（新規） / `git worktree list` + `cd`（既存移動） | 既存 worktree への移動は CLI を使う |
| `/c` | `/discard-worktree` | 未マージ破棄のみ。マージ後 cleanup は `/merge` 内で実行 |
| `/run-tests` | `make test` / `make test-backend` / `make test-frontend` | プロジェクト Makefile の test 系ターゲット |

---

## フローの違い

### 旧フロー

```
/1 → /2 → /3 → /4 → /5 → /6 → /7
                                 ↑
                       /a → /b →  ← /c
```

### canonical フロー

```
/brainstorm → /issue → /plan → /worktree → /develop → /verify → /review → /pr → /merge
                                                                                  ↑
                                                           /discard-worktree     ←
```

主な改善点:
- **`/brainstorm` を必須化**: 新規 Issue の前に Goal / Non-goals / Options / Risks / Issue split を固定し、Issue 本文に保存。
- **`/worktree` がブランチ作成を統合**: 旧 `/3`（ブランチ作成）と `/a`（worktree 作成）を 1 コマンドに集約。
- **`/review` を独立コマンド化**: `/verify`（実装者主体の検証）と `/review`（実装文脈外からの独立レビュー）を分離。
- **`/merge` がマージ + cleanup を統合**: 旧 `/7` の責務を引き継ぎ、worktree 削除まで一括で実行。
- **`/discard-worktree` を分離**: マージしないまま破棄するケースを明示的に扱う。

---

## よくある質問

### Q1. 既存の Issue / PR の本文に `/1` `/2` ... が残っているがどうすればよい？

過去 Issue / PR は履歴として残しても問題ありません。
**新規に書く文書では canonical 名を使ってください**。Codex / `/plan` レビューで自動的に旧表記が検出されます。

### Q2. `/run-tests` の代わりに何を使えばよい？

プロジェクト Makefile の test 系ターゲットを直接実行してください:

```bash
make test                  # backend + frontend 両方
make test-backend          # バックエンドのみ
make test-frontend         # フロントエンドのみ
make traceability          # 7 軸 traceability 検証
make validate-claude       # `.claude/` 配下の frontmatter 検証
```

Makefile target の存在は `make -n test` で dry-run 確認できます。

### Q3. なぜ shim（旧コマンド名で canonical へ転送するエイリアス）を残さなかった？

- shim は Phase 2-3（Issue #41）で 1 週間 deprecation 期間として用意していました
- Phase F-1（Issue #45）でユーザーと合意のうえ前倒しで物理削除し、SubsCore と同型のコマンド体系を即時確立
- 並存期間を長く取ると「どちらを使うべきか」の混乱が長引くため、cutover を一気に完了

### Q4. `/b`（旧 worktree 移動）の代替は？

| ケース | コマンド |
|--------|---------|
| 新規 worktree を作成して移動 | `/worktree <N>` |
| 既存 worktree に移動 | `git worktree list` で一覧確認 → `cd .claude/worktrees/issue-<N>` |

### Q5. 旧コマンドを誤って入力したらどうなる？

`/1` `/2` ... のファイルは存在しないため、Claude Code は「コマンドが見つからない」と返します。
本ドキュメントの対応表を参照して canonical 名で再入力してください。

---

## 関連

- [.claude/rules/terminology.md](../../.claude/rules/terminology.md) — canonical 用語 SSOT
- [.claude/commands/README.md](../../.claude/commands/README.md) — canonical コマンド一覧
- [.claude/CLAUDE.md](../../.claude/CLAUDE.md) — プロジェクト全体ガイド
- Issue #45 — 本移行を実施した Issue（Phase F-1: legacy shim 物理削除）
