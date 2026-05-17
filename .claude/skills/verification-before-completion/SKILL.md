---
name: verification-before-completion
description: |
  完了主張前の検証ゲートスキル。
  作業完了・テストパス・ビルド成功を主張する前に、検証コマンドの実行と出力確認を義務付ける。
  `/develop` Phase 3 / `/verify` / `/pr` から参照される。
---

# Verification Before Completion

## 概要

**検証なき完了主張は、効率ではなく不誠実。**

このスキルは「どう証明するか」を定義する。
「いつ止まるか」は [`completion-quality` rule](../../rules/completion-quality.md) が担当する。

| 担当 | 定義 |
|------|------|
| `completion-quality` rule | **いつ止まるか**（3 基準: 取り消せない・繰り返し使われる・印象に残る） |
| **本スキル** | **どう証明するか**（5 ステップゲート） |

---

## 使い方

以下の場面で本スキルが適用される:

- `/develop` Phase 3（品質チェック）で検証コマンドを実行するとき
- `/verify` で証跡を確認するとき（Step 2-3 の機械ゲート `make verify-issue` が変更パスに応じ `test-backend` / `test-frontend` / `validate-claude` / `traceability` を内包し、Step 6 で `verification-result-comment.md` に構造化転記する — [`.claude/commands/verify.md`](../../commands/verify.md)）
- `/pr` で完了ゲートを通すとき
- コミット・プッシュ前に状態を主張するとき
- エージェントチームのメンバーが完了報告するとき

---

## 5 ステップゲート

```
完了を主張する前に、必ずこの順序で実行する:

1. IDENTIFY: この主張を証明するコマンドは何か？
2. RUN:      コマンドを完全実行する（新鮮な実行、部分実行は不可）
3. READ:     出力全体を読み、exit code・失敗数・警告を確認する
4. VERIFY:   出力が主張を裏付けているか？
   - NO  → 実際の状態を証拠付きで報告する
   - YES → 証拠付きで主張する
5. CLAIM:    証拠が揃ってはじめて完了を主張する

どのステップも省略 = 検証していない
```

---

## docdd-starters の proof commands

| 主張 | 必要なコマンド | 不十分な代替 |
|------|--------------|-------------|
| Backend テストがパスする | `make test-backend` の出力: 0 failures | 前回の実行結果、「たぶん通る」 |
| Frontend テストがパスする | `make test-frontend` の出力: 0 failures（`lint:biome` + `check:segments` + `test:unit` まで PASS） | unit だけ通った |
| 全テストがパスする | `make test` の出力: 0 failures | 片方だけ通った |
| `.claude/` の変更が壊れていない | `make validate-claude` の出力: exit 0 | リンクが解決しているように見えた |
| DocDD が整合している | `make traceability` の出力: exit 0 | frontmatter だけ見た |
| バグが修正された | 元の症状を再現するテストが PASS | コード変更した、たぶん直った |
| 回帰テストが有効 | RED-GREEN サイクル検証済み（[`tdd-workflow`](../tdd-workflow/SKILL.md) 参照） | テストが 1 回パスした |
| エージェントが完了した | VCS diff で変更を確認 | エージェントの「成功」報告 |
| 要件を満たしている | 受け入れ条件の 1 行ずつチェック | テストがパスしたから完了 |

> 補足: Wave 5-2 で **`make verify-issue ISSUE=<N>`** が導入済み。これは変更パスから必要証跡カテゴリを検出し、上記 4 ターゲット（`test-backend` / `test-frontend` / `validate-claude` / `traceability`）+ `shell-lint` / `shell-format-check` を dedup 実行し、構造化 JSON（schema SSOT: [`.claude/templates/verify-issue-result.json`](../../templates/verify-issue-result.json)）を産出する。`/verify` Step 2-3 はこれを単一の品質ゲートとして使い、Step 6 で [`.claude/templates/verification-result-comment.md`](../../templates/verification-result-comment.md) に構造化転記する（**Issue コメントだけで検証履歴が再現できる** = Phase 5 のゴール）。なお `make quality-gate` 名のターゲット自体は未導入（Epic #23 後続）。検出されないターゲットは実行されないため、`make verify-issue` の `steps[]` で実際に走ったターゲットを確認する。

---

## 禁止パターン

### 検証前に使ってはいけない表現

- "should"（たぶん通る）
- "probably"（おそらく大丈夫）
- "seems to"（〜のように見える）
- "Great!" / "Perfect!" / "Done!"（検証前の満足表現）

### 合理化への対処

| 言い訳 | 現実 |
|--------|------|
| 「たぶん動く」 | 検証コマンドを実行せよ |
| 「自信がある」 | 自信 ≠ 証拠 |
| 「今回だけ」 | 例外なし |
| 「lint は通った」 | lint ≠ テスト ≠ ビルド |
| 「エージェントが成功と言った」 | 独立して検証せよ |
| 「部分チェックで十分」 | 部分は何も証明しない |

---

## 検証パターン

### テスト

```
# 正しい
make test-backend → 出力を確認 → 「N passed, 0 failed」→ 完了主張
# 間違い
「コード的に正しいはず」→ 完了主張
```

### RED-GREEN（TDD）

```
# 正しい
テスト作成 → 実行（FAIL 確認）→ 実装 → 実行（PASS 確認）→ 完了主張
# 間違い
「回帰テストを書いた」（RED-GREEN 未検証）→ 完了主張
```

### `.claude/` の整合性

```
# 正しい
make validate-claude → exit 0 確認 → 完了主張
# 間違い
「frontmatter だけ目視した」→ 完了主張（リンク到達性は？）
```

### 要件チェック

```
# 正しい
計画を再読 → チェックリスト作成 → 各項目を検証 → ギャップ or 完了を報告
# 間違い
「テストが通ったからフェーズ完了」
```

### エージェント委譲

```
# 正しい
エージェント完了報告 → VCS diff 確認 → 変更内容を検証 → 実際の状態を報告
# 間違い
エージェントの報告を信頼する
```

---

## 失敗扱いになる出力

以下は「パス」として扱わない:

- `0 selected`
- `all skipped`
- `script not found`
- `make test-backend` / `make test-frontend` / `make test` / `make validate-claude` / `make traceability` が FAIL
- 実行コマンド未記録

正しいコマンドを再実行するか、なぜ実行できないかを明記すること。

---

## 適用タイミング

**必ず適用する場面:**
- 完了・成功・パスを主張するあらゆる表現の前
- コミット・PR 作成・タスク完了の前
- 次のタスクへ移る前
- エージェントに委譲した後

---

## 関連ファイル

### プロジェクト内参照

- [rules/completion-quality.md](../../rules/completion-quality.md) - いつ止まるか（棲み分け対象）
- [commands/verify.md](../../commands/verify.md) - `/verify` 機械ゲート（`make verify-issue`）+ Step 6 構造化投稿（Wave 5-2/5-3）
- [templates/verify-issue-result.json](../../templates/verify-issue-result.json) - `make verify-issue` JSON schema 契約 SSOT
- [templates/verification-result-comment.md](../../templates/verification-result-comment.md) - `/verify` 結果コメント記法 SSOT
- [skills/tdd-workflow/SKILL.md](../tdd-workflow/SKILL.md) - TDD 証跡チェーン・RED-GREEN サイクル
- [skills/test-design/SKILL.md](../test-design/SKILL.md) - Critical Path 判定・Coverage expectation
- [rules/tdd-gate.md](../../rules/tdd-gate.md) - TDD 判断基準（必須 / スキップ）

### 外部リファレンス

- [Superpowers: verification-before-completion](https://github.com/obra/superpowers/tree/main/skills/verification-before-completion) - 原典
