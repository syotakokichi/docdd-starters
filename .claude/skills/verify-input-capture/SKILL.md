---
name: verify-input-capture
description: |
  `/verify` Step 1 の入力固定手順を集約した read-only 補助 skill。
  Issue 番号・diff（merge-base 基準）・実行コンテキストを Bash tool 経由で取得し、
  後段（Step 2 以降の品質ゲート / Codex 差分レビュー）に渡す単一エントリポイントとして機能する。
  呼び出し前の input 収集のみを担当し、品質ゲートには関与しない。
disable-model-invocation: true
---

## 概要

### 目的

- `/verify` Step 1 の入力固定（Issue 内容 / diff / 実行コンテキスト）を **SSOT として集約**
  し、`verify.md` 本体は thin launcher に徹する（二重 SSOT 排除）
- `bang syntax` allowlist が `$()` を禁止しているため、Bash tool 経由で明示的に実行する
- Issue number の validation（digits-only）と `git merge-base` 失敗時の hard fail を
  本 skill 内で集中処理する

### 非ゴール

- 品質ゲート（`make test-backend` / `make test-frontend` / `make validate-claude`）の実行は Step 2 以降の責務。本 skill は diff の取得までで終了する
- Codex 差分レビュー（Step 5）の実行は `.claude/rules/codex-review.md` の SSOT に従う

### スキル分類

手順型（Step 1 の確定手順を実行する）。`disable-model-invocation: true` により自動起動せず、`.claude/commands/verify.md` Step 1 からのみ参照される thin launcher 専用 skill。

---

## 使い方

### いつ呼ぶか

- `/verify <issue-number>` コマンドの Step 1（変更内容と入力を固定）実行時のみ
- parent Claude が Bash tool を使える文脈で inline 実行する（Agent / Task で fork しない）

### 呼び出し元

[`.claude/commands/verify.md`](../../commands/verify.md) Step 1（thin launcher）からのみ参照される。

---

## 詳細

### 手順

#### Step 1-1: Issue 番号の digits-only 検証

引数 `<issue-number>` が **1 桁以上の純粋な数字**であることを確認する:

- 空文字 / 非数字 / 負数 / float / 空白混在 → hard fail（エラーメッセージ:
  `"invalid issue number: <given>. must be digits-only, positive integer."`）
- 先頭 0 許容 or 不許容: `0` のみは不許容（GitHub Issue は 1 origin）

Bash での実装例:

```bash
ISSUE_NUMBER="$1"
if ! echo "$ISSUE_NUMBER" | grep -qE '^[1-9][0-9]*$'; then
  echo "invalid issue number: $ISSUE_NUMBER. must be digits-only, positive integer." >&2
  exit 2
fi
```

#### Step 1-2: Issue 内容の取得

`gh issue view` で Issue 本文とコメントを取得する:

```bash
gh issue view "$ISSUE_NUMBER" --comments
```

確認する内容:

- Issue 本文の受け入れ条件
- `/develop` で記録した実装サマリー
- 変更ファイルと主要レイヤー

#### Step 1-3: diff 取得（merge-base 基準）

**`git diff main` は使わない**。worktree ブランチが main より古い場合、main 側で
追加された変更が「削除」として差分に含まれ、誤った判断の原因になる（幻影差分）。

```bash
# main 同期 + merge-base の確定
git fetch origin main
MERGE_BASE=$(git merge-base HEAD origin/main 2>/dev/null)
if [ -z "$MERGE_BASE" ]; then
  echo "git merge-base HEAD origin/main failed. ensure 'main' branch exists and is fetched." >&2
  exit 3
fi

# コミット済み差分（merge-base...HEAD）
git diff "$MERGE_BASE"...HEAD --stat
git diff "$MERGE_BASE"...HEAD --name-only

# ワーキングツリー差分（未コミット実装の取りこぼし防止）
git diff HEAD --stat
git diff HEAD --name-only

# Untracked ファイル
git ls-files --others --exclude-standard
```

失敗条件:

- `git merge-base HEAD origin/main` が非 0 exit → hard fail（main が存在しない / fetch されていない / detached HEAD 等）
- 出力が空文字 → hard fail（ブランチ構造異常）

#### Step 1-4: 実行コンテキストの記録

以下のテンプレートで記録する:

```markdown
### 実行コンテキスト
- セッション: /develop と同一 / 別セッション
- 実行場所: main repo / worktree
- worktree path: .claude/worktrees/issue-<number>(-<slug>) （worktree の場合）
- branch: <branch-name>
- merge-base: <commit-hash>
```

worktree の場合は merge-base と品質ゲートの結果がどの checkout で得られたかの
証跡になる。

### `verify.md` Step 1 との関係

[`.claude/commands/verify.md`](../../commands/verify.md) Step 1 は **本 skill への thin launcher** に徹する:

- `verify.md` 側: 「Step 1 は本 skill を参照」とだけ書き、具体的な実装手順の SSOT は本 skill に置く
- 本 skill 側: 上記 Step 1-1 〜 Step 1-4 の手順が SSOT
- 重要: `git merge-base` の raw Bash snippet は **本 skill 内**に集約する（二重 SSOT 禁止）

### 失敗時の取り扱い

本 skill の Step 1-1 / Step 1-3 で hard fail した場合、`/verify` フロー全体を中止し、
ユーザーに修正を促す:

- Step 1-1 失敗（`exit 2` hard fail — invalid issue number）: 正しい Issue 番号を再入力してもらう
- Step 1-3 失敗（`exit 3` hard fail — git merge-base 失敗 / detached HEAD / main 不在）: 「main ブランチが fetch されていない / 存在しない / detached HEAD」のいずれに該当するかをユーザーに確認してもらい、`git fetch origin main` など修正コマンドを提示する

**parent session（`.claude/commands/verify.md` Step 1）の義務**:

parent session（`verify.md` Step 1 の thin launcher）は本 skill の `exit 2` / `exit 3`（hard fail）を受けた場合、**`/verify` フロー全体を中止し、非 0 exit を伝播**する。Step 2 以降に進まない。`exit 2` / `exit 3` の両方とも parent が伝播する契約（片方だけ処理する設計は NG）。

---

## 関連ファイル

| パス | 役割 |
|------|------|
| [`.claude/commands/verify.md`](../../commands/verify.md) | 呼び出し元（Step 1 は本 skill を参照する thin launcher） |
| [`.claude/rules/codex-review.md`](../../rules/codex-review.md) | Step 5（Codex コード差分レビュー）の SSOT |
