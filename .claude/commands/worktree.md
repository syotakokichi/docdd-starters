---
description: Issue 用の worktree 環境を作成します。
argument-hint: "<issue-number>"
disable-model-invocation: true
---
Create the canonical worktree environment for Issue $ARGUMENTS.

`/worktree` は checkout 準備コマンドです。Issue 情報取得 → worktree 作成 → ブランチリネーム → 環境セットアップを一括で行います。

**前提知識**: [.claude/skills/parallel-development/SKILL.md](../skills/parallel-development/SKILL.md) — 判定 SSOT（原則 worktree 推奨）・Track A/B（.env 要否）・複数エディタ並走パターン・worktree 互換性サマリ・マージ順序

> **不変条件**: 本 Issue で worktree を使うか否かの判定は SKILL.md の「判定 SSOT」に従う。原則 worktree 推奨、例外は単独 sequential 作業をユーザーが明示した場合のみ。

> **CLI-first 原則**: 本コマンドは `git worktree add` CLI を使う（`.claude/rules/cli-first.md` 準拠）。MCP の `EnterWorktree` ビルトインツールは使わない。

---

## 目的

- Issue 情報を取得する
- main ベースで worktree を作る
- 命名規則に沿ったブランチへリネームする
- 別ウィンドウ / 別セッションで安全に作業できる状態を作る

## 標準フロー

```bash
/worktree <N>
/plan <N>
/develop <N>
/verify <N>
/pr <N>            # PR 作成
```

## 関連コマンド

| コマンド | 用途 |
|---------|------|
| `/discard-worktree <N>` | 未マージ worktree の破棄（`/merge` がマージ前提のため別コマンド） |
| `/merge <N>` | マージ + worktree クリーンアップ |

---

## 手順

### Step 1: Issue 情報を取得

```bash
gh issue view $ARGUMENTS --json title,number,state
```

- Issue が存在しない場合はエラー
- Issue が Close 済みの場合は警告

### Step 2: dirty check

未コミット変更がある状態で `git checkout main` すると衝突する。先にコミットまたはスタッシュする。

```bash
git status --porcelain
```

**変更がある場合**: ユーザーに確認し、`/commit-and-push` またはスタッシュしてから進む。

> **別ターミナルで Track A が作業中の場合**: `git checkout main` は共有チェックアウトを切り替えてしまう。Track A の作業を一時中断（コミット or スタッシュ）してから実行するか、Track A 完了後に実行する。

### Step 3: main ブランチに切り替え

```bash
# 現在のブランチを確認
git branch --show-current

# main でない場合は切り替え
git checkout main
git pull origin main
```

### Step 4: git worktree add でワークツリーを作成

CLI-first 原則に従い `git worktree add` を直接呼ぶ:

```bash
# Issue タイトルから type と short-description を決定（branch-naming.md 準拠）
# 例: feature/issue-42-add-login-page

WORKTREE_PATH=".claude/worktrees/issue-$ARGUMENTS"
BRANCH_NAME="<type>/issue-$ARGUMENTS-<short-description>"

# main ベースで worktree + ブランチを同時作成
git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME" main
```

- `.claude/worktrees/issue-<number>/` にワークツリーが作成される（`.gitignore` 登録済み）
- `<type>/issue-<number>-<short-description>` ブランチが main ベースで作成される
- 既に同名 worktree / ブランチがある場合は `git worktree add` がエラー終了する。Step 1 で警告が出ていなければそのまま中断し、ユーザーに確認する

> **branch-naming**: `<type>` は `feature` / `fix` / `refactor` / `docs` / `test` / `chore` のいずれか（`.claude/rules/branch-naming.md`）。

### Step 5: worktree に移動

```bash
cd "$WORKTREE_PATH"

# 確認
git branch --show-current
pwd
```

### Step 6: 環境変数ファイルのセットアップ（allowlist + 安全策）

worktree は `.gitignore` 対象のファイル（`.env`, `.env.local` 等）を共有しないため、メインリポジトリからシンボリックリンクを作成する。

> **Track 判定**: Issue が `.claude/` / `docs/` / `.github/` / `scripts/` など `apps/` 以外のみを触る Track B の場合、Backend/Frontend の `.env` は **不要**。判定基準は `.claude/skills/parallel-development/SKILL.md` の Track 分類節（SSOT）を参照。

#### 安全策（必須）

env symlink は secret 漏洩・自己参照による .env 破壊のリスクが高いため、以下を厳守する:

1. **cwd ガード**: スクリプト先頭で `git rev-parse --show-toplevel` を取得し、main repo と同一なら停止する（Step 5 が抜けたまま Step 6 を実行すると、main の `.env` を自己参照 symlink で破壊する事故を防ぐ）
2. **allowlist 限定**: 対象は `apps/backend/.env` と `apps/frontend/.env.local` の **2 ファイルのみ**。広範な `.env.*` を symlink しない
3. **存在確認**: main repo にファイルが存在する場合のみ symlink を作成
4. **ユーザー確認**: 初回作成時は「main repo の `.env` を symlink で参照しますか？」と 1 回確認してから進む
5. **`.env.example` 優先**: main repo にもファイルがなければ `cp .env.example .env` の手順を案内（symlink ではなくコピー）
6. **既存ファイル退避**: 既に通常ファイルの `.env` があれば `.env.bak` に退避してから symlink
7. **絶対パスで操作**: symlink の作成先・参照先はいずれも `$WORKTREE_ROOT/...` / `$MAIN_ROOT/...` の絶対パス（同一性比較で自己参照を二重防止）

```bash
# メインリポジトリのルートパスを取得（primary worktree）
MAIN_ROOT=$(git worktree list --porcelain | head -1 | sed 's/worktree //')

# 現在地を worktree ルートに固定する（Step 5 が反映されていない別シェルでも安全に動作させる）
WORKTREE_ROOT="$(git rev-parse --show-toplevel)"
cd "$WORKTREE_ROOT"

# 安全策: cwd が main repo（primary worktree）と同一なら symlink で .env を破壊するリスクがあるため停止
if [ "$WORKTREE_ROOT" = "$MAIN_ROOT" ]; then
  echo "❌ Step 6 は worktree 内でのみ実行可能（現在は main checkout: $WORKTREE_ROOT）"
  echo "   先に Step 4-5 を実行して worktree に入ってからやり直してください"
  return 1 2>/dev/null || exit 1
fi

# Track 判定（Step 1 で取得した Issue 内容から判断）
# - Track A: apps/ を含む変更 → Backend/Frontend .env 必要
# - Track B: .claude/ / docs/ / .github/ / scripts/ 等（apps/ 非変更）→ .env 不要
# Claude が判定し、Track B なら TRACK="B"、Track A または不明なら TRACK="A"
TRACK="A"  # デフォルトは A（env セットアップを行う）。Track B 確定時のみ B に変更

# allowlist: この 2 ファイルのみを対象とする
ENV_ALLOWLIST=("apps/backend/.env" "apps/frontend/.env.local")

setup_env() {
  local label="$1"    # "Backend" or "Frontend"
  local path="$2"     # allowlist 内のパス（worktree からの相対）
  local main_path="$MAIN_ROOT/$path"
  local worktree_path="$WORKTREE_ROOT/$path"

  # 自己参照 symlink 防止（万一 cwd ガードを抜けても、絶対パス比較で再ガード）
  if [ "$worktree_path" = "$main_path" ]; then
    echo "  ❌ $label $path → main と worktree が同一パス。symlink を作成しない"
    return 1
  fi

  # 既存の通常ファイルは退避
  if [ -e "$worktree_path" ] && [ ! -L "$worktree_path" ]; then
    echo "  ℹ️  $label $path は通常ファイル → $path.bak に退避"
    cp "$worktree_path" "$worktree_path.bak"
  fi

  if [ -f "$main_path" ]; then
    # ユーザー確認は呼び出し側で実施済みの前提（Track A 初回のみ）
    if /bin/ln -sf "$main_path" "$worktree_path"; then
      echo "  ✅ $label $path → symlink 作成"
      return 0
    else
      echo "  ❌ $label $path → symlink 作成失敗（ln exit code: $?）"
      echo "      手動で作成してください: /bin/ln -sf \"$main_path\" \"$worktree_path\""
      return 1
    fi
  fi

  # main にも存在しない場合は .env.example 優先のフォールバック
  if [ "$TRACK" = "B" ]; then
    echo "  ⏭️  $label $path → スキップ（Track B は apps/ 非変更のため .env 不要）"
  else
    echo "  ℹ️  $label $path → main にも未存在。以下でセットアップ:"
    echo "      cp ${path%.env*}.env.example $path  # .env.example が存在する場合"
  fi
  return 0
}

echo "環境変数ファイルのセットアップ（Track: $TRACK / allowlist: ${#ENV_ALLOWLIST[@]} ファイル / worktree: $WORKTREE_ROOT）"
setup_env "Backend"  "${ENV_ALLOWLIST[0]}"
setup_env "Frontend" "${ENV_ALLOWLIST[1]}"
```

> **なぜ symlink?**: `.env` を直接コピーすると、メインで値を変更しても worktree に反映されない。symlink なら常にメインの最新値を参照できる。
> **broken symlink 防止**: `[ -f ]` で実体の存在を確認してから `ln -sf` する。
> **PATH 破損耐性**: `ln` は `/bin/ln` 絶対パスで呼ぶ。

### Step 7: 依存パッケージのインストール

worktree は `.gitignore` 対象のファイル（`node_modules/` 等）を共有しないため、必要な依存をインストールする。

> ⚠️ **重要**: リポジトリ root には `package.json` が存在しない。`package.json` は `apps/frontend/` 配下にある。

```bash
# Frontend の依存インストール
# 推奨: Makefile 経由
make install-dev

# または直接 npm を呼ぶ場合は --prefix を必ず指定（root の package.json 不在エラー回避）
npm --prefix apps/frontend install
```

> **Backend (Python)**: venv はホスト共有 or Docker 内実行のため、通常は追加作業不要。
> **`make install-dev` の挙動**: Frontend の `npm install` を含む dev 依存セットアップを一括で実施する。

### Step 8: Cursor 別ウィンドウで開く

worktree ルートの **絶対パス** を渡して開く。`cursor .` は Step 7 等で cwd がずれていると誤ったディレクトリを開くため使用しない。

```bash
# pwd ではなく worktree の絶対パスを明示的に指定する
cursor "$(git rev-parse --show-toplevel)"
```

> **なぜ絶対パス?**: `npm install` 等のサブコマンドで cwd が変わる場合がある。`git rev-parse --show-toplevel` は常に worktree ルートを返すため安全。

- メインの Cursor ウィンドウはそのまま維持（マージ・Issue 作成等の管理操作に専有）
- 新しい Cursor ウィンドウで検索・タブ・ターミナル・Git ブランチ表示が worktree に揃う

### Step 9: 次のステップを案内

```
Worktree 作成完了:
  パス: .claude/worktrees/issue-<N>
  ブランチ: <type>/issue-<N>-<short-description>
  Cursor: 別ウィンドウで開き済み

次のステップ（Cursor 別ウィンドウ側で実行）:
  /plan <N>      # 計画立案（未計画の場合）
  /develop <N>   # 実装開始
  /verify <N>    # 実装検証
  /pr <N>        # PR 作成
```

---

## 利用パターン

### 方法 A: 同一セッション内（短い作業向け）

```bash
/worktree 42     # worktree 作成 + ブランチセットアップ
/plan 42         # 計画立案
/develop 42      # 実装
/verify 42       # 実装検証（同一セッション）
# ⚠️ 検証は新しいセッションを開いて行うのが推奨（確証バイアス回避）
/pr 42           # PR 作成（worktree 内で最後のステップ）
# → メインリポジトリのターミナルに切り替え
/merge 42        # メインから: マージ + クリーンアップ
```

### 方法 B: 別エディタウィンドウ（長時間並列向け、推奨）

```bash
# メイン Window: 別 Issue の作業を継続
/develop 100

# メイン Window のターミナルで worktree 作成
/worktree 42     # git worktree add + 別ウィンドウ起動

# 別エディタウィンドウ（.claude/worktrees/issue-42）
/plan 42         # 計画立案
/develop 42      # 実装
/verify 42       # 実装検証
/pr 42           # PR 作成

# メイン Window に戻る
/merge 42        # マージ + クリーンアップ
```

> **別ウィンドウの利点**: 検索対象・タブ・AI 文脈・ターミナル cwd・Git ブランチ表示が全て worktree に揃い、メイン checkout を誤って触るリスクがなくなる。

---

## 注意事項

- `.claude/worktrees/` は `.gitignore` 登録済み
- worktree 内でも `.claude/commands/`, `.claude/skills/`, `.claude/rules/` は利用可能（git 管理下のため）
- 既に同名の worktree が存在する場合は `git worktree add` がエラー終了する
- マージ操作（`gh pr merge` / `git worktree remove`）はメインリポジトリから実行する

---

## 次のステップ

Worktree とブランチを作成、別ウィンドウで開いた。新ウィンドウで `/plan` から進める。

```
---
✨ **このセッションで進んだこと**
- worktree: `.claude/worktrees/issue-<N>/` 作成
- ブランチ: `<type>/issue-<N>-<short>` を main ベースで作成
- env symlink: <Backend / Frontend / N/A> / Cursor 別ウィンドウ起動済み

🎯 **これによって変わること**
- main checkout を触らずに Issue #<N> 用の独立作業環境が確立
- 別ウィンドウ側で `/plan` 〜 `/pr` を進めても main 側の他 Issue 作業と競合しない

📋 **次のステップ**
- Worktree #<N>（status:todo / 別ウィンドウ起動済み）
- 別ウィンドウで `/plan <N>` を実行
---
```

コピペ用:

```bash
/plan <N>
```

---

## 📋 後続 Issue で導入予定（forward reference の隔離）

| 参照先（未存在） | 用途 | 予定 Issue |
|--------------|------|----------|
| `validate-merge-cwd.sh` hook | worktree 内からのマージ操作を決定論的にブロック | 後続 Issue（D-1 想定） |

ARGUMENTS: issue_number

Example usage: `/worktree 42`
