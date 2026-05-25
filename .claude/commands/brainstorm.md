---
description: Issue 作成前に必ず実施する discovery phase。
disable-model-invocation: true
---
Issue 作成前の discovery phase を実施してください。

`/brainstorm` は **すべての新規 Issue の前に必ず実施する必須ステップ** です。
やることが明確に見える場合でも、Goal / Non-goals / Options / Risks を明示してから `/issue` に進みます。
これは「曖昧なときだけ使う壁打ち」ではなく、Issue に入る前の discovery gate です。

---

## `/discuss` との棲み分け

| 観点 | `/brainstorm` | `/discuss` |
|------|--------------|-----------|
| **タイミング** | Issue 起票前（必須） | 開発中（既存 Issue の方針相談） |
| **目的** | discovery → スコープ固定 → Issue 化準備 | 既存方針の壁打ち・選択肢比較 |
| **出力** | Goal / Non-goals / Options / Chosen direction / Risks / Issue split | 選択肢の比較・推奨方針・抜け漏れチェック |
| **次のステップ** | `/issue`（起票） | `/develop`（実装続行）/ `/update-issue`（既存 Issue 更新） |
| **ユーザー発話例** | 「〇〇したいんだけど、どこから手を付ければ？」 | 「〇〇方式と××方式、どっちが良い？」 |

> **迷ったら**: Issue がまだないなら `/brainstorm`。既に Issue があり、実装中の判断相談なら `/discuss`。

---

## 目的

- 新規 Issue の前に **Goal / Non-goals** を分離する
- 複数の選択肢（**Options**）を整理し、**Chosen direction** を決める
- **Risks / Scope** を明示する
- 必要なら 1 Issue で扱えるサイズに **分割（Issue split）** する
- 結論を `/issue` での起票に渡せる形でまとめる

## 標準フロー

```
/brainstorm        # 本コマンド（必須 discovery）
/issue             # 起票（Brainstorm 結論を Issue 本文に保存）
/worktree <N>      # 起票後の作業ブランチ作成
```

---

## 進め方（5 ステップ）

### Step 1: 状況の把握

ユーザーから以下を聞き取る:

- **何を実現したいか** — ざっくりでも良い（後で Goal に落とす）
- **背景・きっかけ** — なぜ今これを考えているか
- **制約** — 期限 / 技術的制約 / 依存先
- **既知の選択肢** — 既に思いついている案があれば

### Step 2: 必須観点でのフレーミング

Goal / Non-goals / Options / Risks の 4 軸で会話を整理する。各軸を **明示的に区別** することで、議論のすれ違いを防ぐ。

| 軸 | 内容 | 質問例 |
|----|------|--------|
| **Goal** | 解きたい本質的な課題（What） | 「成功した状態を 1 文で言うと？」 |
| **Non-goals** | やらないこと、別 Issue に切り出すこと | 「これは含めない、と決めておきたいことは？」 |
| **Options** | 取りうるアプローチ（A / B / C） | 「他に考えられる手段は？」 |
| **Risks** | 失敗パターン・副作用・依存リスク | 「壊れるとしたら何が壊れる？」 |

### Step 3: リサーチ（必要時）

選択肢ごとに事実確認が必要なら、以下を実行する:

| 手段 | 用途 |
|------|------|
| WebSearch / WebFetch | 公式ドキュメント・ベストプラクティス確認 |
| Grep / Glob | 既存コードベースで類似パターンを探す |
| `gh issue list --label <label>` | 同じドメインの既存 Issue / 過去の議論を確認 |

リサーチ結果は Step 5 の結論にエビデンスとして残す。

### Step 4: Codex CLI 単一相談（任意）

複雑な選択肢比較・設計判断で第三者視点が欲しい場合、Codex に相談する。

```bash
# Codex 利用可否を判定
codex --version > /dev/null 2>&1
```

利用可能なら、選択肢の比較を Codex に投げる:

```bash
codex exec "$(cat <<'EOF'
以下の選択肢の妥当性をレビューしてください。

## 状況
[Step 1 のサマリ]

## Options
- A: ...
- B: ...
- C: ...

## 観点
- 実現可能性
- 既存システムへの影響
- 想定されるリスク

## 回答形式
- 各選択肢の評価（メリット / デメリット）
- 推奨案 + 理由
- 見落としやすい論点
EOF
)"
```

> **応答時間**: Codex の応答には 3 〜 5 分かかる。30 秒で打ち切らない。
> **未導入時**: スキップしてユーザーとの対話で結論を出す。`.claude/templates/codex-review-handoff.md` の手動 handoff を案内してもよい。

### Step 5: 結論まとめ（Brainstorm 結論テンプレ）

議論の結論を以下のテンプレートで整理する。**そのまま `/issue` で起票できる粒度** に揃える。
`/issue` はこの `## Brainstorm 結論` を Issue 本文へ保存するため、空欄のまま終わらない。

```markdown
## Brainstorm 結論

### Goal
[解きたい本質的な課題を 1〜2 文]

### Non-goals
- [このスコープで扱わないこと 1]
- [このスコープで扱わないこと 2]

### Options（検討した選択肢）
| 案 | 内容 | メリット | デメリット |
|:--:|------|---------|-----------|
| A | ... | ... | ... |
| B | ... | ... | ... |
| C | ... | ... | ... |

### Chosen direction
[採用案 X とその理由]

### Risks
- [リスク 1: 影響範囲、対応策]
- [リスク 2: 影響範囲、対応策]

### Scope（1 Issue で扱う範囲）
- 含める: [変更範囲のリスト]
- 含めない: [Non-goals に該当する分]

### Issue split（必要な場合）
- [子 Issue 1: タイトル案 / スコープ]
- [子 Issue 2: タイトル案 / スコープ]
- 親 Epic を切る場合: [タイトル案]

> サイズ上限（変更ファイル 20 / タスク 8）を超えそうなら必ず分割する（`.claude/rules/issue-sizing.md`）。

### References
- [リサーチで参照した公式ドキュメント / 既存 Issue / コードパス]
- [Codex 相談結果のサマリ（実施した場合）]
```

---

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

複数 Issue に分割する場合、最も大きいものから順に `/issue` を呼んで起票する。

---

## 注意事項

- `/brainstorm` は **Issue 起票前に必須** のコマンド。既存 Issue の議論なら `/discuss` を使う
- `/issue` に進むには `## Brainstorm 結論` が必要。ない場合は `/issue` 側で hard-stop する
- Goal と Non-goals を必ず分ける（混ざるとスコープが膨張する）
- サイズ上限を超えそうなら必ず Issue split する
- 結論は `/issue` で再利用できる粒度にまとめる

---

## 失敗時の対処

| 状況 | 対処 |
|------|------|
| Goal が定まらない | 「成功した状態を 1 文で言うと？」と問い直す。1 文で書けないなら課題が複数混在している |
| Options が出ない | 既存コードベースの類似パターンを Grep / Glob で探す。他プロジェクトの事例を WebSearch |
| Issue split で粒度が揃わない | サイズチェック（変更ファイル 20 / タスク 8）を基準にする。`.claude/rules/issue-sizing.md` 参照 |
| 結論が出ない | 一度持ち帰る判断も OK。「現時点の暫定案 + 次の調査ポイント」をまとめて終わる |

---

Remember to use the GitHub CLI (`gh`) for all GitHub-related tasks.
