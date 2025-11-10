# テスト運用ガイド

DocDD プロジェクトでテストを設計・実装する際の基本フローをまとめています。

## ディレクトリ構成

```
tests/
├── backend
│   ├── unit
│   └── integration
└── frontend
    ├── unit
    └── e2e
```

- バックエンド: `pytest` を利用。`PYTHONPATH=apps/backend pytest tests/backend` で実行する例をスターターに含めています。
- フロントエンド: Vitest / Playwright など任意のテストツールをインストールして利用してください。
- 各テストコマンドは 7-axis `TC` の `automation.command` と一致させます。
- DocDD サンプル: `tests/backend/unit/test_balance_projection.py`（TC-SAMPLE-001-001）と `tests/frontend/unit/sample/balance-status.test.ts`（TC-SAMPLE-001-002）が `TS-SAMPLE-001.md` の検証例になっています。

## Traceability と CI

1. テスト作成後は `docs/testing/traceability/<domain>_map.json` を更新し、`python scripts/test/validate_traceability_map.py --map docs/testing/traceability/<domain>_map.json` で整合性をチェック。
   - サンプル: `docs/testing/traceability/sample_map.json`
2. CI ワークフロー（例: `.github/workflows/test.yml`）で lint / unit / e2e を実行し、Traceability 検証も組み込みます。
3. `scripts/test/export_monitoring_results.py` を使う場合は実行コマンドと Git SHA を併記し、CSV を `scripts/test/output/` 以下へ出力してください。

## DocDD + Sheets ワークフロー
1. 7-axis で TS/TC を追加 (`docs/7-axis/7_TC/TS-SAMPLE-001.md` を参考に作成)
2. `docs/testing/traceability/<domain>_map.json` に `mappings` / `document_references` を追記
3. `python scripts/test/validate_traceability_map.py --map docs/testing/traceability/<domain>_map.json`
4. `scripts/test/auto_sync_test_sheets.sh --dry-run` で依存関係や Secret 設定を確認
5. `scripts/test/auto_sync_test_sheets.sh` を実行して Google Sheets を更新
6. シート側でタブ構成・ダッシュボードを確認（詳細: `docs/testing/test-sheets-integration-guide.md`）

## CI テンプレート

- `docdd-starters/.github/workflows/docdd-starters-ci.yml` に、pre-commit・バックエンド pytest・フロントエンド Biome/Lint/Unit Test を実行するワークフローテンプレートを用意しています。
- Private Folder の構成チェックは `npm run check:segments` を介して CI でも自動実行されます。

## 参考

- Backend: [docs/backend/TESTING_GUIDE.md](../backend/TESTING_GUIDE.md)
- pytest: https://docs.pytest.org/
- Playwright: https://playwright.dev/
- Vitest: https://vitest.dev/
