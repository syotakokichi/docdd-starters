---
description: 未マージ worktree を破棄し、ブランチをクリーンアップします。
argument-hint: "<issue-number>"
disable-model-invocation: true
---
Issue #$ARGUMENTS の worktree を破棄してください。

**未マージのまま作業を中断する場合のコマンドです。マージ済みの worktree クリーンアップは `/merge` 内で実行されるため、本コマンドは不要です。**

---

## 目的

- 作業を取りやめた / マージしないことが確定した Issue の worktree を削除する
- 関連するローカル / リモートブランチも削除する
- main 側のリポジトリ状態をクリーンに保つ

## 標準フロー

```
/worktree <N>           # worktree 作成（前段）
... 作業中断・破棄判断 ...
/discard-worktree <N>   # 本コマンド
```

> **マージ済みの場合**: `/merge <N>` が worktree 削除まで担うため、本コマンドは使わない。

## 入力前提

- 削除して構わないことをユーザーが意思確認済み
- 未マージの変更を後で参照する必要がない（必要なら branch を残す選択肢あり）

---

## 手順

### Step 0: cwd プリフライト

worktree 内から本コマンドを実行すると、自身を削除しようとして失敗するため、必ず main 側（primary worktree）から実行する。

```bash
# primary worktree のパスを取得
MAIN_ROOT=$(git worktree list --porcelain | head -1 | sed 's/worktree //')
CURRENT_ROOT=$(git rev-parse --show-toplevel)

if [ "$CURRENT_ROOT" != "$MAIN_ROOT" ]; then
  echo "❌ /discard-worktree は primary worktree から実行してください"
  echo "   現在地: $CURRENT_ROOT"
  echo "   primary: $MAIN_ROOT"
  echo "   対処: cd \"$MAIN_ROOT\" してから /discard-worktree $ARGUMENTS を再実行する"
  exit 1
fi
```

> **逃げない**: cwd チェックを `--force` で抜けない。worktree 内からの削除は `git worktree remove` が自身を巻き込んで状態破壊するため必ず main 側で実行する。

### Step 1: 対象 worktree を動的に検索

worktree のディレクトリ命名 SSOT は `.claude/skills/parallel-development/SKILL.md`。標準では `.claude/worktrees/issue-<N>/` だが、変則的なパスでも対応できるよう `git worktree list` から動的に取得する。

```bash
# 対象 worktree を検索（ブランチ名 / パスのいずれかで一致するものを抽出）
git worktree list --porcelain

# 期待パス
WORKTREE_PATH=".claude/worktrees/issue-$ARGUMENTS"

# 存在確認
if [ ! -d "$WORKTREE_PATH" ]; then
  # 動的検索フォールバック（ブランチ名で一致するものを探す）
  # 注意: "issue-36" が "issue-360" / "issue-3601" に誤マッチするのを防ぐため、
  # issue 番号の直後が `-` または行末であることを正規表現で要求する
  WORKTREE_PATH=$(git worktree list --porcelain | \
    awk -v issue="$ARGUMENTS" '
      /^worktree / { path=$2 }
      /^branch / && $0 ~ "issue-"issue"(-|$)" { print path; exit }
    ')
  if [ -z "$WORKTREE_PATH" ]; then
    echo "❌ Issue #$ARGUMENTS に対応する worktree が見つかりません"
    echo "   現在の worktree 一覧:"
    git worktree list
    exit 1
  fi
fi

echo "対象 worktree: $WORKTREE_PATH"
```

### Step 2: ブランチ名と状態を確認

```bash
# worktree のブランチ名
WORKTREE_BRANCH=$(git -C "$WORKTREE_PATH" branch --show-current)
echo "ブランチ: $WORKTREE_BRANCH"

# 未コミット変更があるか確認
echo "--- 未コミット変更 ---"
git -C "$WORKTREE_PATH" status --porcelain

# untracked / staged / unstaged の概要
echo "--- 差分概要 ---"
git -C "$WORKTREE_PATH" diff HEAD --stat
git -C "$WORKTREE_PATH" ls-files --others --exclude-standard

# main からの差分（コミット済み分）
git fetch origin main
MERGE_BASE=$(git -C "$WORKTREE_PATH" merge-base HEAD origin/main 2>/dev/null)
if [ -n "$MERGE_BASE" ]; then
  echo "--- main からの差分（コミット済み） ---"
  git -C "$WORKTREE_PATH" log --oneline "$MERGE_BASE"..HEAD
fi
```

### Step 3: ユーザー意思確認

未コミット変更や未 push コミットがある場合は **必ずユーザーに確認** する。意思確認なしで `--force` での削除をしない。

```
削除前確認:
  - worktree: <WORKTREE_PATH>
  - ブランチ: <WORKTREE_BRANCH>
  - 未コミット変更: あり / なし
  - 未 push コミット: N 件
  - main からの差分: N コミット

破棄しますか？（y/N）
```

確認パターン:

| 状態 | 推奨アクション |
|------|-------------|
| 未コミット変更なし、push 済 | そのまま削除可 |
| 未コミット変更あり | 「`/commit-and-push` でコミットしてから破棄しますか？」と問い直す |
| 未 push コミットあり | 「リモートに残さなくて良いか」を確認。後で復元したい場合は branch だけ残す選択肢を提示 |
| main からの差分が大きい | 本当に破棄して良いかを再確認 |

### Step 4: worktree 削除（強制削除フロー）

ユーザー承認後に削除する。`--force` は **未コミット変更がある状態で削除する** 場合のみ使用する。

```bash
# 通常削除（クリーンな状態）
git worktree remove "$WORKTREE_PATH"

# 強制削除（未コミット変更あり、Step 3 でユーザー承認済みの場合のみ）
# git worktree remove --force "$WORKTREE_PATH"
```

> **`--force` の使用条件**: Step 3 でユーザーが明示的に承認した場合のみ。Claude が独断で `--force` を付けない。

### Step 5: ローカルブランチ削除

```bash
if [ -n "$WORKTREE_BRANCH" ] && [ "$WORKTREE_BRANCH" != "main" ]; then
  # 通常削除（マージされていない場合は拒否される）
  git branch -d "$WORKTREE_BRANCH" 2>/dev/null

  # 拒否された場合の強制削除（Step 3 でユーザー承認済みの前提）
  if [ $? -ne 0 ]; then
    echo "ローカルブランチ $WORKTREE_BRANCH は未マージです。強制削除しますか？"
    # ユーザーが yes と答えた場合のみ:
    # git branch -D "$WORKTREE_BRANCH"
  fi
fi
```

### Step 6: リモートブランチ削除（任意）

リモートに push 済みのブランチを削除する場合:

```bash
# リモート追跡ブランチが存在するか確認
git ls-remote --heads origin "$WORKTREE_BRANCH"

# 削除（ユーザー承認後のみ）
# git push origin --delete "$WORKTREE_BRANCH"
```

> **リモート削除は破壊的**: チームで共有していた場合の影響を必ず確認する。ユーザー承認なしに実行しない。

### Step 7: 後処理 + 確認

```bash
# リモート追跡ブランチを整理
git remote prune origin

# 残存 worktree を確認
git worktree list

# ローカルブランチを確認
git branch -a
```

### Step 8: 完了報告

```
worktree 破棄完了:
  - worktree: <WORKTREE_PATH> 削除済
  - ローカルブランチ: <WORKTREE_BRANCH> 削除済 / 残置（理由）
  - リモートブランチ: 削除済 / 未操作

備考:
  - Issue #$ARGUMENTS 自体は Open のまま（必要なら手動で Close）
```

---

## チェックリスト

破棄前に確認:

- [ ] cwd が primary worktree（main 側）であること
- [ ] 対象 worktree が `git worktree list` に存在すること
- [ ] 未コミット変更 / 未 push コミットの有無を確認した
- [ ] ユーザーに破棄の意思確認をした（特に未コミット変更がある場合）
- [ ] `--force` を使う場合はユーザーが明示的に承認した

破棄後に確認:

- [ ] `git worktree list` から対象が消えている
- [ ] ローカルブランチが削除されている（または意図的に残置）
- [ ] リモートブランチの状態が意図通り（削除済 / 未操作）
- [ ] Issue 側の状態（Open のまま / 別途 Close するか）を判断した

---

## 注意事項

- 本コマンドは **未マージ worktree の破棄** 専用。マージ済みは `/merge` 内で削除される
- `--force` を独断で使わない（ユーザー意思確認を経てから）
- リモートブランチ削除はチーム共有の影響を必ず確認する
- worktree 内から実行しない（Step 0 で停止する）

---

## 失敗時の対処

| 状況 | 対処 |
|------|------|
| `git worktree remove` が失敗（未コミット変更） | 状態を確認し、ユーザーが破棄承認したら `--force` で再実行 |
| ブランチ削除が `not fully merged` で拒否 | ユーザー承認後に `-D`（強制削除）に切替 |
| worktree が見つからない | 既に削除済みかパスが変則的。`git worktree list` で確認 |
| ディレクトリだけ残ってしまった | `git worktree prune` で worktree メタデータを整理してから手動 `rm -rf` |

---

## 次のステップ

Worktree とブランチを破棄した。Issue は Open のまま、必要なら手動で Close。

```
---
✨ **このセッションで進んだこと**
- worktree `<WORKTREE_PATH>` 削除
- ローカルブランチ `<BRANCH>`: 削除済 / 残置（理由: <reason>）
- リモートブランチ: 削除済 / 未操作

🎯 **これによって変わること**
- 未マージのまま中断した作業が main 側のリポジトリ状態から消え、`git worktree list` がクリーンになる
- 後続で別の Issue 番号で `/worktree` を呼べる空き状態に戻る

📋 **次のステップ**
- Issue #<N>（Open のまま / 必要なら `gh issue close <N>`）
- 次の Issue へ: `/issue` または `/worktree <次の N>`
---
```

コピペ用:

```bash
/issue
```

---

## 📋 後続 Issue で導入予定（forward reference の隔離）

| 参照先（未存在） | 用途 | 予定 Issue |
|--------------|------|----------|
| `.claude/hooks/validate-merge-cwd.sh` | worktree 内からの `/discard-worktree` を hook で deny（Step 0 の決定論的補強） | 後続 Issue（1-1 baseline 拡張 or 別 Issue） |
| `.claude/skills/ephemeral-session-memory/SKILL.md` | 破棄前の session memory 退避 | 後続 Slice（未起票） |

Remember to use the GitHub CLI (`gh`) for all GitHub-related tasks.
