---
description: 要件発見・アイデア出しの構造化壁打ち（Issue 化前のフェーズ）。
disable-model-invocation: true
---
要件発見・アイデア出しの壁打ちを行ってください。

`/brainstorm` は **Issue を起票する前の探索フェーズ** に使うコマンドです。Goal / Non-goals / Options / Risks の構造で議論を整理し、最終的に `/issue` での起票につなげます。

---

## `/discuss` との棲み分け

| 観点 | `/brainstorm` | `/discuss` |
|------|--------------|-----------|
| **タイミング** | Issue 起票前（要件・スコープがまだ固まっていない） | 開発中（実装方針に迷ったとき） |
| **目的** | アイデア発散 → スコープ絞り込み → Issue 化準備 | 既存方針の壁打ち・選択肢比較 |
| **出力** | Goal / Non-goals / Options / Chosen direction / Risks / Issue split | 選択肢の比較・推奨方針・抜け漏れチェック |
| **次のステップ** | `/issue`（起票） | `/develop`（実装続行）/ `/update-issue`（既存 Issue 更新） |
| **ユーザー発話例** | 「〇〇したいんだけど、どこから手を付ければ？」 | 「〇〇方式と××方式、どっちが良い？」 |

> **迷ったら**: 「Issue がまだない / スコープが見えない」状態なら `/brainstorm`。「既に Issue がある / 実装中」なら `/discuss`。

---

## 目的

- 曖昧な要望から **Goal / Non-goals** を分離する
- 複数の選択肢（**Options**）を整理し、**Chosen direction** を決める
- **Risks / Scope** を明示する
- 必要なら 1 Issue で扱えるサイズに **分割（Issue split）** する
- 結論を `/issue` での起票に渡せる形でまとめる

## 標準フロー

```
/brainstorm        # 本コマンド（要件発見）
/issue             # 起票（Goal / Non-goals / 受け入れ条件をもとに作成）
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

```
Brainstorm 結論まとめ完了:
  - Goal: [...]
  - Chosen direction: [...]
  - Issue split: [N 件 / なし]

次のステップ:
  /issue              # Goal / Non-goals / 受け入れ条件をもとに起票
```

複数 Issue に分割する場合、最も大きいものから順に `/issue` を呼んで起票する。

---

## 注意事項

- `/brainstorm` は **Issue 起票前** に使うコマンド。既存 Issue の議論なら `/discuss` を使う
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

## 📋 後続 Issue で導入予定（forward reference の隔離）

| 参照先（未存在） | 用途 | 予定 Issue |
|--------------|------|----------|
| Tier-2 escalation（複数 LLM の議論） | Codex + Claude SA 等での多視点比較 | 後続 Issue（D-1 想定） |
| `.claude/skills/llm-debate/SKILL.md` | tier-2 escalation の運用スキル | 後続 Issue（D-1 想定） |
| Umbrella judgment（親 Epic 自動切り出し判定） | サイズ超過時の Epic 化判断 | 後続 Issue（D-1 想定） |

Remember to use the GitHub CLI (`gh`) for all GitHub-related tasks.
