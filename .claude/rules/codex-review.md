# Codex CLI レビュー運用ルール

## 概要

Codex CLI を活用した独立レビューの運用ルール。
`/plan`（計画立案）と `/verify`（実装検証）に Codex レビューステップを組み込む。

---

## セットアップ

```bash
# 認証
codex login

# 認証確認
codex --version
```

---

## `/plan` Phase 5: 計画テキストレビュー

計画立案完了後、Codex で計画テキストをレビューする。

### 手順

1. 計画テキストを一時ファイルに書き出す

```bash
gh issue view <N> --json body -q '.body' > /tmp/issue_<N>.md
```

2. プロンプトテンプレートを使って Codex に投入

```bash
# テンプレートからプロンプトを生成
cat .claude/templates/codex-plan-review-prompt.md /tmp/issue_<N>.md > /tmp/codex_prompt_<N>.md

# Codex 実行
codex exec "$(cat /tmp/codex_prompt_<N>.md)"
```

3. 結果を Issue コメントに記録

```bash
gh issue comment <N> --body "## Codex 計画レビュー結果
<結果をここに貼り付け>"
```

### 注意

- **`--base` は使わない**: `/plan` はコード差分ではなく計画テキストのレビュー
- `codex exec` + プロンプトで実行する

---

## `/verify` Step 5: コード差分レビュー

実装検証の最終ステップで、Codex にコード差分をレビューさせる。

### 手順

1. Codex review を実行

```bash
codex review --base main
```

2. 結果を Issue コメントに記録

```bash
gh issue comment <N> --body "## Codex コードレビュー結果
<結果をここに貼り付け>"
```

### 注意

- **`--base` と `[PROMPT]` の同時使用は不可**（v0.120.0 で確認済み）
  - `the argument '--base <BRANCH>' cannot be used with '[PROMPT]'`
- `codex review --base main` はプロンプト指定なしで差分全体をレビューする
- 観点メモは `.claude/templates/codex-verify-review-prompt.md` を参照（handoff 時の参考用）

---

## Codex CLI 仕様メモ

| 項目 | 仕様 |
|------|------|
| `codex exec "prompt"` | 非対話実行（計画レビュー用） |
| `codex review --base main` | コード差分レビュー（実装検証用） |
| `codex review --uncommitted` | 未コミット変更のレビュー |
| `--base` + `[PROMPT]` 同時使用 | **不可**（エラーになる） |
| `codex -q` | **存在しない** |
| 長いプロンプト | `/tmp/codex_prompt_<N>.md` 経由で `codex exec "$(cat ...)"` |

---

## 応答時間

- Codex の応答には **3〜5 分** かかる場合がある
- **30 秒で応答なしと判定しないこと**
- タイムアウト設定がある場合は十分な値（300秒以上）を設定する

---

## 指摘の分類

Codex からの指摘は以下の 4 段階で分類する:

| 分類 | 意味 | 対応 |
|:----:|------|------|
| 🔴 必須 | バグ・脆弱性・データ損失リスク | マージ前に必ず修正 |
| 🟡 推奨 | 設計改善・可読性・パフォーマンス | 判断して対応（理由を記録） |
| 🟢 参考 | スタイル・命名・ドキュメント | 記録のみ、対応は任意 |
| ❌ 却下 | 誤検知・コンテキスト不足による的外れ指摘 | 却下理由を記録 |

### 対応ルール

- 🔴 が 1 件でもあれば **修正してから PR 作成**
- 🟡 は対応/非対応の判断理由を Issue コメントに記録
- 🟢 は一覧に残すだけで OK
- ❌ は却下理由を明記（次回のプロンプト改善に活用）

---

## 高リスク変更の定義

以下の変更を含む場合、Codex レビューの指摘に特に注意を払う:

| 領域 | 例 |
|------|-----|
| 決済 | 課金ロジック、金額計算、請求処理 |
| 認証 | ログイン、トークン管理、権限チェック |
| マイグレーション | DBスキーマ変更、データ移行 |
| 契約変更 | プラン変更、解約処理 |
| 状態管理 | ステータス遷移、排他制御 |
| 外部リダイレクト | URL生成、OAuth コールバック |

高リスク変更では:
- 🟡 推奨も原則対応する
- 却下（❌）する場合は詳細な理由を記録する

---

## Fallback（Codex 未導入時）

`codex --version` が失敗した場合:

1. **サイレントスキップ禁止** — 必ずユーザーに通知する
2. `.claude/templates/codex-review-handoff.md` を出力
3. ユーザーに手動で Codex / ChatGPT にレビューを依頼するよう案内

### 判定方法

```bash
if codex --version > /dev/null 2>&1; then
  # Codex 利用可能 → レビュー実行
else
  # Codex 未導入 → fallback handoff テンプレ出力
fi
```

`capability-matrix.md` の `codex_cli` を参照。

---

## D-1 への移行パス

本ルールは Codex **単体** レビュー用。Phase D-1 で以下に拡張予定:

1. `codex-review.md` → `multi-model-review.md` にリネーム
2. Claude SA×2 並列レビューセクション追加
3. 統合オーケストレーター節追加（3 reviewer の指摘突き合わせ）

---

## 関連ファイル

- [commands/plan.md](../commands/plan.md) — Phase 5
- [commands/verify.md](../commands/verify.md) — Step 5
- [templates/codex-plan-review-prompt.md](../templates/codex-plan-review-prompt.md) — `/plan` 用プロンプト
- [templates/codex-verify-review-prompt.md](../templates/codex-verify-review-prompt.md) — `/verify` 用観点メモ
- [templates/codex-review-handoff.md](../templates/codex-review-handoff.md) — Fallback テンプレ
- [references/capability-matrix.md](../references/capability-matrix.md) — capability 定義
