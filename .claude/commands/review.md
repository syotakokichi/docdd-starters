---
description: 実装に対して独立した立場でコードレビューを行います（別セッション推奨）。
argument-hint: "<issue-number>"
disable-model-invocation: true
---
Issue #$ARGUMENTS の独立レビューを行ってください。

**`/verify` 完了後、`/pr` 作成前に実行する独立レビューコマンドです。**

---

## セッション切り替え必須

`/review` は **新規 Claude Code セッション（New Chat）で起動すること** を強く推奨します。

| 状況 | 推奨度 | 理由 |
|------|:------:|------|
| 新規セッション（VS Code New Chat / 新しいウィンドウ） | ✅ 推奨 | 実装者文脈が残らないため見落としを検出しやすい |
| 同一セッション内での連続実行 | ⚠️ 非推奨 | 確認バイアスが蓄積し、見落としを拾えない |

> **VS Code での切り替え方**: コマンドパレットから `Claude: New Chat` を実行、または別の VS Code ウィンドウで worktree を開き直す。
> **同一セッション内で続行する場合**: 確認バイアスが残ることを明示的にユーザーへ通知してから進める。

---

## 目的

- 実装者文脈を外した立場で、`/verify` の事実確認では拾えない見落としを検出する
- 5 軸（バグ / 回帰リスク / 設計不整合 / テスト不足 / ドキュメント更新漏れ）で指摘を整理する
- 🔴 / 🟡 の指摘は本セッション内で actionable なら即修正する

## 標準フロー

```
/verify <N>     # 検証完了（前段）
/review <N>     # 本コマンド（新規セッション推奨）
/pr <N>         # PR 作成
```

## `/verify` との責務分離

| コマンド | 責務 | 立場 |
|---------|------|------|
| `/verify` | 機械的な事実確認・証跡作成（テスト実行・契約整合性） | 実装者 |
| `/review` | 実装者文脈を外した見落とし検出（独立レビュー） | 第三者 |

---

## 手順

### Step 1: 入力の固定

レビュー対象を **3 種類の入力** に固定する。実装者の脳内コンテキストには依存しない。

```bash
# 1. Issue 本文（受け入れ条件 / 実装計画 / 検証定義）
gh issue view $ARGUMENTS --json body --jq .body > /tmp/review_${ARGUMENTS}_issue.md

# 2. /verify で投稿された検証結果コメント
gh issue view $ARGUMENTS --comments > /tmp/review_${ARGUMENTS}_comments.md

# 3. main からの差分（merge-base 起点で main 側追加分を「削除」と誤認しない）
git fetch origin main
MERGE_BASE=$(git merge-base HEAD origin/main)

# コミット済み差分（HEAD と main の差）
git diff "$MERGE_BASE"...HEAD --stat > /tmp/review_${ARGUMENTS}_diff_stat.txt
git diff "$MERGE_BASE"...HEAD > /tmp/review_${ARGUMENTS}_diff.patch

# 未コミット変更（staged + unstaged）も含める
# /review は /pr の前段に走るため、コミット未投下のままレビューされるケースを取りこぼさない
git diff HEAD >> /tmp/review_${ARGUMENTS}_diff.patch

# untracked ファイルの一覧（差分に表れないため別途記録）
git ls-files --others --exclude-standard > /tmp/review_${ARGUMENTS}_untracked.txt

# 未コミット変更がある場合は警告（commit 推奨だが、本コマンドは差分を取りに行く方針）
if [ -n "$(git status --porcelain)" ]; then
  echo "⚠️  未コミット変更があります。レビュー差分には含めましたが、/pr で commit 後の状態を再確認することを推奨します。"
  git status --short
fi
```

確認ポイント:

- Issue 本文の受け入れ条件が網羅されているか
- `/verify` で `未解消` が残っていないか
- 差分にレビュースコープ外のファイルが含まれていないか
- 未コミット変更 / untracked ファイルがレビュー対象に漏れていないか（`/tmp/review_${ARGUMENTS}_untracked.txt` を確認）

### Step 2: 5 軸レビュー

以下の 5 軸でコード差分を読み、指摘を整理する。各軸とも **指摘なしの場合は「なし」と明記**する（軸自体を省略しない）。

#### 1. バグ（ロジック誤り・null 漏れ・境界条件・例外処理）
- off-by-one、null チェック漏れ、型の不一致
- 例外の握りつぶし、不適切な fallback
- 境界条件（空配列・最大値・無効入力）

#### 2. 回帰リスク（既存機能への影響・後方互換性）
- 既存 API / 関数シグネチャの破壊的変更
- 既存のデータ構造の互換性
- 既存テストが想定通り通ること

#### 3. 設計不整合（レイヤー責務逸脱・抽象度のばらつき・命名）
- 単一責任の原則
- レイヤー間の依存方向（presentation → service → infrastructure）
- 抽象度の一貫性、命名の整合

#### 4. テスト不足（追加テスト未追加・エッジケース未カバー）
- 新規ロジックに対するテストの有無
- エッジケース・異常系のカバレッジ
- TDD 必須判定の Issue で RED → GREEN 証跡が残っているか

#### 5. ドキュメント更新漏れ（DocDD / API yaml / CLAUDE.md / README）
- DocDD（`docs/7-axis/`）の更新要否
- API 契約変更時の OpenAPI yaml 更新
- 新コマンド / スキル追加時の CLAUDE.md / README 更新

### Step 3: Codex CLI による独立レビュー

Codex CLI を使って差分の独立レビューを実行する。
ルール参照: `.claude/rules/codex-review.md`

> ⚠️ **`/review` での Codex 起動は `--base main` を使う**（コード差分のレビュー）。
> `--base` と `[PROMPT]` の同時使用は不可（v0.120+ で確認済み）。

#### Codex 利用可否を判定

```bash
codex --version > /dev/null 2>&1
```

#### Codex が利用可能な場合

```bash
codex review --base main
```

> **応答時間**: Codex の応答には 3 〜 5 分かかる場合がある。30 秒で応答なしと判定しない。
> **worktree の場合**: 出力に worktree パス（例: `.claude/worktrees/issue-<N>/`）を明記する。

#### Codex が利用不可の場合（Fallback）

**サイレントスキップ禁止** — 必ずユーザーに通知する。

1. `.claude/templates/codex-review-handoff.md` の「コードレビュー」セクションを出力
2. ユーザーに手動で Codex / ChatGPT にレビューを依頼するよう案内

### Step 4: 指摘の分類と即時対応

Codex / 5 軸レビューで得た指摘を以下のように分類する（`.claude/rules/codex-review.md` 準拠）:

| 分類 | 意味 | 対応 |
|:----:|------|------|
| 🔴 / P1 必須 | バグ・脆弱性・データ損失リスク | マージ前に必ず修正 |
| 🟡 / P2 推奨 | 設計改善・可読性・パフォーマンス | 判断して対応（理由を記録） |
| 🟢 / P3 参考 | スタイル・命名・ドキュメント | 記録のみ |
| ❌ 却下 | 誤検知・コンテキスト不足 | 却下理由を記録 |

#### 必要な修正は本セッション内で即適用

🔴 / 🟡 で actionable な修正は、ユーザー承認を待たずに本セッション内で修正する:

1. 修正を適用
2. `make test-backend` / `make test-frontend` / `make validate-claude` のうち変更レイヤーに該当するものを再実行
3. 修正前後の差分を Step 6 のコメントに記録

> **逃げない**: 🔴 / 🟡 で actionable な指摘を「PR 後に対応」として後送りしない。`/review` は PR 前の最後の関門。
> **🔴 が解消できない場合**: 残留リスクとして Step 6 コメントに明記し、ユーザー判断を仰ぐ。`/pr` を強行しない。

### Step 5: 残留リスクの整理

本セッション内で解消できなかった指摘・気づきを残留リスクとして整理する。

| 種別 | 内容 |
|------|------|
| 🔴 / P1 未解消 | 本来必須だが本セッションで解消できないもの。理由と対応案を必ず記載 |
| 🟡 / P2 非対応 | 採用しなかった推奨。理由を記載 |
| 後続 Issue 候補 | 本 Issue のスコープ外だが起票すべき内容 |

### Step 6: Issue コメントに記録

レビュー結果（Step 2 〜 Step 5 の総合）を Issue コメントとして投稿する。

- 構成は `.claude/templates/independent-review-result-comment.md` に従う
  - 見出し: `## 独立レビュー結果（/review）` をそのまま使う
  - 5 軸は必ず全て記載（指摘なしなら「なし」）
  - 優先度は `P1` / `P2` / `P3` の 3 段階（装飾なし）
  - 残留リスクは必ず記載（なければ「なし」）

```bash
gh issue comment $ARGUMENTS --body-file /tmp/review_result_${ARGUMENTS}.md
```

---

## チェックリスト

`/pr <N>` に渡す前に確認:

- [ ] 新規セッションで起動した（または同一セッションで続行する旨をユーザーに通知した）
- [ ] 入力 3 種（Issue 本文 / `/verify` コメント / `git diff merge-base`）を固定した
- [ ] 5 軸（バグ / 回帰 / 設計 / テスト / docs）を全て確認し、指摘なしの軸も「なし」と記載した
- [ ] Codex CLI でコード差分レビューを実施した（未導入時は handoff を出力した）
- [ ] 🔴 / 🟡 actionable な指摘は本セッション内で修正した
- [ ] 🔴 未解消が残る場合は残留リスクに明記した
- [ ] レビュー結果を `.claude/templates/independent-review-result-comment.md` 形式で Issue コメントに投稿した

---

## 次のステップ

```
Issue #<N> 独立レビュー完了:
  - P1 必須: X 件（解消 Y / 未解消 Z）
  - P2 推奨: X 件（解消 Y / 非対応 Z）
  - P3 参考: X 件
  - 残留リスク: あれば 1 行 / なし

次のステップ:
  /pr <N>     # PR 作成（🔴 P1 未解消が 0 件であること）
```

> **🔴 P1 未解消が残っている場合**: `/pr` に進まず、本セッション内で修正してから再 `/review` するか、ユーザー判断を仰ぐ。

---

## 注意事項

- `/review` は **新規セッション推奨**（実装者文脈による確認バイアスを避けるため）
- 入力は 3 種に固定する（実装者の脳内コンテキストに依存しない）
- 5 軸は必ず全て埋める（指摘なしの軸を省略しない）
- Codex 未導入時は handoff テンプレートで案内する（サイレントスキップ禁止）

---

## 📋 後続 Issue で導入予定（forward reference の隔離）

| 参照先（未存在） | 用途 | 予定 Issue |
|--------------|------|----------|
| 3 reviewer adversarial review（Codex + Claude SA × 2） | レビュアー多重化 | 後続 Issue（D-1 想定） |
| `.claude/rules/multi-model-review.md` | multi-reviewer 統合 SSOT | 後続 Issue（D-1 想定） |
| `.claude/skills/review-orchestrator/SKILL.md` | 3 reviewer 並列起動 | 後続 Issue（D-1 想定） |
| `.claude/skills/receiving-code-review/SKILL.md` | レビュー指摘の受領パターン | 後続 Issue（4-3 想定） |
| `.claude/skills/ephemeral-session-memory/SKILL.md` | レビュー raw 出力の session memory 退避 | 後続 Slice（未起票） |

Remember to use the GitHub CLI (`gh`) for all GitHub-related tasks.
