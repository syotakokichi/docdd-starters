# Command Trailer - SSOT

13 verb コマンド（`/issue` / `/plan` / `/worktree` / `/develop` / `/verify` / `/review` / `/pr` / `/merge` / `/tdd` / `/brainstorm` / `/update-issue` / `/commit-and-push` / `/discard-worktree`）の末尾に出力する **3 ブロック trailer** の SSOT。

ユーザーが各コマンド完了時に「何が進んだか」「何が変わったか」「次に何をするか」を一目で把握できるようにナビゲーション体験を統一する。

> ⚠️ **本ファイルは V8（抽象論禁止監査）の scope 除外対象**。禁止例として「品質向上」「設計改善」「コードが動く」等を意図的に記載するため、V8 grep は `.claude/commands/` 配下にのみ適用する。

---

## 構造

各コマンドの末尾の `## 次のステップ` セクションに以下の構造を出力する:

| ブロック | 内容 | 文量 |
|---------|------|------|
| ✨ **このセッションで進んだこと** | 数値・PASS/FAIL・成果物名 | 1〜3 行 |
| 🎯 **これによって変わること** | Issue 固有の本質的効果（抽象論禁止）。Group B のみ `- DocDD 7軸: ...` 1 行を必須で含める | 1〜3 行 |
| 📋 **次のステップ** | 直後 1 アクション（最大 2 まで）を bash snippet で | 1〜2 行 |

---

## 行頭フォーマット（厳格）

V3〜V5 の grep 検証が壊れないよう、以下を厳守する:

- ✨ / 🎯 / 📋 は **行頭** に配置（インデント・引用・コードブロック内インデント禁止）
- 直後に半角スペース 1 つ + `**` で太字を開始
- ヘッダ文言は完全一致:
  - `✨ **このセッションで進んだこと**`
  - `🎯 **これによって変わること**`
  - `📋 **次のステップ**`

> 既存の `## 📋 後続 Issue で導入予定（forward reference の隔離）` heading とは行頭が `## ` から始まるため衝突しない（grep `^📋 \*\*次のステップ\*\*` は trailer ブロックのみにヒットする）。

---

## fenced code block の入れ子設計

trailer 全体を ` ``` ` で囲み、内側で更に ` ```bash ` を出すと Markdown レンダラの入れ子問題で表示が崩れる。

| 出力先 | 推奨 fence |
|--------|-----------|
| コマンド本文（runtime に literal 出力するだけ） | 3 連バッククォート単独で OK |
| 本 SSOT および計画書（フォーマット例を Markdown 表示する） | 外側 4 連バッククォート ` ```` ` で囲み、内側で 3 連を使う |

例（このドキュメント内で fence の中の fence を見せる場合）:

````markdown
## 次のステップ

[簡潔な前置き 1 行]

```
---
✨ **このセッションで進んだこと**
- 具体的な数値・PASS/FAIL・成果物名（1〜3 行）

🎯 **これによって変わること**
- Issue 固有の効果を 1〜2 行（抽象論禁止）

📋 **次のステップ**
- Issue #<N>（[現在の状態]）
- [次の 1 アクションを 1 行で]
---
```

コピペ用:

```bash
/<次コマンド> $ARGUMENTS
```
````

---

## 「🎯 これによって変わること」の抽象論禁止ルール

抽象論で逃げないこと。Issue 固有の **名詞・動詞** で「何が変わったか」を書く。

### NG（V8 grep で監査される禁止語）

- 「品質向上」
- 「設計改善」
- 「コードが動く」
- 「可読性向上」
- 「保守性向上」

### OK（Issue 固有の効果）

- 「招待トークンの再利用が拒否され、`PUT /api/invitations/:id/accept` の重複受諾が成立しない」
- 「`docs/7-axis/3_DM/DM-User.md` と実装が同期し、新規開発者が DM を一次参照源として読める」
- 「次フェーズで `/develop` 着手時に `status:in-progress` ラベルが付き、誰が触っているかが可視化される」

> **判定基準**: 一般論を書きたくなったら、それは「✨ 進捗 fact」に書くべきか、本来書く必要のない冗長記述である。

---

## 数値根拠の必須化（✨ ブロック）

「✨ このセッションで進んだこと」は具体的な根拠を伴う:

- 件数（変更ファイル N 件 / 修正タスク N 件 / 🔴 必須指摘 N 件）
- PASS/FAIL（`make test-backend` PASS / `make validate-claude` PASS）
- 成果物名（PR #123 / `DM-User.md` / `users.yaml`）

NG: 「色々進めた」「だいぶ進んだ」「テストを通した」（数値なし）。

---

## 「📋 次のステップ」の 1-step 原則

- **直後 1 コマンド** をコピペ可能な bash snippet で提示する（最大 2 まで許容: ペアで提示する場合のみ）
- PR・マージなど **先のフローを先回りしない**（ユーザーは現在地を起点に動く）
- bash snippet は trailer fence の **外** に置く（内側 fence の二重化を避ける）

OK 例（1〜2 step）:

```bash
/develop 42
```

NG（先回り例）:

```bash
/develop 42
/verify 42
/pr 42
/merge 42
```

> V7 自動検査: trailer 領域内の `/[a-z-]+ ` の unique 数が 2 以下であることを `awk` で確認する（Issue #46 の検証定義 V7 参照）。

---

## DocDD 7 軸の固定フォーマット（Group B のみ）

`/plan` / `/verify` / `/pr` / `/merge` の 🎯 ブロックには以下の **1 行** を必ず含める:

```
- DocDD 7軸: BR=<更新有無> / UC=<更新有無> / DM=<更新有無> / SR=<更新有無> / EXT=<更新有無> / API=<更新有無> / TC=<更新有無>
```

例:

| ケース | 表記 |
|------|------|
| 全軸更新なし | `- DocDD 7軸: BR=— / UC=— / DM=— / SR=— / EXT=— / API=— / TC=—` |
| DM・API のみ更新 | `- DocDD 7軸: BR=— / UC=— / DM=DM-User.md / SR=— / EXT=— / API=users.yaml / TC=—` |
| 簡潔ショートハンド | `- DocDD 7軸: 更新なし` |
| 簡潔ショートハンド | `- DocDD 7軸: DM-User.md, API-users.yaml 更新（他軸は更新なし）` |

> 簡潔ショートハンドを認めるのは、軸名 7 個列挙が冗長な軽量変更での読みやすさ確保のため。**ただし「BR」「UC」「DM」「SR」「EXT」「API」「TC」のいずれか 1 軸名以上、または「更新なし」の語を必ず含める**（V6 grep `DocDD 7軸:` で検出可能なように）。

---

## 配置ルール（実装ファイル側）

| 状況 | 配置 |
|------|------|
| 既存の `## 次のステップ` heading がある | **置換**（既存の重要メモ・但し書きは保全） |
| 既存 heading がない | **新規追加**: 末尾の `Remember to use the GitHub CLI` の **直前** に配置 |

セクション順序:

```
## 次のステップ（trailer）
↓
## 注意事項（既存）
↓
## 失敗時の対処（既存・該当ファイルのみ）
↓
## 📋 後続 Issue で導入予定（forward reference の隔離）（既存・該当ファイルのみ）
↓
Remember to use the GitHub CLI (`gh`) for all GitHub-related tasks.
```

---

## 13 コマンド分のサンプル

各コマンドの trailer 例。実装時はこの形を踏襲しつつ、Issue 固有の数値・成果物名で埋める。

### Group A — SubsCore 流そのまま採用（9 コマンド）

#### `/issue`

````markdown
## 次のステップ

Issue 起票完了。並列開発するなら `/worktree` を先に、単独 sequential なら `/plan` を直接呼ぶ。

```
---
✨ **このセッションで進んだこと**
- Issue #<N> 作成（labels: <優先度> / <領域> / status:todo）
- Brainstorm 結論を Issue 本文へ保存
- サイズチェック PASS（変更ファイル <M> 件想定 / 実装タスク <K> 件想定）

🎯 **これによって変わること**
- 起票内容が Issue tracker 上の単一参照源になり、`/plan` 以降が Issue 番号で追跡可能になる
- 並列開発する場合は次の `/worktree` で worktree + 専用ブランチが立ち上がる

📋 **次のステップ**
- Issue #<N>（status:todo）
- 並列開発するなら `/worktree <N>`、単独 sequential なら `/plan <N>` を直接
---
```

コピペ用:

```bash
/worktree <N>
```
````

#### `/develop`

````markdown
## 次のステップ

実装サマリーを Issue コメントに投稿済み。新セッションで `/verify` を起動して確証バイアスを避ける。

```
---
✨ **このセッションで進んだこと**
- 変更ファイル <N> 件 / 追加テスト <M> 件
- TDD 証跡: 必須-PASS / スキップ（理由: <one-liner>）
- Coverage: PASS / N/A

🎯 **これによって変わること**
- 実装が Issue の受け入れ条件を満たし、`/verify` の事実確認に渡せる
- 計画との差分があれば Issue 本文に反映済みで、次フェーズの読者が最新状態を読める

📋 **次のステップ**
- Issue #<N>（status:in-progress）
- `/verify <N>` を新セッションで実行（実装者文脈を持ち込まない）
---
```

コピペ用:

```bash
/verify <N>
```
````

> **新セッションで `/verify` を実行する理由**: 実装者の文脈（編集したファイル・意図）が残ったまま検証すると見落としが増える。

#### `/review`

````markdown
## 次のステップ

独立レビュー完了。🔴 必須指摘 0 件なら `/pr` に進める。

```
---
✨ **このセッションで進んだこと**
- 5 軸レビュー（バグ / 回帰 / 設計 / テスト / docs）完了
- P1 必須: <X> 件（解消 <Y> / 未解消 <Z>） / P2 推奨: <X> 件 / P3 参考: <X> 件
- Codex CLI レビュー: 実施 / Fallback handoff

🎯 **これによって変わること**
- 実装者文脈外で見落としが拾われ、PR 作成前の最終ゲートが成立
- 残留リスクが Issue コメントに整理され、レビュアーが受領状態を把握できる

📋 **次のステップ**
- Issue #<N>（status:in-progress / 🔴 P1 未解消 0 件）
- `/pr <N>` で PR 作成
---
```

コピペ用:

```bash
/pr <N>
```
````

#### `/tdd`

````markdown
## 次のステップ

RED 証跡を Issue コメントに残した。`/develop` で GREEN を達成する。

```
---
✨ **このセッションで進んだこと**
- 追加した Failing test: <M> 件（FAILED 確認済み）
- RED コマンド: `pytest <path>::<test>`（または `npx vitest run ...`）
- 実装本体は未編集

🎯 **これによって変わること**
- 期待挙動がテストとして固定され、`/develop` での GREEN 実装が同じコマンドで検証可能になる
- スコープ漏れがあれば `/plan` の Critical Path テーブルとの差分が見える

📋 **次のステップ**
- Issue #<N>（RED 証跡記録済み）
- `/develop <N>` で GREEN 実装
---
```

コピペ用:

```bash
/develop <N>
```
````

#### `/brainstorm`

````markdown
## 次のステップ

Brainstorm 結論まとめ完了。`/issue` で起票に渡す。

```
---
✨ **このセッションで進んだこと**
- Goal / Non-goals / Options / Risks 4 軸で整理
- Chosen direction 確定 / Issue split: <N 件 / なし>
- Codex 単一相談: 実施 / 未実施

🎯 **これによって変わること**
- 曖昧な要望が起票可能な粒度（受け入れ条件付き）まで分解され、`/issue` でそのまま起票できる
- 分割が必要な場合は子 Issue / 親 Epic の構成案が決まる

📋 **次のステップ**
- 起票候補: <N> 件
- `/issue` を呼び、Brainstorm 結論を貼り付けて起票
---
```

コピペ用:

```bash
/issue
```
````

#### `/update-issue`

````markdown
## 次のステップ

Issue 本文を最新の実装状態に同期した。

```
---
✨ **このセッションで進んだこと**
- Issue #<N> 本文更新（変更履歴 / 計画からの変更点 / 設計決定事項を追記）
- 既存セクション（背景・目的・受け入れ条件）は保全

🎯 **これによって変わること**
- 実装中の判断が Issue 本文に反映され、`/verify` `/review` `/pr` で参照する内容が最新化される
- 計画と実装の乖離が `/develop` のサマリーと突き合わせ可能になる

📋 **次のステップ**
- Issue #<N>（本文最新化済み）
- 実装続行なら `/develop <N>`、検証フェーズなら `/verify <N>`
---
```

コピペ用:

```bash
/develop <N>
```
````

#### `/commit-and-push`

````markdown
## 次のステップ

変更をコミットしてリモートに push 済み。次の作業フェーズへ。

```
---
✨ **このセッションで進んだこと**
- コミット <N> 件（subject + body 形式）
- pre-commit hook PASS / 修正コミット追加
- リモート push 完了（origin/<branch>）

🎯 **これによって変わること**
- ローカル変更がリモートに反映され、CI が走り始める
- 他セッション・他エディタウィンドウからも最新ブランチを pull できる

📋 **次のステップ**
- ブランチ: <branch>（origin と同期済み）
- 検証フェーズに進むなら `/verify <N>`、PR 作成なら `/pr <N>`
---
```

コピペ用:

```bash
/verify <N>
```
````

#### `/worktree`

````markdown
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
````

#### `/discard-worktree`

````markdown
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
````

---

### Group B — DocDD 7 軸を 🎯 に統合（4 コマンド）

#### `/plan`

````markdown
## 次のステップ

Issue 本文を仕様固定済み計画に更新し、Codex 計画レビューを実施した。

```
---
✨ **このセッションで進んだこと**
- Issue #<N> 本文を仕様固定済み計画に更新（タイトルに `[実装計画]` 付与）
- サイズチェック PASS / Codex 計画レビュー: 🔴 必須 <X> 件 / 🟡 推奨 <Y> 件（全件反映済）
- TDD 判定: 必須 / スキップ（理由: <one-liner>）

🎯 **これによって変わること**
- DocDD 7軸: BR=<…> / UC=<…> / DM=<…> / SR=<…> / EXT=<…> / API=<…> / TC=<…>（計画反映有無）
- 受け入れ条件・検証定義・Critical Path が Issue 本文に揃い、`/develop`（または `/tdd`）でそのまま着手できる

📋 **次のステップ**
- Issue #<N>（status:todo / 計画確定）
- TDD 必須なら `/tdd <N>`、スキップなら `/develop <N>` を直接
---
```

コピペ用:

```bash
# TDD 必須の場合（RED 証跡を先に作る）
/tdd <N>

# TDD スキップの場合（計画に理由を明記している前提）
/develop <N>
```
````

#### `/verify`

````markdown
## 次のステップ

実装検証完了。Codex コード差分レビュー実施済み。新セッションで `/review` に渡す。

```
---
✨ **このセッションで進んだこと**
- 品質ゲート再実行 PASS（`make test-backend` / `make test-frontend` / `make validate-claude` のうち該当）
- ブラウザヘルスチェック: PASS / N/A / Console / Network 0 件
- TDD 証跡確認: PASS / Codex レビュー: 🔴 必須 <X> 件（解消 <Y>） / 未解消 0 件

🎯 **これによって変わること**
- DocDD 7軸: BR=<…> / UC=<…> / DM=<…> / SR=<…> / EXT=<…> / API=<…> / TC=<…>（整合性検証結果）
- 受け入れ条件と実装が一致したことが Issue コメントに残り、`/review` の独立レビューに渡せる

📋 **次のステップ**
- Issue #<N>（status:in-progress / 検証 PASS）
- 新セッションで `/review <N>` を起動
---
```

コピペ用:

```bash
/review <N>
```
````

#### `/pr`

````markdown
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
````

> **`/merge` は main 側で実行する**: worktree 内から実行すると main 同期がスキップされる。primary worktree のターミナルに戻ってから呼ぶ。

#### `/merge`

````markdown
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
````

---

## 検証

trailer 統一の検証は Issue #46 の検証定義 V3〜V9 を SSOT とする:

| ID | 観点 | コマンド/期待 |
|----|------|--------------|
| V3 | ✨ 網羅 | `^✨ \*\*このセッションで進んだこと\*\*` が 13 コマンドにヒット |
| V4 | 🎯 網羅 | `^🎯 \*\*これによって変わること\*\*` が 13 コマンドにヒット |
| V5 | 📋 網羅 | `^📋 \*\*次のステップ\*\*` が 13 コマンドにヒット |
| V6 | DocDD 7軸 | `DocDD 7軸:` が Group B 4 コマンドにヒット |
| V7 | 1-step 原則 | trailer 領域の `/[a-z-]+` unique 数が各ファイル 2 以下 |
| V8 | 抽象論禁止 | `品質向上 \| 設計改善 \| コードが動く \| 可読性向上 \| 保守性向上` が `.claude/commands/` 配下で 0 件（**本 SSOT は scope 除外**） |
| V9 | 重要メモ保全 | 既存の但し書き（`/develop` の新セッション理由、`/verify` `/pr` `/issue` 等の運用注意）が trailer 置換後も残存 |

---

## 関連

- `.claude/rules/terminology.md` — canonical コマンド名 SSOT
- `.claude/commands/README.md` — コマンド一覧
- Issue #46 — trailer 統一導入の起源
