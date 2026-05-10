---
description: PR をマージし、ブランチ・worktree のクリーンアップ + 実装サマリー投稿を行います。
argument-hint: "[issue-number]"
disable-model-invocation: true
---
PR をマージしてクリーンアップを行ってください。

`argument-hint` が **角括弧** であることに注意。引数は任意です:

- 引数あり (Mode B): `/merge <N>` — Issue 番号 `<N>` の worktree を対象にマージ + worktree 削除
- 引数なし (Mode A): `/merge` — 現在のブランチに紐づく PR を対象にマージ + ブランチ削除（worktree 操作なし）

**`/pr` 完了後、main 側のターミナルで実行するコマンドです。**

---

## 目的

- CI 完了を待機してから PR をマージする
- main を最新化し、ローカルブランチ・リモート追跡ブランチをクリーンアップする
- Mode B では worktree も削除する
- Issue へ実装サマリーコメントを投稿し、Issue を Close する

## 標準フロー

```
/pr <N>         # PR 作成（前段）
/merge <N>      # 本コマンド（main 側で実行）
```

## Mode A / Mode B の振り分け

| Mode | 引数 | 用途 | cwd 制約 |
|:----:|:----:|------|---------|
| A | なし | 現在ブランチ（main 直作業 or 既に worktree 内）の PR をマージ | 制約なし（ただし worktree 内では Mode B 推奨） |
| B | `<N>` | Issue 番号で対応する worktree のマージ + 削除 | **main 側（primary worktree）から実行**（worktree 内からは禁止） |

> **重要**: Mode B を **worktree 内** から実行すると、`git worktree remove` が自身を削除しようとして失敗するため必ずメインリポジトリ側のターミナルから実行する。

---

## 手順

### Step 0: cwd プリフライト（Mode B のみ）

Mode B（引数あり）の場合、現在の cwd が主リポジトリ（primary worktree）かを確認する。worktree 内から実行された場合は中止する。

```bash
# Mode 判定
ARG="$ARGUMENTS"
if [ -n "$ARG" ]; then
  MODE="B"
else
  MODE="A"
fi

if [ "$MODE" = "B" ]; then
  # primary worktree のパスを取得（git worktree list の最初の行）
  MAIN_ROOT=$(git worktree list --porcelain | head -1 | sed 's/worktree //')
  CURRENT_ROOT=$(git rev-parse --show-toplevel)

  if [ "$CURRENT_ROOT" != "$MAIN_ROOT" ]; then
    echo "❌ Mode B (/merge <N>) は primary worktree から実行してください"
    echo "   現在地: $CURRENT_ROOT"
    echo "   primary: $MAIN_ROOT"
    echo "   対処: cd \"$MAIN_ROOT\" してから /merge $ARG を再実行する"
    exit 1
  fi
fi
```

> **逃げない**: cwd チェックを `--force` で抜けない。worktree 内からのマージは main の sync をスキップする SubsCore 由来の事故が再現するため、必ずメイン側で実行する。

### Step 1: 現在状態の確認

```bash
# 現在ブランチを確認
git branch --show-current

# 未コミット変更がないか確認
git status --porcelain

# Mode A: 現在ブランチに紐づく PR を取得
# Mode B: Issue 番号からブランチを推定
if [ "$MODE" = "A" ]; then
  PR_NUMBER=$(gh pr view --json number -q .number 2>/dev/null)
  if [ -z "$PR_NUMBER" ]; then
    echo "❌ 現在ブランチに紐づく PR が見つかりません"
    exit 1
  fi
else
  # Mode B: Issue から PR を逆引き
  PR_NUMBER=$(gh pr list --state open --search "in:body Closes #$ARG" --json number,headRefName --jq '.[0].number')
  if [ -z "$PR_NUMBER" ]; then
    echo "❌ Issue #$ARG に紐づく open な PR が見つかりません"
    exit 1
  fi
fi

echo "対象 PR: #$PR_NUMBER"
```

未コミット変更があれば、コミットしてから `/pr` 経由で push してください。`/merge` ではコミット作成を行いません。

### Step 2: CI 完了を待機

```bash
# CI が全て pass するまで待機
gh pr checks $PR_NUMBER --watch
```

> **重要**: `--watch` は CI 完了まで block する。失敗 check が残っている場合は `gh pr checks` の結果から原因を特定し、ブランチに戻って修正してから再 push する。

### Step 3: PR 詳細を取得し関連 Issue を特定

```bash
# PR 詳細取得
gh pr view $PR_NUMBER --json title,body,headRefName,state

# PR body から Closes #N を抽出
RELATED_ISSUES=$(gh pr view $PR_NUMBER --json body --jq .body | grep -oE "Closes #[0-9]+" | grep -oE "[0-9]+")
echo "関連 Issue: $RELATED_ISSUES"
```

### Step 4: マージ

```bash
# squash / merge / rebase はプロジェクトの方針に従う（既存 PR の運用と揃える）
# デフォルトは --merge（マージコミットを残す）。リポジトリのデフォルトに合わせる
gh pr merge $PR_NUMBER --merge
```

> **ブランチ削除は Step 5 / Step 6 で明示削除**: `gh pr merge` の組込ブランチ削除オプションは local 削除失敗（worktree が local branch を占有しているケース）で exit 1 → remote 削除もスキップする事故が再現するため使用しない。local は Step 5 / Step 6 の `git branch -d`、remote は Step 5 / Step 6 末尾の独立ブロックの `git push origin --delete` で分離して実行する。`Closes #<N>` による Issue auto close は GitHub 側で実行されるが、Step 7 で明示的に確認する。

### Step 5: main 同期 + ローカルブランチ削除

worktree から Mode A を実行している場合、`git checkout main` は primary 側で既に main がチェックアウトされているため失敗する。cwd が primary か worktree かを判定して分岐する。

```bash
# primary worktree のパスを取得
MAIN_ROOT=$(git worktree list --porcelain | head -1 | sed 's/worktree //')
CURRENT_ROOT=$(git rev-parse --show-toplevel)
MERGED_BRANCH=$(gh pr view $PR_NUMBER --json headRefName --jq .headRefName)

if [ "$CURRENT_ROOT" = "$MAIN_ROOT" ]; then
  # primary worktree から実行中: main に切り替えて pull + ローカルブランチ削除
  git checkout main
  git pull origin main

  if [ "$MODE" = "A" ] && [ -n "$MERGED_BRANCH" ] && [ "$MERGED_BRANCH" != "main" ]; then
    git branch -d "$MERGED_BRANCH" 2>/dev/null || \
      echo "⚠️  ローカルブランチ $MERGED_BRANCH は既に削除済みか、未マージです"
  fi
else
  # 連結 worktree から Mode A 実行: primary で main がチェックアウト済みのためここでは checkout しない
  # remote の main 最新を取り込むだけ（ローカル main の fast-forward は primary 側で実施）
  git fetch origin main
  echo "ℹ️  Mode A を worktree 内から実行: primary worktree（$MAIN_ROOT）に戻ってから 'git checkout main && git pull' を実行してください"
  echo "ℹ️  ローカルブランチ $MERGED_BRANCH の削除も primary 側で実施してください（現在 worktree がそのブランチを保持しているため）"
fi

# Mode A: remote 削除（cwd / worktree 有無に依存しない独立ブロック）
# 旧 `gh pr merge --delete-branch` は local 削除失敗時に remote 削除もスキップする事故があったため、
# remote 削除は cwd 分岐の外に置き、primary でも連結 worktree でも確実に発火させる
if [ "$MODE" = "A" ] && [ -n "$MERGED_BRANCH" ] && [ "$MERGED_BRANCH" != "main" ]; then
  # MERGED ガード: merge queue / auto-merge 環境で `gh pr merge` が queued/open のまま戻る場合に
  # head branch を merge 前に消して PR を unmergeable にする事故を防ぐ
  PR_STATE=$(gh pr view "$PR_NUMBER" --json state --jq .state 2>/dev/null)
  if [ "$PR_STATE" != "MERGED" ]; then
    echo "⚠️  PR #$PR_NUMBER は MERGED 状態ではありません（state: ${PR_STATE:-unknown}）。remote ブランチ削除はスキップ"
  else
    IS_CROSS_REPO=$(gh pr view "$PR_NUMBER" --json isCrossRepository --jq .isCrossRepository 2>/dev/null)
    if [ "$IS_CROSS_REPO" = "true" ]; then
      echo "ℹ️  PR #$PR_NUMBER は fork からの PR。remote ブランチ削除はスキップ"
    else
      err=$(git push origin --delete "$MERGED_BRANCH" 2>&1) || \
        echo "⚠️  リモートブランチ $MERGED_BRANCH の削除に失敗: $err"
    fi
  fi
fi

# リモート追跡ブランチを整理
git remote prune origin
```

### Step 6: worktree 削除（Mode B のみ）

```bash
if [ "$MODE" = "B" ]; then
  WORKTREE_PATH=".claude/worktrees/issue-$ARG"
  MERGED_BRANCH=$(gh pr view $PR_NUMBER --json headRefName --jq .headRefName)

  if [ -d "$WORKTREE_PATH" ]; then
    # worktree 内に未コミット変更が残っていないか確認
    git -C "$WORKTREE_PATH" status --porcelain | head

    # worktree を削除（マージ済みなので force は不要だが、念のため一覧で確認してから）
    git worktree list
    git worktree remove "$WORKTREE_PATH"

    # worktree 用のローカルブランチを削除
    if [ -n "$MERGED_BRANCH" ] && [ "$MERGED_BRANCH" != "main" ]; then
      git branch -d "$MERGED_BRANCH" 2>/dev/null || \
        echo "⚠️  ローカルブランチ $MERGED_BRANCH は既に削除済みか、未マージです"
    fi
  else
    echo "⚠️  worktree $WORKTREE_PATH が見つかりません（既に削除済み？）"
  fi

  # remote 削除（worktree 有無に依存しない独立ブロック）
  # `if [ -d "$WORKTREE_PATH" ]` の **外** に配置することで、
  # worktree 既削除（再実行）/ WORKTREE_PATH 不在でも remote 削除を確実に発火させる
  if [ -n "$MERGED_BRANCH" ] && [ "$MERGED_BRANCH" != "main" ]; then
    # MERGED ガード: merge queue / auto-merge 環境で `gh pr merge` が queued/open のまま戻る場合に
    # head branch を merge 前に消して PR を unmergeable にする事故を防ぐ
    PR_STATE=$(gh pr view "$PR_NUMBER" --json state --jq .state 2>/dev/null)
    if [ "$PR_STATE" != "MERGED" ]; then
      echo "⚠️  PR #$PR_NUMBER は MERGED 状態ではありません（state: ${PR_STATE:-unknown}）。remote ブランチ削除はスキップ"
    else
      IS_CROSS_REPO=$(gh pr view "$PR_NUMBER" --json isCrossRepository --jq .isCrossRepository 2>/dev/null)
      if [ "$IS_CROSS_REPO" = "true" ]; then
        echo "ℹ️  PR #$PR_NUMBER は fork からの PR。remote ブランチ削除はスキップ"
      else
        err=$(git push origin --delete "$MERGED_BRANCH" 2>&1) || \
          echo "⚠️  リモートブランチ $MERGED_BRANCH の削除に失敗: $err"
      fi
    fi
  fi

  # Mode B 用 remote-tracking ref 整理（Step 5 の `git remote prune origin` は
  # 上記 Mode B remote 削除より前に実行されているため、削除した remote ブランチに
  # 対応するローカル追跡 ref が残っている。ここで再 prune して checklist を成立させる）
  git remote prune origin
fi
```

> **未マージ変更がある場合**: `git worktree remove` は失敗する。意図せず未マージの場合は中断してユーザーに確認する。明示的に破棄したい場合は `/discard-worktree <N>` を使う。

### Step 7: Issue を明示 Close + 実装サマリー投稿

`Closes #<N>` による auto close は GitHub 側で実行されるが、明示的に状態を確認し、実装サマリーを投稿する。

```bash
for ISSUE in $RELATED_ISSUES; do
  # Issue が Close 済みか確認（auto close されているはず）
  STATE=$(gh issue view $ISSUE --json state -q .state)
  echo "Issue #$ISSUE: $STATE"

  # 念のため明示的に close（既に closed なら no-op）
  gh issue close $ISSUE 2>/dev/null || true

  # 実装サマリーをコメント投稿
  # 構成は `.claude/templates/implementation-summary-comment.md` を踏襲
  # （/develop で投稿済みのサマリーをベースに、PR 番号 + マージ状況を追記する形でも可）
  gh issue comment $ISSUE --body "## マージ完了（/merge）

### Status
- マージ済み: PR #$PR_NUMBER
- マージ先: main
- ブランチ削除: 済 / worktree 削除: $([ "$MODE" = "B" ] && echo "済" || echo "N/A（Mode A）")

### 関連
- PR: #$PR_NUMBER
- /develop 実装サマリー / /verify 検証結果は本 Issue 内の既存コメント参照
"
done
```

> **/develop 実装サマリーとの責務分離**: 実装内容の詳細は `/develop` Phase 5 で `.claude/templates/implementation-summary-comment.md` の形式で既に投稿済み。`/merge` ではマージ完了の事実のみを 1 コメントで残す。

### Step 8: 最終確認

```bash
git branch -a
git log --oneline -5
git worktree list
```

### Step 9: 完了報告

```
マージ完了:
  - PR: #<PR_NUMBER>
  - 関連 Issue: #<N>（Close 済み）
  - Mode: A / B
  - worktree: 削除済 / N/A

次のステップ:
  - 次の Issue へ: /issue / /worktree <次の N>
```

> **本 Issue で得た学びの体系反映**: 実装中に発見した再利用可能な知見（新パターン / harness 改善 / フィードバック）が本 Issue にあれば、**次の Issue に進む前に** `.claude/skills/update-knowledge/SKILL.md` を参照し、skills / rules / commands / templates のうち適切な反映先を判断する（一時的な情報・コードから読み取れることは memory に逃がす or 反映しない）。

---

<!-- Optional: stg sync (デフォルト無効)
   高リスク変更（決済 / 認証 / マイグレーション / 外部連携）をマージ後に
   ステージング環境を即時更新したい場合のみ、以下のコマンドをコメントアウト解除する。
   通常は `/verify` Phase 4 で事前確認済みのため、本ステップは不要。

   make deploy-stg                # ステージングへデプロイ
   # make stg-migrate             # マイグレーションがある場合のみ

   実行後は STG で疎通確認し、結果を Issue コメントに追記する。
-->

---

## チェックリスト

マージ前に確認:

- [ ] CI が全て PASS している（`gh pr checks` で確認）
- [ ] レビュー承認が必要なリポジトリでは approval を得ている
- [ ] PR body に `Closes #<N>` が含まれている
- [ ] Mode B の場合: cwd が primary worktree（main 側）であること

マージ後に確認:

- [ ] 関連 Issue が Close されている
- [ ] ローカルブランチが削除されている（Mode A）/ worktree が削除されている（Mode B）
- [ ] リモートブランチが削除されている（`git ls-remote --heads origin "$MERGED_BRANCH"` が空）
- [ ] `git remote prune origin` でリモート追跡ブランチが整理されている

---

## 失敗時の対処

| 状況 | 対処 |
|------|------|
| CI が失敗している | ブランチに戻って修正 → push → `/merge` 再実行 |
| マージコンフリクト | ブランチで `git rebase origin/main` → コンフリクト解消 → push |
| Mode B で worktree 内から実行した | Step 0 で停止する。`cd "$MAIN_ROOT"` してから再実行 |
| 未マージで worktree を削除したい | `/discard-worktree <N>` を使う（`/merge` ではなく） |
| Issue が auto close されていない | `gh issue close <N>` を手動実行（Step 7 でも実行している） |
| （旧仕様起因）`Closes #N` 後に origin にブランチが残っている | 旧 `/merge` は worktree 占有時に local 削除失敗 → remote もスキップする問題があった。手動で `git push origin --delete <branch>` を実行。本コマンドは Step 5 / Step 6 で明示削除済み |

---

## 次のステップ

PR をマージし、worktree とブランチをクリーンアップした。

```
---
✨ **このセッションで進んだこと**
- PR #<PR_NUMBER> マージ（merge / squash / rebase: <strategy>）
- main 同期 / ローカルブランチ削除 / リモートブランチ削除 / worktree 削除（Mode B）
- 関連 Issue Close: #<N1> #<N2> / 実装サマリーコメント投稿済み

🎯 **これによって変わること**
- DocDD 7軸: BR=<…> / UC=<…> / DM=<…> / SR=<…> / EXT=<…> / API=<…> / TC=<…>（本流反映完了）
- Issue #<N> がクローズされ、main が最新化された状態で次の Issue に着手できる

📋 **次のステップ**
- 次の Issue へ: `/issue` で起票、または `/worktree <次の N>` で並列着手
---
```

コピペ用:

```bash
/issue
```

---

## 注意事項

- `/merge` は **PR が存在し、CI が PASS していること** が前提
- 未コミット変更は **`/merge` ではなく `/pr`** で扱う
- worktree 内からは **Mode A のみ** 許容（Mode B は cwd プリフライトで停止）
- `--no-verify` / `--force` で hook をスキップしない

---

## 📋 後続 Issue で導入予定（forward reference の隔離）

| 参照先（未存在） | 用途 | 予定 Issue |
|--------------|------|----------|
| `.claude/hooks/validate-merge-cwd.sh` | worktree 内からの `/merge` を hook で deny（Step 0 の決定論的補強） | 後続 Issue（1-1 baseline 拡張 or 別 Issue） |
| `landing_path_state` preflight | UI 変更時の auto close 抑止判定 | **持ち込まない**（`screen-verify` がスコープ外のため） |
| `roadmap.md` 更新ステップ | リリース計画との突合 | starter に roadmap なし。**持ち込まない** |
| `ephemeral-session-memory` cleanup | マージ後の session memory 退避 | 後続 Slice（未起票） |
| stg 自動同期（`make deploy-*-stg` / `make stg-migrate`） | high-risk 変更の stg 即時反映 | **オプトイン**（本ファイル末尾のコメントブロック参照、デフォルト無効） |

Remember to use the GitHub CLI (`gh`) for all GitHub-related tasks.
