# `docs/upstream-sync/` — 上流参照ハーネス追従の governance 文書群

## 目的

docdd-starters は上流参照ハーネス（外部の Claude Code 開発フロー実装）を起点に **OSS 汎用テンプレートとして再ベースライン** している。本ディレクトリは上流の改良を月次で取り込むかどうかを 4 区分（Adopt now / Adapt later / Document only / Reject）で判定し、その判定結果を **append-only 台帳** として残す governance 文書群を集約する。

> 本ディレクトリは **monorepo 内 governance** の位置づけ。実装コード（`apps/` / `scripts/` / `.claude/`）は変更しない。

## 構成

| ファイル | 役割 | 更新頻度 |
|---------|------|---------|
| [`baseline-commits.json`](./baseline-commits.json) | **採否台帳 SSOT**。`baselines[]` / `records[]` / `summary[]` の 3 配列を append-only で成長させる JSON。schema は `_schema` キーで自己ドキュメント化 | 月次（baseline 更新時） |
| [`drift-audit-<date>.md`](./drift-audit-2026-05-20.md) | 各 baseline の hand-curated audit table。人間レビュー用の Markdown 派生物（件数・record_id は ledger と ±0 で一致） | 月次（baseline 更新時に新規ファイル） |
| [`monthly-audit-procedure.md`](./monthly-audit-procedure.md) | 月次手動監査の 1-page runbook（4 ステップ: SHA 検証 → drift 列挙 → 4 区分判定 → ledger append） | 半期に 1 回程度（手順改良時） |
| `README.md`（本ファイル） | ディレクトリ意図 + 月次運用との関係 | 構成変更時のみ |

## 月次運用との関係

```
内部の上流参照手順メモ → monthly-audit-procedure.md（runbook）
                            ↓
                       baseline-commits.json（採否台帳 SSOT）
                       drift-audit-<date>.md（hand-curated 派生物）
                            ↓
                       Epic #69 Rolling Wave 反映 + 子 Issue 起票
```

- **入力**: 上流参照ハーネスの最新 commit SHA（`git ls-remote` で取得）
- **処理**: 4 ステップ runbook を 30〜60 分で実行
- **出力**: 新 baseline record + Rolling Wave 子 Issue 起票候補
- **Wave 4 ツール化**: `make audit-upstream` で Step 2-4 を自動化予定（本 runbook が tool 化の前提仕様）

## append-only ルール（重要）

`baseline-commits.json` の `baselines[]` / `records[]` / `summary[]` は **immutable**:

- 既存 record を書き換えない（schema 矛盾 / 再評価による classification 変更も**新 record として** emit する）
- 順序保証なし（id で同一性管理。`r001 → r002 → ...` は採番順、解釈順序は持たない）
- 再評価トリガが発火した場合の運用は `monthly-audit-procedure.md` Step 4 参照

## OSS sanitize 規約

公開境界（本ディレクトリ全ファイル + Epic #69 / 子 Issue 本文）には:

- **持ち込まない**: 上流組織名 / 私有 repo 名 / 決済プロバイダ名
- **持ち込んで OK**: 「上流参照ハーネス」「内部の上流参照手順メモ」「内部の OSS sanitize 規約メモ」など汎用化された表記

具体的な置換パターンは内部の OSS sanitize 規約メモを参照。

## 関連

- 親 Epic [#69](https://github.com/syotakokichi/docdd-starters/issues/69) — 上流参照ハーネス追従 + Optional/Finish 仕上げ
- Wave 0 Issue [#70](https://github.com/syotakokichi/docdd-starters/issues/70) — 本ディレクトリの起点
- [`.claude/rules/terminology.md`](../../.claude/rules/terminology.md) — Wave / Phase 名 SSOT
- [`.claude/templates/verify-issue-result.json`](../../.claude/templates/verify-issue-result.json) — `_schema` キーパターンの参考実装
