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

検証の中核は **`make verify-issue ISSUE=<N>`（Wave 5-2 / 機械ゲート）** です。
変更パスから必要証跡カテゴリを検出し、対応する品質ターゲットを実行して
構造化 JSON を産出します。`/verify` はその JSON を読み取り、Step 6 で
Issue コメントに構造化転記します（**Issue コメントだけで検証履歴が再現できる**
SSOT の成立 = Phase 5 のゴール）。手順 SSOT の二重化（人手で品質ターゲットを
並べる）を排し、機械ゲートを単一の真実の源とします。

> **責任分離**: `/verify` は機械的な事実確認、後続の独立レビュー（`/review` = 別コマンド）は実装者文脈を外した見落とし検出。本コマンドでは Codex 単独レビュー（Step 5）まで実施する。

**フロー**:
`/verify` Step 1（入力固定）→ Step 2-3（機械ゲート `make verify-issue` 実行 + rc×JSON 判定）→ Step 4（挙動・契約・導線の人手確認）→ Step 4.5（エージェントチーム検証 / 2 レイヤー以上）→ Step 5（Codex コード差分レビュー）→ Step 6（構造化コメント記録）

> **機械ゲートに吸収されない直交関心**: Step 1（入力固定 / `verify-input-capture` SKILL）・Step 4（人手導線確認）・Step 4.5（agent-teams context-fresh）・Step 5（Codex `--base main`）は `make verify-issue` に吸収されない。集約対象は機械的 Step 2-3 のみ。Step 番号アンカー（1 / 4 / 5 / 6 + 4.5）は外部参照（`develop.md` / `tdd.md` / `agent-teams` / `verify-input-capture`）のため温存する。

---

## 手順

### Step 1: 変更内容と入力を固定

> Step 1 の Issue 番号検証 / merge-base diff / 実行コンテキスト記録の **手順 SSOT** は [`.claude/skills/verify-input-capture/SKILL.md`](../skills/verify-input-capture/SKILL.md) を参照。本セクションの bash snippet は同 skill の literal 反映。

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

#### 🔴 案1: commit-before-gate 契約（必読）

`make verify-issue`（Step 2-3 の機械ゲート）の変更検出は **コミット済み差分のみ**:

- PR 未作成時: detector `--git` ＝ `merge-base..HEAD`（`scripts/claude/verify-issue-detect.sh:21-22`「staged / working-tree / untracked changes are out of scope」）
- PR 作成後: `gh pr diff`（PR = コミット済み）

いずれも **未コミット変更を検出しない**。したがって `/verify` は機械ゲートを
**コミット済み状態に対して**実行する契約とする:

1. 上記の working-tree 差分 / untracked が **非空** なら、機械ゲート（Step 2）に進む前に
   ブランチ内へ commit する（`/pr` 前なので可逆・benign）。コミット対象は本 Issue の実装差分。
2. commit 後に Step 2 の機械ゲートを実行する。
3. それでも gate 実行時点で working-tree/untracked が非空のまま残った場合は、
   Step 6 の構造化コメント「未コミット blind-spot 警告」欄に
   **非空のファイル一覧 + Step 4 人手確認で補完したか** を必ず記録する
   （機械検出外であることを明示し、PASS の射程を誤認させない）。

> Step 1 の人手 working-tree/untracked 捕捉は維持する（案1 でも放棄しない）。
> 機械ゲートが見ない領域を人手で可視化し続けることが blind-spot 警告の前提。

### Step 2: 機械ゲート実行（make verify-issue）

> **このステップが品質ゲートの単一の真実の源**。`/develop` で実行した品質チェックが
> 実際に成立しているかを、人手でターゲットを並べず `make verify-issue` に集約して再確認する。
> `make verify-issue` は変更パスから必要証跡カテゴリを検出し、対応する
> `make test-backend` / `make test-frontend` / `make traceability` / `make validate-claude` /
> `make shell-lint` / `make shell-format-check` を dedup 実行し、`*-manual` placeholder を加えて
> 構造化 JSON を産出する（schema SSOT: `.claude/templates/verify-issue-result.json`）。

#### Step 2-1: 本実行専用の出力を pin して実行

`.latest.json` symlink の直読は **stale read 危険**（rc=2/3 で JSON 未書込時に過去 run を読む）。
`VERIFY_ISSUE_OUTPUT` で **本実行専用の出力先を pin** し、そのファイルだけを読む。
`make verify-issue` は step FAIL（rc=1）でも JSON を書く（`scripts/claude/verify-issue.sh:459-462`）ため、
`&&` で繋ぐと rc=1 で JSON を読まず停止する。**rc を capture** して分岐する。

```bash
OUT="$(mktemp "${TMPDIR:-/tmp}/verify-issue-$ARGUMENTS.pinned.XXXXXX").json"
set +e
VERIFY_ISSUE_OUTPUT="$OUT" make verify-issue ISSUE=$ARGUMENTS
rc=$?
set -e
echo "make verify-issue rc=$rc / pinned output=$OUT"
```

> **注意**: `make verify-issue` は変更レイヤーに応じて `make test-backend` 等を内包する。
> 単独で `make test-backend` 等を別途叩く必要はない（人手並列化の余地を排除）。

#### Step 2-2: 出力の新鮮性を検証

pin したファイルが**本実行の・本 Issue の**ものであることを確認する:

```bash
test -s "$OUT" && jq -e \
  --argjson n "$ARGUMENTS" \
  '.inputs.requested_issue == $n and (.inputs.run_id | length > 0)' "$OUT" \
  && echo "fresh: requested_issue/run_id OK" \
  || echo "JSON 不在 or 新鮮性 NG（rc=$rc を Step 3 で判定）"
```

`inputs.requested_issue == $ARGUMENTS` 不一致、または `run_id` 空なら stale read。
JSON 不在（後述 rc=2/3）はここで `test -s` が偽になる。

### Step 3: rc×JSON マトリクス判定 + 証跡確認

#### Step 3-1: rc×JSON マトリクス（🔴 Codex #2/#3/#4）

| `rc` | 意味 | pin JSON | 取扱 |
|:----:|------|:--------:|------|
| 0 | 全 PASS | あり | JSON 転記。`summary.manual_required_count > 0` なら未消化人手証跡を Step 4 で消化（未消化は `未解消`） |
| 1 | step FAIL あり | **あり** | **rc に関わらず JSON を読んで FAIL を転記**（FAIL 結果こそ Issue に残す）。Status は「ブロッカーあり」 |
| 2 | 引数不正 | **なし** | **hard fail**。`verification-result-comment.md`「JSON 不在転記規約」に従い stderr を手動転記。PASS 扱い禁止 |
| 3 | 前提失敗（jq 不在 / gh 認証 / detector / output 書込失敗 / pr_issue_mismatch） | **なし** | **hard fail**。同上。原因を解消して再実行 |

> **原則**: pin した JSON が存在すれば rc=1 でも解析・投稿する（FAIL を握り潰さない）。
> JSON が**存在しない**（rc=2 / rc=3）ときのみ `/verify` を hard fail させる。

#### Step 3-2: TDD 証跡確認

`/develop` の実装サマリーの「TDD 証跡」テーブルを確認する（`make verify-issue` は
TDD の RED-GREEN 履歴までは検証しないため、この確認は機械ゲートに吸収されない）。
判定基準 SSOT: [`.claude/rules/tdd-gate.md`](../rules/tdd-gate.md) / RED-GREEN 証跡フォーマット SSOT: [`.claude/skills/tdd-workflow/SKILL.md`](../skills/tdd-workflow/SKILL.md)。

| 確認項目 | PASS 条件 |
|---------|---------|
| TDD 判定が記載されている | `必須` または `スキップ（理由）` のいずれか。空欄 = FAIL |
| TDD 必須の場合: RED コマンドが記録されている | 実行コマンドと FAILED 結果が明示されている |
| TDD 必須の場合: GREEN コマンドが記録されている | 実行コマンドと PASSED 結果が明示されている |
| TDD 必須の場合: `0 selected` / `all skipped` が RED/GREEN に使われていない | 失敗・成功が明示的に確認されている |
| TDD スキップの場合: 理由が記載されている | 「空欄」「理由なし」は FAIL |

不十分な場合は、`/develop` 側に戻って RED/GREEN を改めて実行・記録する。

#### Step 3-3: 失敗扱いにする例

完了主張前のゲート（5 ステップ）と禁止表現の SSOT は [`.claude/skills/verification-before-completion/SKILL.md`](../skills/verification-before-completion/SKILL.md)。以下を「成功」扱いにしない:

- pin JSON 不在（rc=2 / rc=3）を PASS 扱いにする
- JSON の step `status` に `fail` があるのに転記せず PASS にする
- `summary.manual_required_count > 0` を Step 4 で消化せず PASS にする
- `make verify-issue` の rc を capture せず `&&` で握り潰す
- 実行したと書いてあるが pin した JSON / stderr が残っていない

#### Step 3-4: 構成・配置の確認（機械ゲートの補完）

`make verify-issue` が JSON に立てた `<category>-manual` placeholder（`status: skip` /
`skip_reason: manual_required`）を起点に、ディレクトリ構成・命名規則を人手確認する。
ルール参照: `.claude/rules/file-naming.md`

| チェック | 確認内容 |
|---------|---------|
| ディレクトリ構成 | Backend: `kernel/`, `modules/<domain>/{domain,infrastructure,presentation}/` の分離 |
| ファイル配置 | 正しいレイヤーに配置されているか（ビジネスロジックが `presentation/` に漏れていないか） |
| 命名規則 | Python: snake_case、TS: kebab-case（ファイル）/ PascalCase（コンポーネント）、ドキュメント: kebab-case |
| 重複チェック | 同じロジック・定義が複数箇所に存在しないか |
| import 整理 | 不要な import、循環参照がないか |

問題があれば修正し、差分が変わったら **commit → Step 2 の機械ゲートを再実行**（出力を re-pin）する。

### Step 4: 挙動・契約・導線の確認

> **JSON の `manual_required` step を起点にする**: Step 2 で pin した JSON の
> `steps[]` から `skip_reason == manual_required` の placeholder（`<category>-manual`）を
> 抽出し、その category に対応する人手確認を行う。`summary.manual_required_count > 0` は
> **`exit_code == 0` でも人手証跡が未消化**を意味する（additive セマンティクス）。
> ここで消化できなければ Step 6 の該当証跡欄を `未解消` とする。
>
> ```bash
> jq -r '.steps[] | select(.skip_reason=="manual_required") | "\(.name): \(.notes)"' "$OUT"
> ```

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

参照: [`.claude/skills/agent-teams/SKILL.md`](../skills/agent-teams/SKILL.md)（[`.claude/rules/agent-teams.md`](../rules/agent-teams.md) は薄いポインタ）

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

> **指摘の受領プロトコル**: `.claude/skills/receiving-code-review/SKILL.md` の 6 ステップ（READ → UNDERSTAND → VERIFY → EVALUATE → RESPOND → IMPLEMENT）に従う。`「おっしゃる通りです」` 等のパフォーマティブな同意は禁止。`/verify` 文脈での `🔴/🟡/🟢/❌` ハンドリングは同 SKILL の `/verify`（Codex 単独レビュー）節を参照。

1. **指摘を分類**（`.claude/rules/codex-review.md` 参照）:
   - 🔴 必須修正: 本 Issue 内で即対応（バグ・脆弱性・データ損失リスク）
   - 🟡 推奨: 理由付きで記録、対応要否を判断
   - 🟢 参考: 記録のみ
   - ❌ 却下: 理由を付けて却下

2. **必要な修正を本セッション内で即適用**: 🔴 / 🟡 で actionable な修正案は、ユーザー承認を待たずにその場で修正する。

> **逃げない**: 🔴 / 🟡 で actionable な指摘を後回しにしない。`/verify` は実装検証の最後の関門。本セッション内で修正完了できない場合（`receiving-code-review/SKILL.md` の「ユーザー判断を仰ぐ 4 例外」に該当する場合）は **ユーザー判断待ちに切り替える** — `/review` への bypass は 4 例外でも非該当でも認めない（同 SKILL `/verify` Step 5 節）。

3. **🔴 Codex #4 契約: Step 5 後に差分が変わったら機械ゲートを再実行する**:
   Step 5 の actionable 修正で差分が変化したら、Step 2 で pin した JSON は **stale** になる。
   必ず以下を行ってから Step 6 に進む:
   1. 修正を **commit**（案1: 機械検出はコミット済み差分のみ）
   2. **Step 2 の機械ゲートを再実行**（`VERIFY_ISSUE_OUTPUT` で出力を **re-pin**）
   3. 新しい JSON を再取得し、Step 3 の rc×JSON 判定を再評価
   4. **最新 JSON** を Step 6 に渡す（修正前の古い結果を SSOT 化しない）

   修正なし（指摘が全て 🟢 / ❌、または差分非発生）なら再実行不要。

4. **差分があれば Issue 本文を更新**: `gh issue edit $ARGUMENTS --body-file ...` または `/update-issue` を実行

> **後続 Issue で Codex + Claude SA × 2 の 3 reviewer 並列レビュー（multi-model-review）を導入予定**。本コマンドでは Codex 単独レビューに留める。

### Step 6: 構造化コメント投稿

Step 2 で **pin した JSON**（Step 5 で差分が変わった場合は **再 pin した最新 JSON**）を
`jq` で読み、`.claude/templates/verification-result-comment.md` の各欄に転記して
Issue コメントに投稿する。**Issue コメントだけで検証履歴が再現できる**ことが本ステップの要件。

- 構成は `.claude/templates/verification-result-comment.md` に従う（**見出し・TDD 判定行・Coverage 結果行の記法を厳守**）
  - 見出し: `## 実装検証結果（/verify）` をそのまま使う（`/develop 完了時点` suffix を付けない）
  - 直下に `### 機械検証サマリー（make verify-issue）` を置き、pin JSON を転記する（既存記法は破壊しない）
  - TDD 判定行: スキップ時は `スキップ（理由: ...）` と同一セル内に書く
  - Coverage 結果行: `PASS` / `N/A` / `未解消` のみ（装飾なし）
- 機械検証サマリーへの転記内容（pin JSON → 欄）:
  - `inputs.{requested_issue, resolved_pr, issue_pr_match, source, run_id, output_path, started_at, finished_at}`
  - `steps[]` の `name / categories / command / status / exit_code / skip_reason / partial / notes`
  - `summary.{pass,fail,skip,manual_required,partial,total}_count` と `exit_code`（rc×JSON 取扱表）
  - `error.{code,message,detector_stderr}` / `warnings[]`
  - `manual_required_count > 0` の人手証跡サーフェス（未消化なら `未解消`）
  - 未コミット blind-spot 警告（Step 1 の working-tree/untracked が gate 時に非空だったか）
- JSON 不在（rc=2 / rc=3）の場合: テンプレートの「JSON 不在転記規約」に従い stderr を手動転記し **hard fail**
- `ブラウザ確認` を必ず埋める（フロントエンド変更がある Issue は実施、なければ `N/A`）
- `未解消` が残る場合は理由と対応方針を明記する

```bash
# pin JSON の主要フィールドを確認してから転記する（例）
jq '{inputs, summary, exit_code, steps: [.steps[] | {name, status, skip_reason}]}' "$OUT"

# テンプレートに転記した本文を投稿
gh issue comment $ARGUMENTS --body-file /tmp/verify_result_$ARGUMENTS.md
```

---

## チェックリスト

`/pr`（PR 作成）に渡す前に確認:

- [ ] 案1: working-tree/untracked が非空なら機械ゲート前に commit した（gate はコミット済み状態に対して実行）
- [ ] `VERIFY_ISSUE_OUTPUT` で pin した本実行専用 JSON を読んだ（`.latest.json` 直読していない）
- [ ] `make verify-issue` の rc を capture した（`&&` で握り潰していない）。rc=1 でも JSON を読んで FAIL を転記した
- [ ] pin JSON 不在（rc=2 / rc=3）を PASS 扱いにしていない（hard fail させた）
- [ ] `inputs.requested_issue == <N>` / `run_id` の新鮮性を検証した
- [ ] `summary.manual_required_count > 0` の人手証跡を Step 4 で消化した（未消化は `未解消`）
- [ ] Step 5 で差分が変わった場合: commit → 機械ゲート再実行（出力 re-pin）→ 最新 JSON を Step 6 に渡した
- [ ] `0 selected` / `all skipped` / `script not found` を成功扱いにしていない
- [ ] **TDD 証跡が `verification-result-comment.md` に転記されている**（必須 / スキップ（理由）のいずれか）
- [ ] **TDD 必須の場合: RED / GREEN コマンドの両方が確認・転記されている**
- [ ] 主要導線・契約・状態遷移を確認した
- [ ] DocDD / TC / traceability map の更新要否を確認した
- [ ] フロントエンド変更がある場合は軽量ブラウザヘルスチェック（Console / Network）を実施した
- [ ] Codex コード差分レビュー（`codex review --base main`）を実施した
- [ ] 検証結果（機械検証サマリー + 既存証跡欄）を Issue コメントに構造化記録した

---

## 次のステップ

実装検証完了。Codex コード差分レビュー実施済み。新セッションで `/review` に渡す。

```
---
✨ **このセッションで進んだこと**
- 機械ゲート `make verify-issue ISSUE=<N>` 実行（pin JSON: rc=<0/1> / pass=<P> fail=<F> skip=<S> / manual_required=<M>）
- ブラウザヘルスチェック: PASS / N/A / Console / Network 0 件
- TDD 証跡確認: PASS / Codex レビュー: 🔴 必須 <X> 件（解消 <Y>） / 未解消 0 件 / 構造化コメント投稿済

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

> 本 Issue（Phase 5 / Wave 5-3）では作らない。Epic #23 後続 Wave で管理する。
> `/review` コマンド・`scripts/claude/verify-issue.sh` は既に存在するため本表から除外済（accuracy reconcile）。

| 参照先（未存在） | 用途 | 予定 Issue |
|--------------|------|----------|
| `.claude/rules/multi-model-review.md` | Codex + Claude SA × 2 の 3 reviewer 並列レビュー | Epic #23 後続（D-1 想定） |
| `make quality-gate` ターゲット | 品質ゲート一括実行（注: `make verify-issue` が 5-2 で実質代替済。`quality-gate` 名のターゲット自体は未導入） | Epic #23 後続（D-X 想定） |
| `/screen-verify` + TC YAML 自動実行 | post-merge ステージング検証 | Epic #23 後続（D-X 想定） |

Remember to use the GitHub CLI (`gh`) for all GitHub-related tasks.
