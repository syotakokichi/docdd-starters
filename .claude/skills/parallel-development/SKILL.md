---
name: parallel-development
description: |
  並列開発（Worktree）運用ルール。原則 worktree 推奨の判定 SSOT、Track A/B の分類（.env 要否）、
  複数エディタ並走パターン、ファイル競合回避、マージ順序、worktree 互換性サマリを提供。
  /worktree, /plan で参照される。
---

# 並列開発スキル

## 概要

`git worktree` コマンドを使った並列開発の運用ルールを定義する。

**非ゴール**: worktree の技術的仕組みそのものの説明（Git 公式ドキュメントを参照）。

## 使い方

以下のコマンドで参照される:
- `/worktree` — Worktree 作成 + ブランチセットアップ
- `/plan` — 計画立案時に worktree 要否を案内する SSOT として参照

> 後続 Issue でマージ・破棄系コマンド（`/merge` / `/discard-worktree`）を整備予定。本 Issue では `/7`（旧マージコマンド）と `/c`（旧 worktree 削除）が並存している。

---

## 判定 SSOT — 原則 worktree 推奨

> 本節は worktree 要否判定の **単一の真実の源（SSOT）**。
> `.claude/rules/issue-workflow.md` / `.claude/commands/{plan,worktree}.md` は本節を参照し、独自定義を書かない。

### 原則

**全 Issue で worktree を推奨する。** 複数エディタ・複数セッションでの並走前提では、Track を問わず worktree による checkout 隔離が必要。

- 他エディタの checkout 切替で state が壊れる問題を回避
- 同時マージのコンフリクト回避
- PR 時の後出しブランチ切り替え手順が不要

### 例外（main 直接作業が許容される条件）

**単独 sequential 作業**のみ許容する。以下を **すべて満たす** 場合に限る:

- 同時に他エディタセッションで作業していない（ユーザー自己申告ベース）
- 直列に 1 Issue ずつ処理する運用である

> エディタ枚数は Claude 側で決定論的に判定できない。ルールとしてはデフォルト worktree に倒し、例外適用はユーザーが明示的に宣言した場合に限る。

### 例外トリガー（ユーザー自己申告の substring 一致）

Claude 側は以下のいずれかの **substring** が直前のユーザー発話に含まれる場合のみ例外を適用する（full phrase 完全一致は要求しない。自然発話の variant を拾うため）:

- 日本語 substring: `worktree なし` / `worktree 不要` / `worktree いらな` / `単独 sequential` / `sequential モード` / `直接 main`
- 英語 substring: `sequential mode` / `solo sequential` / `no-worktree` / `no worktree` / `without worktree`

**判定ロジック**:
- 上記 substring の **いずれかを含む** → 例外適用
- 含まないが「近い表現」（例: `worktree やめる` / `worktree なくていい`）→ Claude は「`worktree なし` の意味でしょうか？」と 1 回確認してからユーザー回答に従う
- substring も近い表現も含まない → デフォルト（worktree 推奨）に倒す
- 過去メッセージや Issue 本文からの暗黙的推測は禁止（SSOT の同一性を保つため、判定は **直前のユーザー発話のみ** を見る）

**例外適用時の案内**:
substring 一致で例外を適用した場合も、Claude は「worktree を推奨しますが単独 sequential として main 直接作業で進めます」と 1 行案内してから進める。

### 判定フロー（Claude 側）

```
Issue が渡された
  └→ 直前メッセージに上記の定型句のいずれかが含まれるか？
       └→ Yes → main 直接作業を許容（推奨理由を 1 行案内してから進める）
       └→ No  → worktree 必須として `/worktree <N>` を案内する（デフォルト）
```

---

## 複数エディタ並走パターン

実運用では複数のエディタウィンドウ（VS Code / Cursor 等）を開き、並列に Issue を進める前提で設計する。

```
┌──────────────────────┬──────────────────────┐
│ Window 1: main       │ Window 2: worktree-A │
│ /7 / /1 等の管理系   │ Issue #X の実装      │
├──────────────────────┼──────────────────────┤
│ Window 3: worktree-B │ Window 4: worktree-C │
│ Issue #Y の実装      │ Issue #Z の実装      │
└──────────────────────┴──────────────────────┘
```

- **Window 1 (main)**: マージ・Issue 作成・ロードマップ更新など worktree 外コマンド
- **Window 2-N (worktree)**: それぞれ独立した Issue の `/plan` → `/develop` → `/verify` → `/6`

### 運用ルール

1. **main checkout は Window 1 が専有する**（他 Window が `git checkout main` すると Window 1 が壊れる）
2. 各 worktree は独自ブランチに checkout されているため checkout 干渉はない
3. Track A 同士でもモジュールが異なれば並列可（同モジュールは直列にする）

---

## Track 分類（`.env` 要否のみに限定）

Track A/B は **`.env` セットアップの要否判定のみ** に使う。worktree 要否とは独立。

| Track | 条件 | `.env` セットアップ |
|-------|------|:-------------------:|
| Track A | `apps/backend/` / `apps/frontend/` を変更する | 必要（`/worktree` Step 6 で symlink 作成）|
| Track B | `.claude/` / `docs/` / `.github/` / `scripts/` 等 | 不要（apps/ 非変更のため） |

> **判断に迷う場合**: `apps/` 配下を 1 行でも変更するなら Track A。
> **worktree 要否**: Track に関わらず原則 worktree 推奨（本節「判定 SSOT」参照）。

---

## ワークツリー構成

```
docdd-starters/                    # メインリポジトリ（Window 1 専有）
└── .claude/
    └── worktrees/                 # .gitignore 登録済み
        ├── issue-42/              # Window 2 用
        ├── issue-99/              # Window 3 用
        └── issue-123/             # Window 4 用
```

> `git worktree add .claude/worktrees/issue-<N> -b <branch>` で作成する（CLI-first 原則）。

---

## コマンドフロー

```
[メインリポジトリ (Window 1)]
/worktree <N>  → worktree 作成 + ブランチセットアップ + 別ウィンドウ起動の案内

[Worktree 内 (Window 2-N)]
/plan <N>       → 計画立案（未計画の場合）
/develop <N>    → 実装（旧 /4）
/verify <N>     → 実装検証（旧 /5）
/6              → PR 作成 ← worktree 内の最後のステップ

[メインリポジトリに戻る (Window 1)]
/7 <N>          → PR マージ + クリーンアップ（旧コマンド体系。後続 Issue で /merge に置換予定）
/c <N>          → 未マージ Worktree 削除（旧コマンド体系）
```

> **重要**: マージ操作（`gh pr merge` / `git worktree remove`）はメインリポジトリから実行する。
> worktree 内から自身を削除すると cwd が消えて後続ステップが失敗する。

---

## ファイル競合回避の原則

1. **同じモジュールに触れる Issue は直列にする**
2. **別モジュールの Track A 同士は並列可**（worktree で checkout 隔離されているため）
3. **Track B 同士も自由に並列可**
4. **Track A + Track B の並列は推奨**

## マージ順序の注意

1. **Track B を先にマージ** → Track A が最新の main を取り込める
2. Track A と B が独立なら順序は自由
3. **同モジュールの Track A 同士は必ず直列**

---

## Worktree 互換性サマリ

### ✅ 問題なし

| コマンド / 操作 | 理由 |
|----------------|------|
| `/plan` | コード読み取り + `gh` CLI のみ |
| `/develop` + `make test-backend` | DB はホスト共有 or Docker。PYTHONPATH は Makefile が設定 |
| `/verify` | コード読み取り + `gh` CLI + `make` のみ |
| `/6`（PR 作成） | `gh` CLI のみ |
| `git diff` / `git merge-base` | worktree でも正常動作 |
| `make validate-claude` | スクリプト経由のため worktree でも動作 |
| `make traceability` | スクリプト経由のため worktree でも動作 |
| pytest discovery | `pytest.ini` の `testpaths` は相対パス |

### ⚠️ 要注意

| 項目 | 問題 | 対策 |
|------|------|------|
| Backend `.env` | worktree に存在しない | Track A の `/worktree` Step 6 で symlink を作成（main 側に存在する場合のみ） |
| Frontend `.env.local` | worktree に存在しない | Track A の `/worktree` Step 6 で symlink を作成（main 側に存在する場合のみ） |
| `node_modules/` | worktree に存在しない | Track A の `/worktree` Step 7 で `npm --prefix apps/frontend install` |

### ❌ worktree で実行しない（運用ルール）

| 操作 | 理由 |
|------|------|
| マージ操作（`gh pr merge` / `git worktree remove`） | worktree 内から自身を削除すると cwd が消える / main 同期が silent にスキップされる |
| `make deploy-*` | デプロイはメインから |
| Terraform `apply` | 状態管理はメインから |
| Docker / Compose 操作 | 固定パス前提 |

> 上記はルールベース（hook 自動ブロックは未実装）。後続 Issue で `validate-merge-cwd.sh` 相当の hook 追加を検討する。

---

## 関連ファイル

- [.claude/commands/worktree.md](../../commands/worktree.md) — Worktree 作成（canonical）
- [.claude/commands/a.create-worktree.md](../../commands/a.create-worktree.md) — Worktree 作成（旧コマンド・並存）
- [.claude/commands/b.move-to-worktree.md](../../commands/b.move-to-worktree.md) — Worktree 移動（旧コマンド・並存）
- [.claude/commands/c.remove-worktree.md](../../commands/c.remove-worktree.md) — Worktree 削除（旧コマンド・並存）
- [.claude/rules/branch-naming.md](../../rules/branch-naming.md) — ブランチ命名規則
- [.claude/rules/cli-first.md](../../rules/cli-first.md) — CLI-first 原則
- [.claude/rules/agent-teams.md](../../rules/agent-teams.md) — エージェントチーム運用

---

## 📋 後続 Issue で導入予定（forward reference の隔離）

| 参照先（未存在） | 用途 | 予定 Issue |
|--------------|------|----------|
| `/merge`, `/discard-worktree` コマンド | canonical マージ・破棄フロー | 後続 Issue（2-2 想定） |
| `validate-merge-cwd.sh` hook | worktree 内からのマージ操作を決定論的にブロック | 後続 Issue（D-1 想定） |
