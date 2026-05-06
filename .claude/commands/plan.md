---
description: GitHub Issue の仕様固定済み実装計画を作成します。
argument-hint: "<issue-number>"
disable-model-invocation: true
---
GitHub Issue $ARGUMENTS の仕様固定済み実装計画を作成してください。

**時間をいくらかけてもいいので品質を優先してください。**
**リサーチして公式のベストプラクティスがあれば採用してください。**
**CLAUDE.md の開発フローに従って進めてください。**

---

## 前提

- Issue が作成済み（`/issue` で起票するか、既存の Issue を対象とする）
- 標準では `/worktree $ARGUMENTS` 後に実行する（worktree 内で計画立案 → 実装 → 検証 → PR 作成）

## このコマンドの完了条件

Issue 本文が「実装可能」ではなく、**仕様固定済み** になっていること。

最低限、以下が Issue 本文に残っていること:

- 影響範囲（依存先・波及範囲・DocDD 更新対象）
- 証跡マッピング表
- サイズチェック
- 重要ポイント
- 実装タスク
- 検証定義（V1 + Issue 固有の V3 以降）
- TDD 判定
- Critical Path / Coverage expectation

> ⚠️ **Plan mode を使用している場合**: ExitPlanMode を呼ぶ前に必ず `gh issue edit` で Issue 本文を更新してください。Plan mode を抜けてから Issue 更新すると、会話内容が失われる場合があります。

## 標準フロー

### Worktree の要否（必ず言及すること）

計画完了時に worktree の要否を明示する。**原則 worktree 推奨**（Track 問わず）。

判定 SSOT: [.claude/skills/parallel-development/SKILL.md](../skills/parallel-development/SKILL.md) 「判定 SSOT — 原則 worktree 推奨」。Track A/B は `.env` 要否の分類にのみ使用し、worktree 要否とは独立。

| 状況 | 案内 |
|------|------|
| デフォルト（複数エディタ並走 / 他セッションと並列） | `/worktree <N>` を推奨 |
| 例外: 単独 sequential を明示（ユーザー自己申告） | main 直接作業も可（ただし worktree 推奨の旨は案内） |

例外の発動条件は SKILL.md「例外トリガー（ユーザー自己申告の substring 一致）」セクションを参照（SSOT）。`/plan` を呼んだ **直前のユーザー発話** に substring（「単独 sequential」「sequential mode」「worktree なし」等）が含まれない限り、常に worktree 推奨に倒す。

**出力例（デフォルト・次のステップ — `/plan` 完了時点）:**
```
/develop <N>
```

> worktree は `/plan` の前段（`/worktree <N>`）で作成済みのはず。`/plan` が main で実行された場合は、以降の `/develop` を worktree で実行するため先に `/worktree <N>` を案内する（`/plan` 自体の再実行は不要）。

---

## 手順（段階的に進める）

**重要: このコマンドの最終ゴールは「Issue本文の更新」です。**
**フロー**: Phase 0-3（調査・相談・リサーチ）→ Phase 4（Issue 更新）→ Phase 5（Codex 計画レビュー + Issue コメント記録）

### Phase 0: Issue ステータス確認

```bash
gh issue view $ARGUMENTS --json title,body,labels,state
```

- `[実装計画]` がタイトルに既に付いている場合は再計画として扱い、既存の計画と差分を取る
- ラベルに `status:todo` / `status:in-progress` のいずれかがあるか確認（なければ Phase 4 で `status:todo` を付与）

### Phase 1: 理解

1. `gh issue view $ARGUMENTS --comments` で Issue の内容と既存コメントを確認
2. **適用スキルを読み込む**（Issue の内容に応じて選択）:

   | Issue involves... | Applicable Skill | Path |
   |-------------------|------------------|------|
   | Backend API / FastAPI | backend-patterns | `.claude/skills/backend-patterns/SKILL.md` |
   | Frontend / Next.js / UI | frontend-patterns | `.claude/skills/frontend-patterns/SKILL.md` |
   | Test implementation | testing-patterns | `.claude/skills/testing-patterns/SKILL.md` |
   | DocDD documents / 7-axis | docdd-workflow | `.claude/skills/docdd-workflow/SKILL.md` |
   | UI design / デザイントークン | design | `.claude/skills/design/SKILL.md` |

3. **品質ルール** `.claude/rules/planning-quality.md` を参照
4. コードベースを調査し、影響範囲を特定
   - **変更起点ごとに依存先をトレースすること**（API → schema → repo → caller、UI → container → hook → API）
   - 同じドメインの既存 Issue を `gh issue list --label <label> --state open` で確認

### Phase 1.2: 依存先・呼び出し元トレース（必須）

影響範囲の特定後、**変更起点から下流まで閉じているか** を確認する。

- 変更起点ごとに、波及先（caller、UI、状態管理、テスト）を Issue 本文の表に列挙する
- 「直接実装しないが壊していないことを確認すべき箇所」も別表に明記する

### Phase 1.2.5: 証跡マッピング表 + UI State Matrix（必須）

Phase 1.2 の依存先トレースが完了した時点で、変更パスから必要な証跡を特定する。

1. `.claude/templates/issue-implementation-plan.md` の「🗺️ 証跡マッピング表」を全行コピーし、各行を ✅（該当）または —（非該当）で埋める
2. UI 変更がある場合は「🖥️ UI State Matrix」を埋める。UI 変更がなければ「UI 変更なし — 適用外」と記載
3. ブラウザ確認が必要な場合は、TC YAML の作成タスクを実装タスクに含めるか検討する（`docs/7-axis/7_TC/`）
4. DocDD 更新を伴う場合は、関連する `docs/7-axis/` のドキュメントパス（DM / API / UC / SR / TC）を実装タスクに列挙し、`make traceability` を検証定義 V2 に含める
5. テスト追加・契約変更がある場合は、変更レイヤーに応じた `make test-backend` / `make test-frontend` / `make test` を Critical Path テーブルの focused test commands に記入する

### Phase 1.3: Critical Path 判定（必須）

変更対象を以下の基準で評価する:

- **Critical**: 状態遷移・外部連携・callback・認証・申込導線を含む
- **Non-critical**: 上記に該当しない（UI 文言、CSS、DX ツーリング等）
- **Mixed**: Critical と Non-critical が混在
- **N/A**: `.claude/` / `docs/` のみの変更、文言修正のみ

判定結果に応じて Coverage expectation・focused test commands を Issue 本文の Critical Path テーブルに記入する。

### Phase 1.5: UI 設計の確認（UI 変更を伴う場合）

UI 変更を伴う Issue の場合は、計画前にデザインを検討:

- `.claude/skills/design/SKILL.md` を参照（Pencil.dev MCP 連携によるデザイントークン管理・コンポーネント設計）
- デザインが確定したら Issue にモックアップ URL や Pencil 画面 ID を添付
- コンポーネント分割を計画に含める

> **理由**: 設計を `/develop` に先送りすると、修正中の発見で計画変更が必要になり手戻りが発生する。`.claude/rules/project-workflow.md` の「Pencil 調整ルール」を参照。

### Phase 1.6: サイズチェック（必須）

影響範囲の特定後、`.claude/rules/issue-sizing.md` に照らしてサイズチェックを行う:

| 指標 | 上限 |
|------|:----:|
| 変更対象ファイル | 20 |
| 実装タスク数 | 8 |
| 起因 Issue / 負債 | 1 |
| Phase 数 | 1 |
| API/型の契約変更点 | 3 |
| 下流呼び出し元数 | 5 |

**2 つ以上 ❌ の場合**: 分割案をユーザーに提示してから計画を進める。
分割の方針: ドメイン概念ごとの縦スライスを優先。

### Phase 2: ユーザーと相談（必須）

**計画を確定する前に、必ずユーザーと方向性を相談してください。**

相談すべき内容:
- 実装アプローチの選択肢（複数ある場合）
- 技術的なトレードオフ
- 優先順位の確認
- 不明点の確認
- 後続 Issue の見通し（Backend → Frontend → DocDD 等、複数段階になる場合）

```
例: 「Issue #XX について調査しました。
実装方針として A と B の選択肢があります。
A: [メリット/デメリット]
B: [メリット/デメリット]
どちらで進めますか？」
```

### Phase 3: リサーチ（必要時）

- 公式ドキュメントやベストプラクティスをリサーチ
- **参照した外部リンクは必ず記録**（後で Issue 本文に追記）
- アーキテクチャ決定がある場合は ADR セクションを準備
- 新機能の場合は DocDD 7 軸トレーサビリティ文書計画を準備

**エージェントチーム活用**（複雑な Issue の場合）:
- 複数ドメインにまたがる場合は、並列リサーチエージェントで調査を効率化
- 技術選定では、複数候補を並列で調査し比較検討
- 詳細は `.claude/rules/agent-teams.md` のパターン 1（並列リサーチ）・パターン 10（Issue 分析・計画）を参照

### Phase 4: Issue 更新（必須）

#### Step 1: テンプレートの heading 順序・必須項目を遵守する

1. **テンプレ本文を読み込む**: `.claude/templates/issue-implementation-plan.md` を Read し、コードフェンス（` ```markdown ` 〜 ` ``` `）内の `## ` heading 順序を取得する
2. **heading を Issue 本文へ literal に反映する**: フェンス内の `## ` 〜 `### ` heading 列を、その**順序のまま** Issue 本文の追記セクションへコピーする（heading 名は変更禁止）
3. **必須項目を埋める**: 各 heading 配下のプレースホルダ（`[...]` / `?` / `✅/—` 等）を Issue 固有の値で置換する
4. **HTML コメントは Issue 本文に出さない**: テンプレ内の `<!-- ... -->` ガイダンスはプランナーの判断材料。Issue 本文には出力しない
5. **元 Issue 本文（背景・目的・スコープ・受け入れ条件）は保全**する。書き換え禁止

#### Step 2: 条件付き表示ロジック（必須）

テンプレを反映する際、以下の 3 ロジックで該当セクションを出し分ける:

1. **TDD 判定 row の出し分け**:
   - **TDD 必須** の場合: 「想定 RED コマンド」「想定 GREEN コマンド」に focused pytest / vitest コマンドを**具体値**で記入
   - **TDD スキップ** の場合: 同じ row に「該当なし」と記入し、判定欄に `スキップ（理由: <one-liner>）` と記入
   - **空欄禁止**: 必須 / スキップどちらかを必ず記入する。空欄 = 証跡漏れとして扱う

2. **サイズチェック超過時の分割提案**:
   - 上限を 2 つ以上超過した場合、サイズチェック表の直後に `## 🪓 分割提案` セクションを追加し、子 Issue 候補を列挙する（縦スライス優先）
   - 上限内の場合は分割提案セクションを出さない
   - 判定 SSOT: [`.claude/rules/issue-sizing.md`](../rules/issue-sizing.md)

3. **forward reference の末尾隔離**:
   - 本 Issue が **未存在 path** を参照する場合（例: `tdd-gate.md`、`scripts/claude/verify-issue.sh` 等）、Issue 本文の末尾に `## 📋 後続 Issue で導入予定（forward reference の隔離）` セクションを追加し、`---` 区切りで隔離する
   - 既存 path への参照は本セクションに含めない
   - 参照先が無い場合は本セクションを出さない

#### Step 3: dogfooding ガード（上書き安全性）

`gh issue edit --body-file` で Issue 本文を更新する**直前**に、**最新 body を再取得**して上書きリスクを排除する:

```bash
# 1. 最新 body と更新時刻を取得
gh issue view $ARGUMENTS --json body,updatedAt > /tmp/issue_${ARGUMENTS}_remote.json

# 2. ローカル作成本文との差分を目視確認
#    - 他セッションの追記 / レビューコメント反映が無いか確認
#    - updatedAt がローカル取得時刻より新しい場合は競合の可能性
diff <(jq -r '.body' /tmp/issue_${ARGUMENTS}_remote.json) /tmp/issue_${ARGUMENTS}.md

# 3. 差分が想定内であることを確認してから edit
gh issue edit $ARGUMENTS --body-file /tmp/issue_${ARGUMENTS}.md
```

**競合検出時の対応**: 他セッションの追記が見つかった場合は、ローカル本文に統合してから再度 dogfooding ガード手順を実行する。サイレントに上書きしない。

#### Step 4: タイトル・ラベル付与

1. **`gh issue edit --title` でタイトルに `[実装計画]` を追加**
2. **ラベル付与**（最低 2 つ。canonical 優先 — `.github/labels.json` 参照）:
   - 優先度: `P0` / `P1` / `P2`（legacy alias: `High` / `Medium` / `Low`）
   - 領域: `BE` / `FE` / `infra` / `docs` / `tests` / `bug` / `chore`（legacy alias: `バックエンド` / `フロントエンド` / `インフラ` / `ドキュメント` / `テスト` / `バグ`）
   - ステータス: `status:todo` または `status:in-progress`

#### 長い計画の場合（一時ファイル経由）

```bash
# 1. 一時ファイルに書き出し（Step 1〜2 を反映）
cat > /tmp/issue_$ARGUMENTS.md << 'EOF'
[既存の内容 + 計画]
EOF

# 2. dogfooding ガード（Step 3）
gh issue view $ARGUMENTS --json body,updatedAt > /tmp/issue_${ARGUMENTS}_remote.json
diff <(jq -r '.body' /tmp/issue_${ARGUMENTS}_remote.json) /tmp/issue_$ARGUMENTS.md

# 3. Issue 更新
gh issue edit $ARGUMENTS --body-file /tmp/issue_$ARGUMENTS.md
```

### Phase 5: Codex 計画レビュー

Issue 本文更新後、Codex CLI で計画テキストをレビューする。
ルール参照: `.claude/rules/codex-review.md`

> ⚠️ **`/plan` と `/verify` では Codex への渡し方が異なる**
> - `/plan`: **計画テキスト**のレビュー（Issue 本文）→ `--base main` は使わない
> - `/verify`: **コード差分**のレビュー → `--base main` を使う
>
> `/plan` で `codex review --base main` を実行すると、ワーキングツリーの差分がレビューされ、当該 Issue の計画が検証されない。

#### Codex 利用可否を判定

```bash
codex --version > /dev/null 2>&1
```

#### Codex が利用可能な場合

1. 計画テキストを一時ファイルに書き出し:
   ```bash
   gh issue view $ARGUMENTS --json body -q '.body' > /tmp/issue_$ARGUMENTS.md
   ```

2. プロンプトテンプレートと結合して Codex に投入:
   ```bash
   cat .claude/templates/codex-plan-review-prompt.md /tmp/issue_$ARGUMENTS.md > /tmp/codex_prompt_$ARGUMENTS.md
   codex exec "$(cat /tmp/codex_prompt_$ARGUMENTS.md)"
   ```

   > **注意**: Codex の応答には 3〜5 分かかる場合がある。30 秒で応答なしと判定しないこと。

3. 結果を Issue コメントに記録:
   ```bash
   gh issue comment $ARGUMENTS --body "## 計画レビュー結果（/plan Phase 5 — Codex CLI）

   <レビュー結果をここに記載>

   ---
   *Codex CLI review: $(date +%Y-%m-%d)*"
   ```

4. **指摘の分類と対応** （`.claude/rules/codex-review.md` 参照）:
   - 🔴 必須: 計画に影響する見落とし・不整合 → 計画を修正して Issue 本文を再更新
   - 🟡 推奨: 計画の改善提案 → 実装タスクに追加 or 注意事項として記載
   - 🟢 参考: 記録のみ
   - ❌ 却下: 理由を付けて却下

#### Codex が利用不可の場合（Fallback）

**サイレントスキップ禁止** — 必ずユーザーに通知する。

1. `.claude/templates/codex-review-handoff.md` の「計画レビュー」セクションを出力
2. ユーザーに手動で Codex / ChatGPT にレビューを依頼するよう案内

```
⚠️ Codex CLI が未導入のため、計画レビューを自動実行できません。
以下の handoff テンプレートを使って手動レビューを実施してください。
```

> **後続 Issue で Codex + Claude SA × 2 の 3 reviewer 並列レビュー（multi-model-review）を導入予定**。本コマンドでは Codex 単独レビューに留める。

---

## 参照テンプレートとリファレンス

- Issue 本文テンプレート: `.claude/templates/issue-implementation-plan.md`
- Codex レビュープロンプト: `.claude/templates/codex-plan-review-prompt.md`
- Codex レビュー引き継ぎテンプレート: `.claude/templates/codex-review-handoff.md`（Codex CLI 未導入時のフォールバック）
- Codex CLI レビュー運用ルール: `.claude/rules/codex-review.md`
- 計画品質ルール: `.claude/rules/planning-quality.md`
- サイジングルール: `.claude/rules/issue-sizing.md`
- Pencil 調整ルール: `.claude/rules/project-workflow.md`
- 並列開発判定 SSOT: `.claude/skills/parallel-development/SKILL.md`

---

## 注意事項

- **一気に進めず、Phase 2 でユーザーと相談すること**
- **Phase 5 で Codex 計画レビューを必ず実施する**（`.claude/rules/codex-review.md` 参照）
- コメントではなく **Issue 本文を編集** して計画を追記
- 元の Issue 内容は残す
- スキルファイルのパターン・制約に従う

---

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

---

## 📋 後続 Issue で導入予定（forward reference の隔離）

| 参照先（未存在） | 用途 | 予定 Issue |
|--------------|------|----------|
| `.claude/rules/multi-model-review.md` | Codex + Claude SA × 2 の 3 reviewer 並列レビュー | 後続 Issue（D-1 想定） |
| `.claude/skills/test-design/SKILL.md` | Critical Path 判定スキル化 | 後続 Issue（4-2 想定） |
| `.claude/rules/tdd-gate.md` | TDD 判定の SSOT | 後続 Issue（4-2 想定） |
| `.claude/references/applicable-skills.md` | 適用スキル一覧の SSOT | 後続 Issue（4-1 想定） |
| `.claude/skills/planning-quality/SKILL.md` | `rules/planning-quality.md` の skill 化 | 後続 Issue（4-1 想定） |

Remember to use the GitHub CLI (`gh`) for all GitHub-related tasks.
