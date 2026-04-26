# 実装サマリーコメントテンプレート

`/develop` 完了時点で Issue コメントに残すテンプレート。`/verify` の証跡確認の基準資料となる。

> **記法ルール**: 後続で evidence-checker（自動証跡検証）を導入する際の互換性を保つため、以下の記法を厳守する:
> - **見出し**: `## 実装サマリー（/develop 完了時点）` をそのまま使う（`/verify` のサマリーと混同しない）
> - **TDD 判定行**: スキップ時は `スキップ（理由: ...）` と **同一セル内** に理由を書く
> - **結果値**: `PASS` / `N/A` / `未解消` のみ（`✅ PASS` / `PASS（31/31）` / `PASS — 詳細` 等の装飾は付けない）
> - **ブラウザ確認**: `PASS` / `Deferred to /verify` / `N/A` / `未解消` のみ

```markdown
## 実装サマリー（/develop 完了時点）

### Status
- [完了 / 継続 / ブロッカーあり] — 1 行で記載
- 次アクション: `/verify <N>` / ユーザー判断待ち（理由）など

### 計画からの差分
- **追加 X / 変更 Y / 削除 Z**
- 主要な変更点 3 行以内:
  - [最も重要な変更 1]
  - [最も重要な変更 2]
  - [最も重要な変更 3]
- **変更理由**: [なぜ計画と変えたか — 計画通りなら「計画通り」]

### 実装したファイル
[主要なファイルのみリストアップ。詳細は `git diff` で確認]
- `path/to/file1.py`: [何をしたか 1 行]
- `path/to/file2.tsx`: [何をしたか 1 行]

### 品質チェック結果
| 種別 | コマンド | 結果 |
|------|---------|------|
| バックエンド | `make test-backend` | PASS / FAIL（理由）/ N/A |
| フロントエンド | `make test-frontend` | PASS / FAIL（理由）/ N/A |
| 全体 | `make test` | PASS / FAIL（理由）/ N/A |
| frontmatter | `make validate-claude` | PASS / FAIL（理由）/ N/A |
| traceability | `make traceability` | PASS / FAIL（理由）/ N/A |

> 変更レイヤーに該当するもののみ実行。N/A は「変更なし」を意味する。

### TDD 証跡
| 項目 | 内容 |
|------|------|
| TDD 判定 | 必須 / スキップ（理由: ）|
| 追加したテスト | Backend: `apps/backend/tests/.../test_xxx.py::test_name` / Frontend: `apps/frontend/src/.../__tests__/xxx.test.ts`（スキップの場合は「なし」）|
| RED コマンド | `make test-backend` / `make test-frontend` 等（スキップの場合は「なし」）|
| RED 結果 | FAILED: X failed（AssertionError / ImportError 等）/ なし（スキップ）|
| GREEN コマンド | `make test-backend` / `make test-frontend` 等（スキップの場合は「なし」）|
| GREEN 結果 | PASSED: X passed / なし（スキップ）|

### Coverage 証跡
| 項目 | 内容 |
|------|------|
| Critical Path 判定 | /plan の検証定義から転記（Critical / Non-critical / Mixed / N/A） |
| 保護レイヤー | /plan の検証定義から転記 |
| Coverage expectation | /plan の検証定義から転記 |
| Focused test commands | /plan の検証定義から転記 |
| 結果 | PASS / N/A / 未解消 |

### ブラウザ確認
| 項目 | 結果 | 備考 |
|------|------|------|
| 主要導線の手動確認 | PASS / Deferred to /verify / N/A / 未解消 | [動作確認の概要] |
| Console error | PASS / Deferred to /verify / N/A / 未解消 | [新たな error / warn の有無] |
| Network 4xx/5xx | PASS / Deferred to /verify / N/A / 未解消 | [意図しないエラーの有無] |

> **N/A**: API / バックグラウンド処理 / 設定ファイルのみの変更でブラウザ導線が存在しない場合のみ。
> **Deferred**: `/verify` で軽量ヘルスチェックを行う場合。フロントエンド変更がある Issue では原則 `/verify` で実施。

### 未解消 / 先送り
[未実装・未確認・先送りした項目があれば明記。なければ「なし」]

### `/verify` で確認してほしいポイント
- [事実確認の重点項目 1]
- [事実確認の重点項目 2]
```

---

## 📋 後続 Issue で導入予定（forward reference の隔離）

| 参照先（未存在） | 用途 | 予定 Issue |
|--------------|------|----------|
| evidence-checker（`scripts/claude/verify_issue_evidence.py` 相当） | コメント記法の自動検証 | 後続 Issue（5-1 / D-1 想定） |
| ephemeral session memory writer（`scripts/claude/session_memory_writer.sh` 相当） | raw 詳細ログの memory 退避 | 後続 Issue（D-X 想定）|
| `/screen-verify` コマンド + TC YAML 自動実行 | post-merge ブラウザ検証 | 後続 Issue（D-X 想定） |
