---
description: Issue の実装検証を行います。
argument-hint: "<issue-number>"
disable-model-invocation: true
---
Issue #$ARGUMENTS の実装検証を行ってください。

**`/develop` 完了後、`/pr`（PR 作成）前に同一実装セッションで実行するコマンドです。**

---

## 概要

`/verify` は、実装内容の **事実確認と証跡作成** を担当します。
ここでは「何を実行し、何を確認し、何が未確認か」を揃えます。

> **責任分離**: `/verify` は機械的な事実確認、後続の独立レビュー（後続 Issue で `/review` として整備予定）は実装者文脈を外した見落とし検出。本コマンドでは Codex 単独レビュー（Step 5）まで実施する。

**フロー**:
`/verify`（Step 1〜4: 検証）→ Step 5: Codex コード差分レビュー → Step 6: Issue コメント記録

---

## 手順

### Step 1: 変更内容と入力を固定

`/verify` は `/pr`（PR 作成のコミット）より前に実行されるため、実装はコミット済みではなく
**ワーキングツリーに残っている可能性が高い**。コミット済み差分（`MERGE_BASE...HEAD`）だけを見ると
未コミット変更が抜け落ちて検証入力が空になる。コミット済みとワーキングツリーの両方を取得する。

```bash
# Issue 内容と既存コメント取得
gh issue view $ARGUMENTS --comments

# main 同期 + merge-base 算出（main 側の追加変更を「削除」と誤認しないため）
git fetch origin main
MERGE_BASE=$(git merge-base HEAD origin/main)

# 1. コミット済みの差分（merge-base...HEAD）
echo "--- Committed diff (MERGE_BASE...HEAD) ---"
git diff "$MERGE_BASE"...HEAD --stat
git diff "$MERGE_BASE"...HEAD --name-only

# 2. ワーキングツリー差分（staged + unstaged）— 未コミットの実装を取りこぼさない
echo "--- Working-tree diff (HEAD vs working tree) ---"
git diff HEAD --stat
git diff HEAD --name-only

# 3. Untracked ファイル（新規作成されたが add されていないファイル）
echo "--- Untracked files ---"
git ls-files --others --exclude-standard
```

確認すること:
- Issue 本文の受け入れ条件
- `/develop` で記録した実装サマリー
- 変更ファイルと主要レイヤー（**コミット済み + ワーキングツリー + untracked の合算**）
- 実行コンテキスト（main / worktree、worktree path、branch、merge-base）

> **未コミットで `/verify` する場合**: ワーキングツリー差分と untracked が空でないことを確認してから次ステップへ。両方が空なら「実装が見えていない」状態のため、`/develop` に戻るか、コミットしてから再実行する。

### Step 2: 構成・配置チェック

新規ファイル・変更ファイルが正しいディレクトリ構成と命名規則に従っているか確認する。
ルール参照: `.claude/rules/file-naming.md`

| チェック | 確認内容 |
|---------|---------|
| ディレクトリ構成 | Backend: `kernel/`, `modules/<domain>/{domain,infrastructure,presentation}/` の分離 |
| ファイル配置 | 正しいレイヤーに配置されているか（例: ビジネスロジックが `presentation/` に漏れていないか） |
| 命名規則 | Python: snake_case、TS: kebab-case（ファイル）/ PascalCase（コンポーネント）、ドキュメント: kebab-case |
| 重複チェック | 同じロジック・定義が複数箇所に存在しないか |
| import 整理 | 不要な import、循環参照がないか |

問題があれば修正してから次のステップへ。

### Step 3: 品質ゲート再実行（必須）

`/develop` で実行した品質チェックが、**実際に成立しているか** を改めて実行・確認する。

#### Step 3-1: 変更レイヤーごとの品質チェック

```bash
# Backend のみ
make test-backend

# Frontend のみ
make test-frontend

# 両方変更
make test

# .claude/ の dx-docs 変更時
make validate-claude

# DocDD 変更時
make traceability
```

#### Step 3-2: TDD 証跡確認

`/develop` の実装サマリーの「TDD 証跡」テーブルを確認する。

| 確認項目 | PASS 条件 |
|---------|---------|
| TDD 判定が記載されている | `必須` または `スキップ（理由）` のいずれか。空欄 = FAIL |
| TDD 必須の場合: RED コマンドが記録されている | 実行コマンドと FAILED 結果が明示されている |
| TDD 必須の場合: GREEN コマンドが記録されている | 実行コマンドと PASSED 結果が明示されている |
| TDD 必須の場合: `0 selected` / `all skipped` が RED/GREEN に使われていない | 失敗・成功が明示的に確認されている |
| TDD スキップの場合: 理由が記載されている | 「空欄」「理由なし」は FAIL |

不十分な場合は、`/develop` 側に戻って RED/GREEN を改めて実行・記録する。

#### Step 3-3: 失敗扱いにする例

- `pytest` が marker 条件で全 deselect
- `npm run xxx` が script 不在で失敗
- `make test-backend` / `make test-frontend` / `make validate-claude` / `make traceability` が FAIL
- 実行したと書いてあるが結果が残っていない

### Step 4: 挙動・契約・導線の確認

変更種別に応じて、**最短導線** で挙動を確認する。

#### API / Schema / 型変更
- request / response が Issue と実装で一致している
- 呼び出し元、状態管理、次画面の期待値が一致している
- 正常系だけでなく、主要な異常系も確認する
- 関連する `docs/7-axis/6_API/<domain>/*.yaml` が更新されている

#### 画面 / 状態管理 / ルーティング変更
- 入口画面から完了画面までの導線が通る
- 戻る、再読み込み、URL パラメータ欠落時の挙動を確認する
- 分岐条件がある場合は代表パターンを確認する

#### DB / Migration 変更
- model / migration / repository / service / API が整合している
- 必要に応じて upgrade / downgrade、既存データ影響、NOT NULL / FK 制約を確認する
- `docs/7-axis/3_DM/DM-*.md` が更新されている

#### 軽量ブラウザヘルスチェック（フロントエンド変更がある場合）

**目的**: ローカルで即時確認できる範囲のランタイム異常（JS error / 4xx / 5xx）を PR 作成前の最後の関門として検知する。
**対象**: `apps/frontend/` 配下を変更した Issue。
**非対象**: API / バックグラウンド処理 / 設定ファイルのみの変更 → `N/A` として記録。

##### 実行手順

1. **dev サーバー起動確認**:
   ```bash
   # 既に起動していれば不要
   cd apps/frontend && npm run dev > /tmp/nextjs-dev.log 2>&1 &
   ```

2. **対象ページへ手動遷移**: `http://localhost:3000/対象URL` をブラウザで開く

3. **ブラウザ DevTools の Console を確認**:
   - 新たな `error` / `warn` が出ていないか確認（0 件なら PASS）
   - 出ている場合は内容を確認し、本 Issue の変更起因なら修正

4. **Network タブで 4xx / 5xx を確認**:
   - 意図しない `4xx` / `5xx` がないか確認（0 件なら PASS）

> **N/A にしていいのは**「ブラウザ導線自体が存在しない変更」だけ。フロントエンド変更があるのに「ローカル再現が難しい」という理由で N/A にしないこと。

#### DocDD / TC / Traceability 確認

DocDD の変更がある、または本来あるべき変更がある場合は以下を確認:
- DM / API / UC / SR と実装内容が一致している
- テストが追加・変更された場合、`docs/testing/traceability/<domain>_map.json` が更新されている
- 仕様変更・新規分岐・API 契約変更があるのにテスト差分がない場合、**理由が記録されている**
- TC 軸に残すべき内容が未反映でない

> **Note**: UI 設計（Pencil）の整合性確認は `/plan` Phase 1.5 で完結する。`/verify` では比較を行わない（`.claude/rules/project-workflow.md` 参照）。

### Step 4.5: エージェントチーム検証（コンテキストフレッシュ）

**2 レイヤー以上にまたがる変更では、コンテキストフレッシュ（context fresh）spawn による検証が必須。**
単一レイヤーの変更では単一セッションで検証してよい。

**コンテキストフレッシュの原則**:
- 実装セッションのコンテキストを引き継いだまま検証しないこと
- 新しいサブエージェントを spawn し、最小限の入力（Issue 本文、`git diff`、テスト結果）のみ渡すこと
- 修正後の再検証でも新しいサブエージェントを spawn すること

参照: `.claude/rules/agent-teams.md`

**バックエンド検証チーム例:**
```text
Issue #$ARGUMENTS の実装をチームで検証して。
- スキーマ担当: Model 定義、マイグレーション、既存モデルとの整合性
- サービス担当: ロジック、DI、トランザクション、エラーハンドリング
- API 担当: エンドポイント設計、テストカバレッジ、認証認可
- 横断チェッカー: 各担当の報告を突き合わせ、レイヤー間の隙間を指摘
- テスト実行担当: 実行結果と no-op テストがないか確認
```

**フロントエンド検証チーム例:**
```text
Issue #$ARGUMENTS のフロントエンド実装をチームで検証して。
- コンポーネント担当: Container/Presentational 分離、Private Folder 構成
- データフェッチ担当: Server/Client 境界、ローディング/エラー/状態復元
- UI/UX 担当: レスポンシブ、アクセシビリティ、デザインとの差分
- 横断チェッカー: API 契約、型、状態管理、画面遷移の整合性
```

指摘の扱い:
- 🔴 必須修正は `/pr`（PR 作成）に渡す前に解消
- 🟡 推奨は理由付きで記録
- スコープ外に見えても本 Issue 実装に直接関連する問題は本 Issue 内で対応

### Step 5: Codex コード差分レビュー

実装の独立レビューとして Codex CLI でコード差分をレビューする。
ルール参照: `.claude/rules/codex-review.md`

> ⚠️ **`/plan` と `/verify` では Codex への渡し方が異なる**
> - `/plan`: 計画テキストのレビュー → `--base main` は使わない
> - `/verify`: **コード差分のレビュー** → `--base main` を使う
> - `--base` と `[PROMPT]` の同時使用は不可（v0.120+ で確認済み）

#### Codex 利用可否を判定

```bash
codex --version > /dev/null 2>&1
```

#### Codex が利用可能な場合

```bash
codex review --base main
```

> **注意**: Codex の応答には 3〜5 分かかる場合がある。30 秒で応答なしと判定しないこと。
> **worktree の場合**: サマリに worktree パス（例: `.claude/worktrees/issue-<N>/`）を明記すること。

#### Codex が利用不可の場合（Fallback）

**サイレントスキップ禁止** — 必ずユーザーに通知する。

1. `.claude/templates/codex-review-handoff.md` の「コードレビュー」セクションを出力
2. ユーザーに手動で Codex / ChatGPT にレビューを依頼するよう案内

#### Codex 結果の反映

1. **指摘を分類**（`.claude/rules/codex-review.md` 参照）:
   - 🔴 必須修正: 本 Issue 内で即対応（バグ・脆弱性・データ損失リスク）
   - 🟡 推奨: 理由付きで記録、対応要否を判断
   - 🟢 参考: 記録のみ
   - ❌ 却下: 理由を付けて却下

2. **必要な修正を本セッション内で即適用**: 🔴 / 🟡 で actionable な修正案は、ユーザー承認を待たずにその場で修正し、Step 3 の品質チェックを再実行する。

> **逃げない**: 🔴 / 🟡 で actionable な指摘を後回しにしない。`/verify` は実装検証の最後の関門。

3. **差分があれば Issue 本文を更新**: `gh issue edit $ARGUMENTS --body-file ...` または `/update-issue` を実行

> **後続 Issue で Codex + Claude SA × 2 の 3 reviewer 並列レビュー（multi-model-review）を導入予定**。本コマンドでは Codex 単独レビューに留める。

### Step 6: Issue コメントに記録

検証結果全体（Step 1〜4 の結果 + Step 5 の Codex レビュー結果）をまとめて記録する。

- 構成は `.claude/templates/verification-result-comment.md` に従う（**見出し・TDD 判定行・Coverage 結果行の記法を厳守**）
  - 見出し: `## 実装検証結果（/verify）` をそのまま使う（`/develop 完了時点` suffix を付けない）
  - TDD 判定行: スキップ時は `スキップ（理由: ...）` と同一セル内に書く
  - Coverage 結果行: `PASS` / `N/A` / `未解消` のみ（装飾なし）
- `ブラウザ確認` を必ず埋める（フロントエンド変更がある Issue は実施、なければ `N/A`）
- `未解消` が残る場合は理由と対応方針を明記する

```bash
gh issue comment $ARGUMENTS --body-file /tmp/verify_result_$ARGUMENTS.md
```

---

## チェックリスト

`/pr`（PR 作成）に渡す前に確認:

- [ ] 変更レイヤーに対応する `make test-backend` / `make test-frontend` / `make test` のいずれかを再実行した
- [ ] `.claude/` の dx-docs を変更した場合は `make validate-claude` を再実行した
- [ ] DocDD を更新した場合は `make traceability` を再実行した
- [ ] 実行した品質チェックと結果が残っている
- [ ] `0 selected` / `all skipped` / `script not found` を成功扱いにしていない
- [ ] **TDD 証跡が `verification-result-comment.md` に転記されている**（必須 / スキップ（理由）のいずれか）
- [ ] **TDD 必須の場合: RED / GREEN コマンドの両方が確認・転記されている**
- [ ] 主要導線・契約・状態遷移を確認した
- [ ] DocDD / TC / traceability map の更新要否を確認した
- [ ] フロントエンド変更がある場合は軽量ブラウザヘルスチェック（Console / Network）を実施した
- [ ] Codex コード差分レビュー（`codex review --base main`）を実施した
- [ ] 検証結果を Issue コメントに記録した

---

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

> **新しいセッションで PR 作成 / 独立レビューを行うのが推奨**: 検証者の文脈を引き継いだまま PR を出すと、見落としを PR コメントとして拾えない。

---

## 注意事項

- `/develop` 完了後、`/pr` 前に必ず実行すること
- 品質チェックは変更箇所に応じて再実行する（全レイヤー網羅でなくて OK）
- フロントエンド変更がある場合は軽量ブラウザヘルスチェックを必ず実施する
- Codex レビューはサイレントスキップ禁止。Codex 未導入時は handoff テンプレートで案内する

---

## 📋 後続 Issue で導入予定（forward reference の隔離）

| 参照先（未存在） | 用途 | 予定 Issue |
|--------------|------|----------|
| `/review` コマンド | 独立レビュー（実装者文脈を外した見落とし検出） | 後続 Issue（2-2 想定） |
| `.claude/rules/multi-model-review.md` | Codex + Claude SA × 2 の 3 reviewer 並列レビュー | 後続 Issue（D-1 想定） |
| `.claude/skills/verify-input-capture/SKILL.md` | Step 1 の入力固定 SSOT | 後続 Issue（5-1 想定） |
| `.claude/skills/receiving-code-review/SKILL.md` | レビュー指摘の分類スキル | 後続 Issue（4-3 想定） |
| `scripts/claude/verify-issue.sh` / `quality-gate.sh` | Issue 単位の品質ゲート自動化 | 後続 Issue（5-1 想定） |
| `make quality-gate` ターゲット | 品質ゲート一括実行 | 後続 Issue（5-1 想定） |
| `/screen-verify` + TC YAML 自動実行 | post-merge ステージング検証 | 後続 Issue（D-X 想定） |

Remember to use the GitHub CLI (`gh`) for all GitHub-related tasks.
