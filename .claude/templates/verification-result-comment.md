# 実装検証結果コメントテンプレート

`/verify` の結果を Issue コメントに残すテンプレート。`/develop` の実装サマリーと併せて、PR 作成前の最終ゲートとなる。

> **記法ルール**: 後続で evidence-checker（自動証跡検証）を導入する際の互換性を保つため、以下の記法を厳守する:
> - **見出し**: `## 実装検証結果（/verify）` をそのまま使う（`/develop` 側の `完了時点` suffix を引きずらない）
> - **TDD 判定行**: スキップ時は `スキップ（理由: ...）` と **同一セル内** に理由を書く
> - **結果値**: `PASS` / `N/A` / `未解消` のみ（`✅ PASS` / `PASS（31/31）` / `PASS — 詳細` 等の装飾は付けない）
> - **ブラウザ確認**: `PASS` / `Deferred` / `N/A` / `未解消` のみ

```markdown
## 実装検証結果（/verify）

### Status
- [完了 / 継続 / ブロッカーあり] — 1 行で記載
- 次アクション: `/6 <N>`（PR 作成）/ ユーザー判断待ち（理由）など

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

### 未解消 / 先送り
[未対応の指摘・テスト失敗・実装漏れがあれば明記。なければ「なし」]
```

---

## 📋 後続 Issue で導入予定（forward reference の隔離）

| 参照先（未存在） | 用途 | 予定 Issue |
|--------------|------|----------|
| evidence-checker（`scripts/claude/verify_issue_evidence.py` 相当） | コメント記法の自動検証 | 後続 Issue（5-1 / D-1 想定） |
| `.claude/rules/multi-model-review.md` | Codex + Claude SA × 2 の 3 reviewer 並列レビュー | 後続 Issue（D-1 想定）|
| ephemeral session memory writer | raw 3-reviewer 出力の退避 | 後続 Issue（D-X 想定）|
| `/screen-verify` + TC YAML 自動実行 | post-merge STG ブラウザ検証 | 後続 Issue（D-X 想定）|
