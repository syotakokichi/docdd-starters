# テストケース (TC) 作成ガイド

7-axis の TC ドキュメントはテスト自動化や手動検証の内容を明確にするため、粒度の細かい記述が必要です。テンプレート (`TC-template.yaml`) をベースに、以下のポイントを必ず埋めてください。

## 必須項目
- `test_case_id`: 例 `TC-FRONTEND-001-001`。TS の ID に 3 桁連番を付ける形式を推奨
- `title`: テストが検証する具体的な条件（例: "FilterBar ボタン押下で applyFilter が呼び出されること"）
- `domain`: ドメイン名（frontend, backend など）
- `automation.command`: 実行可能なコマンド（例: `npm run test:unit`）
- `steps`: 操作手順を順序付きで記載
- `expected_result`: 実行後に検証すべき結果を明文化
- `related_requirements.traces_to`: 該当する FR/UC などを列挙し、Traceability を担保

## 記述例
```
test_case_id: TC-FRONTEND-001-001
title: FilterBar ボタン押下で applyFilter が呼び出されること
domain: frontend
...
steps:
  - order: 1
    action: 'This Week' ボタンをクリック
    expected: applyFilter("week") が呼び出される
expected_result: applyFilter が "week" を引数に呼ばれる
```

## Traceability 連携
- `docs/testing/traceability/<domain>_map.json` に TC ID / コマンド / 手順 を登録
- `docdd-starters/scripts/test/validate_traceability_map.py` を実行して整合性を確認

詳細はテンプレートやサンプル (`docs/testing/traceability/sample_map.json`) を参照してください。

## DocDD + Sheets フロー（テンプレ）
1. `TS-SAMPLE-001.md` をコピーして {PROJECT} 用の TS を作成
2. `docs/testing/traceability/<domain>_map.json` に `mappings` / `document_references` を更新
3. `python scripts/test/validate_traceability_map.py --map docs/testing/traceability/<domain>_map.json`
4. `scripts/test/auto_sync_test_sheets.sh --dry-run` で差分を確認
5. `scripts/test/auto_sync_test_sheets.sh` を実行して Google Sheets に反映（Secret ARN と Spreadsheet ID は README を参照）
