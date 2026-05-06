---
description: GitHub Issue の実装を行います。
argument-hint: "<issue-number>"
disable-model-invocation: true
---
GitHub Issue $ARGUMENTS の実装を行ってください。

**CLAUDE.md の開発フローに従って進めてください。**

---

## 手順

### Phase 1: 準備

1. `gh issue view $ARGUMENTS --comments` で Issue の内容を確認
   - `[実装計画]` がタイトルにあれば、計画に従って実装
   - なければ先に `/plan $ARGUMENTS` で計画を立てる

2. **Issue を「進行中」に設定**:
   ```bash
   gh issue edit $ARGUMENTS --remove-label "status:todo" --add-label "status:in-progress" 2>/dev/null || true
   ```

3. **適用スキルを読み込む**（Issue の内容に応じて選択）:

   | Issue involves... | Applicable Skill | Path |
   |-------------------|------------------|------|
   | Backend API / FastAPI | backend-patterns | `.claude/skills/backend-patterns/SKILL.md` |
   | Frontend / Next.js / UI | frontend-patterns | `.claude/skills/frontend-patterns/SKILL.md` |
   | Test implementation | testing-patterns | `.claude/skills/testing-patterns/SKILL.md` |
   | DocDD documents / 7-axis | docdd-workflow | `.claude/skills/docdd-workflow/SKILL.md` |

4. **TDD 証跡を確認する**（`/plan` 検証定義の「TDD 判定」欄）:
   - `TDD 必須` → RED テストを先行作成して FAILED 結果を確認してから実装へ
   - `TDD スキップ（理由あり）` → スキップ理由をサマリに転記して実装へ
   - 空欄 → **証跡漏れ** として判断を明示してから実装へ

> 後続 Issue で TDD 専用コマンド `/tdd` および `.claude/rules/tdd-gate.md` を導入予定。本コマンドでは TDD 必須判定の場合も `/develop` 内で RED → GREEN を進める。

### Phase 2: 実装

1. コードベースを調査し、関連ファイルを特定
2. 計画に基づいて実装を進める（TDD 対象は RED 確認済みの前提）
3. GREEN にする最小実装を書く

> **Note**: UI 設計（Pencil）の確認は `/plan` Phase 1.5 で完結済みの想定。`/develop` では計画で確認済みのデザインを正として進める（`.claude/rules/project-workflow.md` 参照）。

> **バグ修正時**: 原因調査に行き詰まったら、変更対象を最小化し、再現テストを書いてから修正する。

#### チーム活用（2 レイヤー以上の変更時）

変更対象が 2 レイヤー以上にまたがり、かつファイル競合が少ない場合はエージェントチームを組成する。単一レイヤーの変更では従来通り単一セッションで実装する。

| 条件 | モード |
|------|--------|
| 単一レイヤーの変更 | 単一セッション（従来通り） |
| 2 レイヤー以上 + ファイル競合なし | エージェントチーム |

詳細: `.claude/rules/agent-teams.md`

チーム構成例:
```
Issue #XXX をチームで実装して。
- Backend担当: API + サービス層（apps/backend/app/modules/<module>/）
- Frontend担当: 画面（apps/frontend/app/<segment>/）
- テスト担当: 統合テスト + DocDD 更新
```

### Phase 2.5: DocDD 更新（実装と同じ Issue 内で）

実装が完了したレイヤーに応じて、関連する DocDD ドキュメントを更新する。
**後回し禁止** — 実装の記憶が新しいうちに書く。

| 実装内容 | 更新対象 |
|---------|---------|
| DB モデル追加/変更 | `docs/7-axis/3_DM/DM-*.md` |
| API エンドポイント追加 | `docs/7-axis/6_API/<domain>/*.yaml` |
| UI 画面追加/変更 | `docs/7-axis/2_UC/` / `docs/7-axis/4_SR/`（該当あれば） |
| テスト追加 | `docs/7-axis/7_TC/TC-*.yaml` + `docs/testing/traceability/<domain>_map.json` |

**判断基準:**
- 新規モデル / エンドポイント → **必ず更新**
- 既存の軽微な修正（バグ修正等） → 更新不要
- サイズ上限（20 ファイル）を超えそうな場合 → DocDD を別 Issue に分割

詳細: `.claude/rules/project-workflow.md` の「DocDD 更新ルール」

### Phase 3: 品質チェック（変更箇所に応じて実行）

実装完了後、**変更した箇所に応じて** 品質チェックを実行する。

#### 変更レイヤーごとの必須チェック

| 変更レイヤー | コマンド |
|------------|---------|
| Backend のみ | `make test-backend` |
| Frontend のみ | `make test-frontend` |
| Backend + Frontend | `make test`（両方を実行） |
| `.claude/commands/`, `.claude/templates/`, `.claude/skills/`, `.claude/rules/`, `.claude/references/` | `make validate-claude` |
| `docs/7-axis/`, `docs/testing/traceability/` | `make traceability` |
| API 契約変更（request / response / status code） | OpenAPI yaml 更新確認 + caller 全件確認 + request/response 整合性 |
| 状態管理変更（Zustand / URL param / form restore） | 保存・復元・戻る導線・次画面の確認 |
| 画面遷移変更 | 対象導線を入口から完了まで確認 |

#### 実行ルール

- **Backend を触ったら** `make test-backend` だけで終わらせず、変更したモジュールに紐づく focused pytest（`pytest apps/backend/tests/.../test_xxx.py::test_name`）も実行する
- **API 契約を変えたら**、client / hook / container / 次画面 / callback handler まで追って確認する
- **DocDD を更新したら** `make traceability` を実行する
- **`.claude/` の dx-docs を変更したら** `make validate-claude` を実行する
- ブラウザ結合確認は `/verify` で軽量ヘルスチェック（Console / Network エラーチェック）として実施する

#### 失敗扱いにするもの

- `0 selected`
- `all skipped`
- `script not found`
- `make test-backend` / `make test-frontend` / `make test` / `make validate-claude` / `make traceability` が FAIL
- 実行コマンド未記録

### Phase 4: 高リスク変更の確認（該当時のみ）

**原則**: ブラウザ結合確認・統合的な動作確認は `/verify` の軽量ヘルスチェックで実施する。
`/develop` では **高リスク変更のみ** 追加の事前確認（pre-merge stg 実確認等）を行う。

#### 高リスク変更の定義

以下に該当する導線は、PR マージ前に追加の事前確認を行う:

| 対象 | 例 | 根拠 |
|------|-----|------|
| 決済 | 課金処理、金額計算、外部決済連携 | 二重課金・決済失敗の顧客影響が大きい |
| 認証 | ログイン、トークン管理、招待トークン、パスワードリセット | ロックアウト・不正アクセスの顧客影響が大きい |
| 外部連携 | 外部 API への送受信、Webhook、コールバック | ローカルでは疎通不可。STG 実確認が必要 |
| マイグレーション | DB スキーマ変更、データ移行 | 後方互換性の破綻・データ損失リスク |
| 状態遷移 | 申込・解約・契約変更等の主要導線 | 不整合状態の発生リスク |
| IP 制限 / Secrets 依存 | ホワイトリスト、Secrets Manager 依存画面 | ローカルでは再現不可能 |

#### 実施手順（high-risk のみ）

1. **検証に必要なコード差分を main に持っていく**（worktree から差分を確認、必要なら main checkout で再現）
2. **ステージング環境を検証可能な状態にする**:
   - Backend 変更あり: `make deploy-stg` でステージングへデプロイ
   - マイグレーションあり: ステージング DB へ migration を適用
   - Frontend 変更あり: `make deploy-stg` でステージングへデプロイ
3. **ステージングで主要導線を最後まで確認する**:
   - 正常系の入口 → 完了
   - 主要な異常系（外部 API エラー、認証失敗、入力不正）
4. **証跡を残す**（実行コマンド + 結果 + スクリーンショット）。後続の `/verify` Step 5 で参照する

#### FAIL 時の復旧フロー

1. **worktree に戻って修正する**: `cd .claude/worktrees/issue-<N>` → 原因を特定して修正
2. **ステージングを再デプロイ**: 上記 Step 2-3 を再実行
3. **再確認**: 上記 Step 3-4 を再実行
4. **復旧サイクル上限**: Step 1〜3 の再試行は **最大 3 回** まで。3 回再試行しても解消しない場合はユーザーに判断を仰ぐ（根本原因の再調査 / Issue 分割 / 一旦マージ見送り等）

#### デフォルト経路（高リスク変更に該当しない場合）

- `/verify` Step 4 のブラウザヘルスチェック（Console / Network / 主要導線手動確認）に委譲する
- 実装サマリーのブラウザ確認欄は `Deferred to /verify` と記録する

> **例外を増やさない原則**: 上記以外の「ステージングでないと確認できない」は `/verify` で十分。迷ったらデフォルト経路（`Deferred to /verify`）を選ぶ。

### Phase 5: 実装サマリー（`/verify` への引き継ぎ）

Phase 3 / 4 完了後、**実装内容を `gh issue comment $ARGUMENTS` で Issue コメントとして投稿**する。
`/verify` で事実確認を行う際の基準資料となる。

- 構成は `.claude/templates/implementation-summary-comment.md` に従う（**見出し・TDD 判定行・Coverage 結果行の記法を厳守**）
  - 見出し: `## 実装サマリー（/develop 完了時点）` をそのまま使う
  - TDD 判定行: スキップ時は `スキップ（理由: ...）` と同一セル内に書く
  - Coverage 結果行: `PASS` / `N/A` / `未解消` のみ（装飾なし）
- `ブラウザ確認` は `Deferred to /verify` / `PASS`（高リスク変更の事前確認済み）/ `N/A` のいずれかで必ず埋める
- **`TDD 証跡` を必ず埋める**（必須 / スキップ（理由）のどちらかで空欄禁止）
- **`Coverage 証跡` を必ず埋める**（`/plan` の Critical Path テーブルから転記 + focused test の実行結果を記録）
- `未解消` が残る場合は理由と扱いを明記する

#### 計画との差分があれば Issue 本文を更新

実装中に当初計画と異なる選択をした場合、追加の決定事項が出た場合、予期しない問題が発生した場合は Issue 本文も更新する:

```bash
gh issue edit $ARGUMENTS --body-file /tmp/issue_$ARGUMENTS.md
```

または `/update-issue` を使用する。

---

## チェックリスト

品質チェック通過後に確認:

- [ ] 変更レイヤーに対応する `make test-backend` / `make test-frontend` / `make test` のいずれかが PASS している
- [ ] `.claude/` の dx-docs を変更した場合は `make validate-claude` が PASS している
- [ ] DocDD を更新した場合は `make traceability` が PASS している
- [ ] `0 selected` / `all skipped` / `script not found` を成功扱いにしていない
- [ ] **TDD 対象の場合: RED コマンドの FAILED 結果と GREEN コマンドの PASSED 結果が記録されている**
- [ ] **TDD スキップの場合: スキップ理由が明記されている（空欄 = 証跡漏れ）**
- [ ] API 契約変更時は caller と次画面まで確認した
- [ ] 高リスク変更（決済 / 認証 / マイグレーション / 外部連携）がある場合は Phase 4 の事前確認を済ませた
- [ ] Phase 5 の実装サマリーを Issue コメントに投稿した
- [ ] 計画との差分があれば Issue 本文を更新した

---

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

> **新しいセッションで `/verify` を実行する理由**: 実装者の文脈（編集したファイル・意図）が残ったまま検証すると見落としが増える。新セッションで `/verify` を起動することで、フレッシュな目で事実確認できる。

---

## 注意事項

- 計画（`[実装計画]`）がなければ先に `/plan` を実行
- 品質チェックは変更箇所に応じて実行する（全レイヤー網羅でなくて OK）
- ブラウザ結合確認は原則 `/verify` に委譲する。高リスク変更（決済 / 認証 / マイグレーション / 外部連携）のみ `/develop` 内で事前確認する
- 大きな変更があれば Issue 本文を更新する

---

## 📋 後続 Issue で導入予定（forward reference の隔離）

| 参照先（未存在） | 用途 | 予定 Issue |
|--------------|------|----------|
| `/tdd` コマンド | TDD 専用コマンド（RED テスト先行作成） | 後続 Issue（4-2 想定） |
| `.claude/rules/tdd-gate.md` | TDD 判定の SSOT | 後続 Issue（4-2 想定） |
| `.claude/skills/tdd-workflow/SKILL.md` | TDD 実行スキル | 後続 Issue（4-2 想定） |
| `.claude/skills/systematic-debugging/SKILL.md` | バグ修正の体系化スキル | 後続 Issue（4-3 想定） |
| `.claude/skills/verification-before-completion/SKILL.md` | 完了主張前のゲート | 後続 Issue（4-2 想定） |
| `make quality-gate` ターゲット | 品質ゲート一括実行 | 後続 Issue（5-1 想定） |
| `/screen-verify` + TC YAML 自動実行 | post-merge ステージング検証 | 後続 Issue（D-X 想定） |

Remember to use the GitHub CLI (`gh`) for all GitHub-related tasks.
