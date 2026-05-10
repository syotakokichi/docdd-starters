---
description: Issue 検証完了後に Pull Request を作成します。
argument-hint: "<issue-number>"
disable-model-invocation: true
---
Issue #$ARGUMENTS の Pull Request を作成してください。

**`/verify` 完了後に実行するコマンドです。レビューが完了していない場合は先に `/review <N>` を実行してください。**

---

## 目的

- 実装内容を main に取り込むための PR を作成する
- PR 本文に `Closes #<N>` を含めて auto close を有効化する
- commit message と PR body の責務を分離する

## 標準フロー

```
/verify <N>     # 検証完了（前段）
/review <N>     # 独立レビュー（推奨）
/pr <N>         # PR 作成（本コマンド）
/merge <N>      # マージ + クリーンアップ
```

## 入力前提

- ローカルブランチが Issue 用ブランチ（`<type>/issue-<N>-<short-description>`）になっていること
- `/verify` コメントが Issue に投稿されていること
- 🔴 必須指摘が解消済みであること

---

## 手順

### Step 1: Pre-flight gate（事前チェック）

PR 作成前に最低限の前提が揃っているかを確認する。

```bash
# 現在のブランチを確認（main では PR を作らない）
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" = "main" ]; then
  echo "❌ main ブランチからは PR を作成できません。先に /worktree $ARGUMENTS で作業ブランチを作成してください"
  exit 1
fi

# Issue が存在し、open であることを確認
gh issue view $ARGUMENTS --json state,number,title

# /verify のコメントが投稿済みかを確認（最低限の証跡）
if ! gh issue view $ARGUMENTS --comments | grep -qE "実装検証結果（/verify）"; then
  echo "❌ /verify コメントが見つかりません。\`/verify $ARGUMENTS\` を先に実行してください"
  exit 1
fi
```

> **逃げない**: `/verify` を飛ばしての PR 作成は禁止。完了品質ルール（[`.claude/rules/completion-quality.md`](../rules/completion-quality.md)）と完了主張前のゲート SSOT（[`.claude/skills/verification-before-completion/SKILL.md`](../skills/verification-before-completion/SKILL.md)）に従い、検証コメントが揃ってから先に進む。Pre-flight gate は **warning ではなく hard failure（exit 1）** にしてゲートを担保する。

### Step 2: 差分確認

main からの差分を確認し、PR に含める範囲を把握する。

```bash
# main 同期（リモート main の最新を取得）
git fetch origin main

# merge-base 算出
MERGE_BASE=$(git merge-base HEAD origin/main)

# 差分の概要
git diff "$MERGE_BASE"...HEAD --stat
git diff "$MERGE_BASE"...HEAD --name-only

# 未コミットの変更も含める
git status --porcelain
```

確認ポイント:

- 想定外のファイルが含まれていないか（`.env` / 一時ファイル / 別 Issue のファイル）
- 削除されたファイルが意図通りか
- 1 PR = 1 Issue の原則に沿っているか（`.claude/rules/issue-sizing.md`）

### Step 3: CLAUDE.md / ドキュメント更新の要否確認

プロジェクト構成・開発フローに影響する変更の場合は CLAUDE.md / 関連ドキュメントを更新する。

| 変更内容 | 更新対象 |
|---------|---------|
| 新コマンド追加 | `.claude/CLAUDE.md` の「カスタムコマンド」表 / `.claude/commands/README.md` |
| 新スキル追加 | `.claude/CLAUDE.md` の「スキル」表 / `.claude/skills/README.md` |
| 新ルール追加 | `.claude/CLAUDE.md` の「ルール」表 / `.claude/rules/README.md` |
| 新 make ターゲット | `.claude/CLAUDE.md` の「テスト・品質」「インフラ管理」セクション |
| 新モジュール（apps/） | 該当 README + DocDD（`/develop` 内で更新済みのはず）|

更新不要な例: バグ修正のみ、既存機能の軽微な改善、ドキュメント本文のみの修正。

### Step 4: ブランチ同期（main の最新を取り込む）

CI / マージで競合が出ないよう、PR 作成前に main の最新を取り込む。

```bash
# 既に Step 2 で fetch 済みのはず。差分を確認
git log --oneline HEAD..origin/main

# main の最新を取り込む（コンフリクトしたら解消してから commit）
git rebase origin/main
# または
# git merge origin/main
```

> **rebase vs merge**: 個人ブランチは `git rebase origin/main` で履歴を整理してから push するのが推奨。チームでブランチを共有している場合は `merge` を選ぶ。プロジェクトの方針に従う。

### Step 5: コミット（Conventional Commits の subject + body のみ）

未コミットの変更があればコミットする。**`Closes #<N>` は commit message に書かない**（PR 本文側に集約する）。

```bash
# 変更を確認
git status

# 必要なファイルを stage
git add <files>

# Conventional Commits 形式でコミット
# subject: <type>(<scope>): <imperative summary>
# body: 任意の補足（変更理由・背景）
git commit -m "feat(scope): add new feature for xxx" \
           -m "Issue #$ARGUMENTS の計画に従い ... を実装。"

git push -u origin "$(git branch --show-current)"
```

**禁止事項**:
- ❌ commit message に `Closes #<N>` / `Fixes #<N>` を書く（PR body に集約するため）
- ❌ `--no-verify` で hook をスキップする
- ❌ 既に push 済みの commit を `--amend` する（新規 commit を作る）

> **理由**: commit message と PR body の両方に closing keyword を入れると責務が重複し、cherry-pick / squash 時に挙動が追いづらくなる。auto close は **PR body 側のみ** に集約する。

詳細: `.claude/rules/commit-messages.md`

### Step 6: PR 作成（gh pr create）

PR 本文は `.claude/templates/pr-body.md` をベースに展開する。

```bash
ISSUE=$ARGUMENTS
PR_BODY="/tmp/pr_body_${ISSUE}.md"

# テンプレートから markdown 本体だけを抽出（ヘッダ・利用例・forward-ref 表をスキップ）
# pr-body.md は `## 変更内容 ... Closes #<N>` を ```markdown ... ``` のフェンス内に持つ
awk '/^```markdown$/{f=1; next} /^```$/{if(f){exit}} f' \
  .claude/templates/pr-body.md > "$PR_BODY"

# `<N>` を Issue 番号に置換し、各セクションを実装内容で埋める
sed -i.bak "s/<N>/${ISSUE}/g" "$PR_BODY" && rm -f "${PR_BODY}.bak"
# その後、エディタで `## 変更内容` `## テスト` セクションを実装内容に書き換える
# 抽出後の本文に `Closes #<ISSUE>` がそのまま残ることを必ず確認する（コードフェンス内に紛れ込ませない）
grep -E "^Closes #${ISSUE}\b" "$PR_BODY" || {
  echo "❌ 抽出後の PR body に 'Closes #${ISSUE}' が見当たりません。テンプレ抽出ロジックを確認してください"
  exit 1
}

# PR タイトル: Conventional Commits の subject に Issue 番号を付与
PR_TITLE="feat(scope): add xxx (#${ISSUE})"

gh pr create \
  --base main \
  --title "$PR_TITLE" \
  --body-file "$PR_BODY"
```

**PR 本文の最小構成**（テンプレートから展開）:

```markdown
## 変更内容
- [主要な変更を 3 〜 5 行で要約]

## テスト
- [ ] [変更レイヤーに対応する `make test-*` を実行（PASS / N/A）]
- [ ] [`.claude/` 変更時は `make validate-claude`（PASS / N/A）]
- [ ] [DocDD 変更時は `make traceability`（PASS / N/A）]

## 関連

Closes #<N>
```

> **複数 Issue を閉じる場合**: `Closes #<N1>` / `Closes #<N2>` を改行区切りで複数行に並べる（1 行に並べると auto close を認識しないことがある）。
> **PR 本文の言語**: 既存 PR と整合する言語（プロジェクトに合わせて日本語 / 英語）を使用する。

### Step 7: 完了報告

PR URL と次のステップを案内する。

```bash
PR_URL=$(gh pr view --json url -q .url)
echo "PR 作成完了: $PR_URL"
```

---

## チェックリスト

PR 作成前に確認:

- [ ] `/verify` コメントが Issue に投稿済み（🔴 必須指摘 0 件）
- [ ] `/review` 完了済み（または同一セッション内で実施済み）
- [ ] `git diff "$MERGE_BASE"...HEAD` で意図しないファイルが含まれていない
- [ ] CLAUDE.md / 関連 README の更新要否を判断した
- [ ] commit message に `Closes #<N>` / `Fixes #<N>` が含まれていない
- [ ] PR 本文の `## 関連` セクションに `Closes #<N>` を 1 行ずつ並べた
- [ ] PR タイトルが Conventional Commits 形式

---

## 次のステップ

PR を作成した。`/merge` は **main 側のターミナル** に切り替えてから実行する。

```
---
✨ **このセッションで進んだこと**
- PR #<PR_NUMBER> 作成（タイトル: Conventional Commits 形式 / body に `Closes #<N>`）
- 差分: 変更ファイル <N> 件 / 追加 <+L> / 削除 <-L>
- CI 起動済み（gh pr checks <PR_NUMBER> で進捗確認）

🎯 **これによって変わること**
- DocDD 7軸: BR=<…> / UC=<…> / DM=<…> / SR=<…> / EXT=<…> / API=<…> / TC=<…>（更新コミット有無）
- レビュー対象が main 候補として可視化され、CI 完了次第 `/merge` でマージできる

📋 **次のステップ**
- PR #<PR_NUMBER>（CI 進行中 / レビュー待ち）
- main 側ターミナルで `/merge <N>`（worktree 内では実行しない）
---
```

コピペ用:

```bash
/merge <N>
```

> **`/merge` は main 側で実行する**: worktree 内から `/merge` を実行すると main 同期がスキップされるため、メインリポジトリのターミナルに戻ってから実行する。

---

## 注意事項

- 1 PR = 1 Issue を原則とする（`.claude/rules/issue-sizing.md`）
- `Closes #<N>` は **PR body のみ** に書く（commit message には書かない）
- `--no-verify` で hook をスキップしない（`.claude/rules/completion-quality.md`）
- 既に push 済みの commit は `--amend` しない（新規 commit を作る）

---

## 📋 後続 Issue で導入予定（forward reference の隔離）

| 参照先（未存在） | 用途 | 予定 Issue |
|--------------|------|----------|
| `make verify-issue` / `make quality-gate` | Pre-flight gate の自動化 | 後続 Issue（5-1 想定） |
| `.claude/policies/landing-path-state.yaml` + validator | UI 変更時の auto close 抑止（`screen-verify` 連携） | **持ち込まない**（`screen-verify` がスコープ外のため） |
| `roadmap.md` 更新ステップ | リリース計画との突合 | starter に roadmap なし。**持ち込まない** |
| `validate_followup_decisions.py` | PR body の 5-form bullet grammar lint | **持ち込まない**（SubsCore 固有 lint） |

Remember to use the GitHub CLI (`gh`) for all GitHub-related tasks.
