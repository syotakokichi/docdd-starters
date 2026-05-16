# 実装検証結果コメントテンプレート

`/verify` の結果を Issue コメントに残すテンプレート。`/develop` の実装サマリーと併せて、PR 作成前の最終ゲートとなる。

Wave 5-2（`make verify-issue`）が産出する構造化 JSON（schema SSOT: [`.claude/templates/verify-issue-result.json`](./verify-issue-result.json)）を `/verify` Step 6 が `jq` で本テンプレートに転記する。**Issue コメントだけで検証履歴が再現できる** SSOT を成立させるのが目的（Phase 5 のゴール）。

> **記法ルール**: 後続で evidence-checker（自動証跡検証）を導入する際の互換性を保つため、以下の記法を厳守する:
> - **見出し**: `## 実装検証結果（/verify）` をそのまま使う（`/develop` 側の `完了時点` suffix を引きずらない）
> - **機械セクションは「上に積む」だけ**: `### 機械検証サマリー（make verify-issue）` を `## 実装検証結果（/verify）` 直下に追加する。既存の `### Status` 以降の見出し・記法は一切変更しない（evidence-checker が parse 前提）
> - **TDD 判定行**: スキップ時は `スキップ（理由: ...）` と **同一セル内** に理由を書く
> - **結果値**: `PASS` / `N/A` / `未解消` のみ（`✅ PASS` / `PASS（31/31）` / `PASS — 詳細` 等の装飾は付けない）
> - **ブラウザ確認**: `PASS` / `Deferred` / `N/A` / `未解消` のみ
> - **機械検証サマリーの値は JSON からの転記のみ**（手で書き換えない）。step `status` は `pass` / `fail` / `skip`、`skip_reason` は `manual_required` 等を JSON のまま転記する

```markdown
## 実装検証結果（/verify）

### 機械検証サマリー（make verify-issue）

> このセクションは `make verify-issue ISSUE=<N>` が出力した構造化 JSON
> （`VERIFY_ISSUE_OUTPUT` で pin した本実行専用ファイル）の転記のみで構成する。
> 手書きの判断は `### Status` 以降に書く。

#### 実行アイデンティティ（inputs）
| JSON フィールド | 値 | 備考 |
|----------------|-----|------|
| `inputs.requested_issue` | [N] | `/verify <N>` の N と一致すること（不一致なら stale read） |
| `inputs.resolved_pr` | [PR番号 / null] | null = PR 未作成（merge-base fallback） |
| `inputs.issue_pr_match` | [true / false] | PR 本文/タイトルが #N を参照するか |
| `inputs.source` | [pr-diff / merge-base-fallback / null] | 変更パスの取得経路 |
| `inputs.run_id` | [run_id] | 本実行の一意 ID（mtime と併せ新鮮性確認） |
| `inputs.output_path` | [絶対パス] | pin した出力ファイル |
| `inputs.started_at` / `finished_at` | [ISO8601] | 実行時刻 |

#### 検出カテゴリ / ステップ結果（steps[]）
| step `name` | `categories` | `command` | `status` | `exit_code` | `skip_reason` | `partial` | `notes` |
|------|------|------|------|------|------|------|------|
| [test-backend 等] | [backend-unit 等] | [make ... / null] | pass / fail / skip | [0/1/null] | [null / manual_required] | [true/false] | [up/down not validated 等] |

> step が `*-manual`（`command` = null / `status` = skip / `skip_reason` = manual_required）の行は
> **自動 target が PASS でも未消化**。下の「人手証跡サーフェス」で必ず扱う。

#### サマリー（summary）
| 指標 | 値 |
|------|-----|
| `pass_count` | [N] |
| `fail_count` | [N] |
| `skip_count` | [N] |
| `manual_required_count` | [N]（>0 なら exit 0 でも人手証跡が未消化） |
| `partial_count` | [N]（migration-safety の up/down 未検証等） |
| `total_count` | [N] |

#### exit_code と rc×JSON 取扱
| `exit_code` | 意味 | JSON | 本テンプレートでの扱い |
|:----:|------|:----:|------|
| 0 | 全 PASS | あり | 転記して PASS。ただし `manual_required_count > 0` なら下記サーフェスで `未解消` 扱い |
| 1 | step FAIL あり | **あり** | **JSON を読んで FAIL を転記**（FAIL こそ残す）。Status は「ブロッカーあり」 |
| 2 | 引数不正 | **なし** | JSON 不在転記規約（下記）。`/verify` は hard fail |
| 3 | 前提失敗（jq 不在 / gh / detector / output 書込失敗） | **なし** | JSON 不在転記規約（下記）。`/verify` は hard fail |

#### 人手証跡サーフェス（manual_required_count > 0 の場合）
- `skip_reason == manual_required` の step（`<category>-manual`）を列挙する:
  - [api-route-manual / frontend-ui-manual / dx-docs-manual 等を列挙]
- これらは自動 target 通過で**解消されない**（additive セマンティクス）。
  `/verify` Step 4 で人手確認し、未確認なら本コメントの該当証跡欄を `未解消` とする。
- `exit_code == 0` でも未消化人手証跡があれば Status を `継続` 以上にする。

#### 未コミット blind-spot 警告（案1 commit-before-gate 契約）
| 項目 | 値 |
|------|-----|
| 機械ゲート実行時の working-tree 差分（`git diff HEAD --name-only`） | [空 / 非空（ファイル列挙）] |
| 機械ゲート実行時の untracked（`git ls-files --others --exclude-standard`） | [空 / 非空（ファイル列挙）] |
| blind-spot 警告 | なし（gate 前に commit 済み）/ ⚠️ 非空のまま gate を実行（機械検出は `merge-base..HEAD` / `gh pr diff` ＝**コミット済み差分のみ**。未コミット分は機械検出外。Step 4 人手確認で補完したか明記） |

> **契約**: `make verify-issue` の機械検出は **コミット済み差分のみ**
> （`verify-issue-detect.sh:21-22` `--git` は `merge-base..HEAD` / PR 作成後は `gh pr diff`）。
> `/verify` は機械ゲートを**コミット済み状態に対して**実行する。Step 1 で working-tree/untracked が
> 非空なら、機械ゲート前にブランチ内 commit（`/pr` 前なので可逆・benign）を促す。

#### error / warnings
| 項目 | 値 |
|------|-----|
| `error.code` | [null / jq_not_found / gh_pr_lookup_failed / pr_issue_mismatch / detector_failed / unknown_category] |
| `error.message` | [null / メッセージ] |
| `error.detector_stderr` | [null / detector の stderr] |
| `warnings[]` | [空 / pr_issue_mismatch 等] |

#### JSON 不在転記規約（exit_code 2 / 3 — JSON が書かれないケース）
JSON が pin した出力ファイルに存在しない場合（rc=2 引数不正 / rc=3 前提失敗。
`finish` 前の `exit 2/3` 経路）は、JSON を読めないため以下を**手動で**転記し、
`/verify` を **hard fail**（PASS 扱いにしない）とする:

| 項目 | 内容 |
|------|------|
| 機械ゲート結果 | 未取得（JSON 不在 / rc=[2 or 3]） |
| stderr メッセージ | `make verify-issue` の標準エラー出力を貼る（`ERROR: ...`） |
| rc | [2 = 引数不正 / 3 = 前提失敗] |
| 扱い | hard fail。原因（jq 不在 / gh 認証 / detector / 引数）を解消して再実行 |

### Status
- [完了 / 継続 / ブロッカーあり] — 1 行で記載
- 次アクション: `/pr`（PR 作成）/ `/review <N>` / ユーザー判断待ち（理由）など

### 実行コンテキスト
- セッション: [/develop と同一 / 別セッション]
- 実行場所: [main / worktree]
- worktree path: [.claude/worktrees/issue-<number>]（worktree の場合）
- branch: [branch-name]

### 検証サマリー
- **Codex レビュー指摘件数**: 🔴 必須 X 件 / 🟡 推奨 Y 件 / 🟢 参考 Z 件 / ❌ 却下 W 件
- **🔴 / 🟡 未解消**: [件数と要点。未解消なら本セッション内での対応方針を 1 行] / なし
- **本セッション内で適用した修正**: [件数と主な変更。適用なしなら「なし」]

### 品質チェック結果
> 値は上の「検出カテゴリ / ステップ結果」（JSON `steps[]`）から転記する。
> 検出されず実行対象外なら `N/A`。
| 種別 | コマンド | 結果 |
|------|---------|------|
| バックエンド | `make test-backend` | PASS / FAIL（理由）/ N/A |
| フロントエンド | `make test-frontend` | PASS / FAIL（理由）/ N/A |
| 全体 | `make test` | PASS / FAIL（理由）/ N/A |
| frontmatter | `make validate-claude` | PASS / FAIL（理由）/ N/A |
| traceability | `make traceability` | PASS / FAIL（理由）/ N/A |

### ブラウザ確認（軽量ヘルスチェック）
| 項目 | 結果 | 備考 |
|------|------|------|
| 主要導線の手動確認 | PASS / Deferred / N/A / 未解消 | [入口 → 完了までの導線を確認したか] |
| Console error | PASS / Deferred / N/A / 未解消 | [新たな error / warn の有無] |
| Network 4xx/5xx | PASS / Deferred / N/A / 未解消 | [意図しないエラーの有無] |

> **運用の基本**: `/verify` ではランタイム異常のヘルスチェックのみを行う。深い目視確認・スクリーンショット比較は別途実施する。
> **N/A にしていいのは**: API / バックグラウンド処理 / 設定ファイルのみの変更でブラウザ導線が存在しない場合のみ。

### TDD 証跡
| 項目 | 内容 |
|------|------|
| TDD 判定 | 必須 / スキップ（理由: ）|
| 追加したテスト | `/develop の TDD 証跡から転記` |
| RED コマンド | `/develop の TDD 証跡から転記` |
| RED 結果 | `/develop の TDD 証跡から転記`（例: FAILED: 1 failed）|
| GREEN コマンド | `/develop の TDD 証跡から転記` |
| GREEN 結果 | `/develop の TDD 証跡から転記`（例: PASSED: 1 passed）|
| /verify での再確認 | PASS / N/A（スキップの場合）/ 未解消 |

### Coverage 証跡
| 項目 | 内容 |
|------|------|
| Critical Path 判定 | /develop の Coverage 証跡から転記 |
| 保護レイヤー | /develop の Coverage 証跡から転記 |
| Coverage expectation | /develop の Coverage 証跡から転記 |
| Focused test commands | /develop の Coverage 証跡から転記 |
| 結果 | PASS / N/A / 未解消 |

### DocDD / TC / Traceability
- `make traceability`: [PASS / FAIL（理由）/ N/A（DocDD 変更なし）]
- 更新した DocDD / TC / traceability map: [ファイル名のリスト。更新なしなら「なし」]

### Codex レビュー監査証跡（サマリのみ）
| 項目 | 内容 |
|------|------|
| Codex 実行コマンド | `codex review --base main` / 実行省略（理由） |
| exit status | [0 / エラー内容 / 未実行] |
| 所要時間 | [秒。未実行なら N/A] |
| 指摘の対応サマリ | 🔴 必須 → [対応内容] / 🟡 推奨 → [採否と理由] |
| Step 5 後の差分変化 | なし / あり → 機械ゲート再実行済（新 run_id: [...]） |

### 未解消 / 先送り
[未対応の指摘・テスト失敗・実装漏れ・未消化の人手証跡（manual_required）があれば明記。なければ「なし」]
```

---

## 📋 後続 Issue で導入予定（forward reference の隔離）

> 本 Issue（Phase 5 / Wave 5-3）では作らない。Epic #23 後続 Wave で管理する（「後続なし」= 本 Issue 完結の意。下記は Epic 管理下の forward reference）。

| 参照先（未存在） | 用途 | 予定 Issue |
|--------------|------|----------|
| evidence-checker（`scripts/claude/verify_issue_evidence.py` 相当）+ `evidence-manifest.yaml` 相当 | 本コメント記法の自動検証（本テンプレートの記法を parse 前提に保つことが本 Issue の要件） | Epic #23 後続（D-1 想定） |
| `.claude/rules/multi-model-review.md` | Codex + Claude SA × 2 の 3 reviewer 並列レビュー | Epic #23 後続（D-1 想定）|
| ephemeral session memory writer | raw 3-reviewer 出力の退避 | Epic #23 後続（D-X 想定）|
| `/screen-verify` + TC YAML 自動実行 | post-merge STG ブラウザ検証 | Epic #23 後続（D-X 想定）|
