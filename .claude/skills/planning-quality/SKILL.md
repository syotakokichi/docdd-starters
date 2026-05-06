---
name: planning-quality
description: |
  計画立案品質ルール。リサーチ必須、依存先トレース、観点別チェック（API/型/DB/UI）、
  DocDD更新要否、証跡マッピング表、UI State Matrix、サイズチェック、ユーザー相談、
  Codex レビュー必須の品質基準を提供。/plan で参照される。
---

# 計画立案品質スキル

## 概要

Issue の実装計画を立案する際の品質基準を定義する。
**時間をいくらかけてもいいので品質を優先する。**

**非ゴール**: 計画のフォーマット定義（テンプレートは `.claude/templates/issue-implementation-plan.md`）。

## 使い方

以下のコマンドで参照される:
- `/plan` — 計画立案の全フェーズで品質基準として使用
- `/issue` — Issue 作成時のサイズ判断で参照（[issue-sizing](../issue-sizing/SKILL.md) と併用）

## 詳細

### 基本原則

- 不完全な計画で実装を始めるより、十分な調査と検討を行う
- 「とりあえず動く」より「正しく動く」を優先する
- 実装だけでなく、依存先・下流影響・DocDD まで閉じる

### 1. リサーチ

実装前に以下を調査し、計画に反映する。

| 調査対象 | 方法 | 目的 |
|---------|------|------|
| 公式ドキュメント | WebSearch / WebFetch | 最新のベストプラクティス確認 |
| 既存コードベース | Grep / Glob / Read | 一貫性のある実装 |
| 類似実装 | GitHub 検索 | 実績のあるパターン参照 |

リサーチが必要なケース:
- 新しいライブラリ / フレームワーク機能を使う
- セキュリティに関わる
- パフォーマンスが重要
- 外部サービス連携がある

### 2. 変更起点ごとの依存先トレース

**変更ファイル候補の列挙だけで終わらせない。**

最低限、以下を Issue に残す。

```markdown
### 依存先・波及範囲
| 変更起点 | 波及先 | 確認内容 |
|---------|--------|---------|
| backend api/public.py | frontend src/lib/api/*.ts | request/response 契約 |
| frontend src/lib/api/*.ts | hooks / container | 呼び出しシグネチャ、エラー処理 |
| Zustand / store | confirm / payment / complete | 状態の保存・復元・画面遷移 |
| model / migration | repository / service / callback | 永続化・例外・冪等性 |
```

### 3. 観点別の必須確認

#### API変更がある場合

- request / response / status code の変更点を明文化
- 呼び出し元を `rg` で全列挙
- 型定義、API client、hooks、containers、pages まで追う
- 影響を受ける次画面、エラー処理、状態管理まで確認

#### 型変更がある場合

- 定義元を確認
- 利用箇所（hook / container / presentational / tests）を確認
- store / query param / route state / hidden field などの受け渡しを確認

#### DB / Model変更がある場合

- model → repository → service → api → docs → tests の順に確認
- migration の要否
- repository / callback / batch / cleanup への波及
- 既存データとの互換性

#### UI変更がある場合

- 遷移元 / 確認画面 / 完了画面 / 戻る導線 / 例外導線を確認
- URL パラメータ、検索パラメータ、token の引き継ぎを確認
- リロード後の状態復元方法を確認

### 4. 見落としやすいが必須の観点

- **ID handoff**: `user_id`, `application_id`, `token` などが画面間 / API 間で一致しているか
- **状態復元**: confirm → submit → complete で再読込しても成立するか
- **URL契約**: path param / query param / callback URL / success URL の整合
- **モード分岐**: 新分岐が store flag や route と矛盾していないか
- **下流要件**: この Issue の完了条件が後続機能の前提と矛盾していないか

### 5. DocDD 更新要否

| 変更レイヤー | 確認先 | 更新要否 |
|------------|--------|:--------:|
| API層（FastAPI routes） | `docs/7-axis/6_API/` | ✅/— |
| Model / Schema層 | `docs/7-axis/3_DM/` | ✅/— |
| Service層（ビジネスルール変更） | `docs/7-axis/4_SR/` | ✅/— |
| UseCase / Flow変更 | `docs/7-axis/2_UC/` | ✅/— |
| テスト戦略変更 | `docs/7-axis/7_TC/`, `docs/testing/traceability/` | ✅/— |

**原則**: 実装と同じ Issue 内で更新する。

### 6. 証跡マッピング表

`.claude/templates/issue-implementation-plan.md` の「🗺️ 証跡マッピング表」を全行コピーし、各行を ✅ または — で埋める。空欄禁止。

### 7. UI State Matrix

UI 変更がある場合、`.claude/templates/issue-implementation-plan.md` の「🖥️ UI State Matrix」を埋める。

### 8. サイズチェック

詳細は [skills/issue-sizing/SKILL.md](../issue-sizing/SKILL.md) を参照。

```markdown
## 📏 サイズチェック
| 指標 | 値 | 上限 | 判定 |
|------|:--:|:----:|:----:|
| 変更対象ファイル | ? | 20 | ✅/❌ |
| 実装タスク数 | ? | 8 | ✅/❌ |
| 起因 Issue / 負債 | ? | 1 | ✅/❌ |
| Phase 数 | ? | 1 | ✅/❌ |
| API/型の契約変更点 | ? | 3 | ✅/❌ |
| 下流呼び出し元数 | ? | 5 | ✅/❌ |
```

2つ以上 ❌ の場合、分割案を出す。

### 9. ユーザー相談

計画確定前に、以下の **候補トピック** を Pattern B フィルタ（`commands/plan.md` Phase 2 SSOT）にかけ、default で進められないものだけ AskUserQuestion で surface する。**4 つすべてを必ず質問するわけではない**（候補トピックはフィルタ入力であり、強制相談リストではない）。

- 実装方針の候補
- 推奨方針と理由
- 技術的トレードオフ
- 後続 Issue の見通し

**0 個例外**: 候補がすべて default で処理できる場合は AskUserQuestion を呼ばず、default 進行を宣言した上で Phase 3 へ進む。論点フィルタとフォーマット定義（呼び出しルール / 禁止パターン / 呼び出し例）の SSOT は [`commands/plan.md`](../../commands/plan.md) Phase 2（Pattern B + AskUserQuestion）。本セクションの候補リスト以外は HOW（フォーマット・上限・例）と重複させない（Phase 2 SSOT に委譲する）。

### 10. Codex レビュー（必須）

`/plan` の Phase 5 で Codex CLI による独立レビューを必ず実施する（[`.claude/rules/codex-review.md`](../../rules/codex-review.md) 参照）。Codex 未導入時は `.claude/templates/codex-review-handoff.md` で handoff する（サイレントスキップ禁止）。

---

### 未完了判定

以下のどれかが欠けている場合、計画は未完了。

- 依存先・波及範囲の表が埋まっていない
- API / 型 / state / route の契約差分が明文化されていない
- UI変更なのに状態復元 / 戻る導線 / 完了画面を見ていない
- DB変更なのに migration / repository / service / API / docs / tests を追っていない
- DocDD / TC / traceability map の更新要否が出ていない
- 証跡マッピング表が全行埋まっていない
- UI 変更があるのに UI State Matrix が埋まっていない
- **相談すべき論点があるのに**ユーザー相談を経ずに方針を確定している
- Codex レビューを実施していない（または handoff も出していない）

### 重要ポイントの書き方

- 🔴 Critical: 漏れると重大な問題
- 🟠 High: 対応しないと高リスク
- 🟡 Medium: 品質向上に寄与
- 🟢 Low: 優先度は低い

### アンチパターン

1. リサーチなしで実装開始する
2. 変更ファイル候補だけ並べて依存先を追わない
3. 状態復元や URL パラメータを見ずに UI だけ見る
4. DocDD を根拠なく「後続対応」に逃がす
5. 「完了条件」を実装タスクの言い換えで済ませる
6. 外部リファレンスを残さない

## 関連ファイル

- [`.claude/CLAUDE.md`](../../CLAUDE.md) - 開発ガイド
- [`.claude/rules/project-workflow.md`](../../rules/project-workflow.md) - Stage と DocDD 更新ルール
- [`.claude/skills/issue-sizing/SKILL.md`](../issue-sizing/SKILL.md) - サイジングルール
- [`.claude/templates/issue-implementation-plan.md`](../../templates/issue-implementation-plan.md) - Issue本文テンプレート
- [`.claude/rules/codex-review.md`](../../rules/codex-review.md) - Codex レビュー運用ルール
