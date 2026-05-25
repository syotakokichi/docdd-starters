---
description: 新しい GitHub Issue を作成します。
disable-model-invocation: true
---
新しい GitHub Issue を作成してください。canonical workflow の起点となるコマンドです。

**CLAUDE.md の開発フローに従って進めてください。**

---

## 役割

- 新しい GitHub Issue を作成する
- `/brainstorm` の結論が提示済みか確認し、未提示なら hard-stop する
- Brainstorm 結論を Issue 本文に保存する
- サイズチェックでスコープが適切に切れているか確認する
- 次に進むべきフェーズ（`/worktree` → `/plan`）を案内する

## 使い方

- 新規作業を起票する場合は `/brainstorm` → `/issue`
- `/issue` は `## Brainstorm 結論` を受け取ってから Issue を作成する
- Brainstorm 結論がない場合は `/brainstorm` へ差し戻す
- 既存 Issue の本文更新は `/update-issue` を使用する

タスクの内容を伝えてください。以下の情報があると良いです:

- `/brainstorm` の `## Brainstorm 結論`
- 起票したい Issue split の対象（複数候補がある場合）

## 標準フロー

Issue 作成前後の正規フロー:

```
/brainstorm        # 必須 discovery。Goal / Non-goals / Options / Risks / Issue split を固定
/issue             # Brainstorm 結論を Issue 本文に保存して起票
/worktree <N>     # worktree 作成 + ブランチ命名（推奨。詳細は parallel-development スキル参照）
/plan <N>         # Issue 本文に仕様固定済みの計画を反映
```

---

## 手順

### Step 0: Brainstorm 結論ゲート（hard-stop）

`/brainstorm` の `## Brainstorm 結論` が、この `/issue` セッションに提示されているか確認する。

必須項目:

- Goal
- Non-goals
- Options（検討した選択肢）
- Chosen direction
- Risks
- Scope（1 Issue で扱う範囲）
- Issue split（必要な場合）

未提示、または上記の必須項目が空欄の場合は Issue を作成しない。以下を案内して終了する:

```bash
/brainstorm
```

既存 Issue の単純な本文修正は `/update-issue` の責務であり、このゲートの例外にしない。

### Step 1: サイズチェック

Brainstorm 結論の Scope / Issue split から影響範囲を概算し、[`.claude/skills/issue-sizing/SKILL.md`](../skills/issue-sizing/SKILL.md) に照らす（適用スキル選択は [`.claude/references/applicable-skills.md`](../references/applicable-skills.md) を参照）:

| 指標 | 上限 |
|------|:----:|
| 変更対象ファイル | 20 |
| 実装タスク数 | 8 |
| 起因 Issue / 負債 | 1 |
| Phase 数 | 1 |

**超過しそうな場合**: 縦スライス（ドメイン概念ごと）に分割して複数 Issue を作成する。
特に「負債まとめて返済」パターンは禁止。棚卸し Issue + 個別 Issue に分ける。

### Step 2: Issue 作成

```bash
gh issue create --title "[タイトル]" --body "$(cat <<'EOF'
# Issue: [タイトル]

## 背景
[なぜ必要か]

## 目的
[何を実現したいか]

## Brainstorm 結論

### Goal
[brainstorm の Goal]

### Non-goals
- [brainstorm の Non-goals]

### Options（検討した選択肢）
| 案 | 内容 | メリット | デメリット |
|:--:|------|---------|-----------|
| A | ... | ... | ... |

### Chosen direction
[採用案と理由]

### Risks
- [リスクと対応]

### Scope（1 Issue で扱う範囲）
- 含める: [変更範囲]
- 含めない: [Non-goals / 後続 Issue]

### Issue split
[分割方針。単一 Issue なら「なし」]

### References
- [参照したドキュメント / Issue / コードパス]

## 受け入れ条件
- [ ] [どうなれば完了か]
EOF
)"
```

### Step 3: ラベル付与（最低 2 つ）

`.github/labels.json` で管理されている canonical labels を **第一候補** として提示し、必要に応じて legacy alias も使用可（移行期間中の互換性確保のため）。

#### 優先度（1 つ選択）— canonical 優先

| canonical | legacy alias | 用途 |
|-----------|--------------|------|
| `P0` | `High` | 1〜2 営業日以内に対応すべき緊急タスク |
| `P1` | `Medium` | 通常の機能追加やバグ修正 |
| `P2` | `Low` | 将来的に対応で良い小変更 |

#### 領域（1 つ以上選択）— canonical 優先

| canonical | legacy alias | 用途 |
|-----------|--------------|------|
| `BE` | `バックエンド` | API・サーバーサイド実装 |
| `FE` | `フロントエンド` | UI/UX 実装・修正 |
| `infra` | `インフラ` | インフラ基盤・CI/CD |
| `docs` | `ドキュメント` | ドキュメント作成・更新 |
| `tests` | `テスト` | テストコードの追加・修正 |
| `bug` | `バグ` | 不具合修正 |
| `chore` | （なし） | ビルド・依存・メタ作業 |

#### ステータス

- `status:todo` を初期付与（`/develop` で `status:in-progress`、`/merge` で `status:done` に遷移）

#### 適用例

```bash
# canonical（推奨）
gh issue create --title "..." --body "..." --label "P1" --label "BE" --label "status:todo"

# legacy alias（移行期間中の互換性）
gh issue create --title "..." --body "..." --label "Medium" --label "バックエンド" --label "status:todo"
```

> ラベル整合の詳細は `.github/labels.json` を参照。canonical / legacy alias どちらでマージされても動作するよう、両方のラベルが定義されている。

### Step 4: 後続フローの案内

Issue 番号を控えて、`## 次のステップ` セクションの ✨/🎯/📋 trailer をユーザーに出力する（trailer SSOT: `.claude/rules/command-trailer.md`）。

---

## 注意事項

- Issue 作成後、`/plan` で実装計画を立案して Issue 本文に追記する
- Issue 本文には `## Brainstorm 結論` を必ず含める。`/plan` はこのセクションを前提にする
- 並列開発する場合は `/worktree <N>` を先に実行し、worktree 内で `/plan` 〜 `/pr` を進める
- 単独 sequential で進める場合は `/plan` 直後に `/develop` でも可（`.claude/skills/parallel-development/SKILL.md` 参照）

---

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

Remember to use the GitHub CLI (`gh`) for all GitHub-related tasks.
