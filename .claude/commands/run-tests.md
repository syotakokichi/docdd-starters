# テスト実行コマンド

DocDD Starters で {PROJECT} の品質を担保するためのテストコマンドをまとめています。必要に応じて Issue や PR からこのファイルへリンクし、再現可能な検証ログを残してください。

## 推奨フロー
```bash
# 1. Traceability チェック
python scripts/test/validate_traceability_map.py --map docs/testing/traceability/<domain>_map.json

# 2. Backend テスト
PYTHONPATH=apps/backend pytest tests/backend -v
# or
make test-backend

# 3. Frontend テスト
cd apps/frontend
npm run lint:biome && npm run check:segments && npm run test:unit
```

## ドメイン別の実行例
```bash
# TS-SAMPLE-001 の pytest をピンポイントで実行
PYTHONPATH=apps/backend pytest tests/backend/unit/test_balance_projection.py -k "test_sample_balance_instant_update"

# フロントエンド（TS-SAMPLE-001 の同期バナー例）
cd apps/frontend
npx vitest run ../../tests/frontend/unit/sample/balance-status.test.ts --runInBand
```

## テストメタデータ収集
```bash
# pytest 側のテストメタデータ
python scripts/test/collect_test_metadata.py --output-dir scripts/test/output

# DocDD (TS) 側のメタデータ（auto_sync 内部からも実行されます）
python scripts/test/enhanced_sheets_sync.py --dry-run --secret-arn $TEST_SHEETS_SECRET_ARN
```

## Google Sheets 連携
```bash
export TEST_SHEETS_SECRET_ARN="arn:aws:secretsmanager:ap-northeast-1:123456789012:secret/your-secret"
export TEST_SPREADSHEET_ID="your-spreadsheet-id"  # Secret に含めるなら省略可

# Dry run
scripts/test/auto_sync_test_sheets.sh --dry-run --verbose

# 本番同期
scripts/test/auto_sync_test_sheets.sh
```
> 依存インストールはスクリプト内で自動チェックされます。詳細は `docs/testing/test-sheets-integration-guide.md` を参照。

## 環境セットアップ
```bash
python3 -m venv apps/backend/venv
source apps/backend/venv/bin/activate
pip install -r apps/backend/requirements-dev.txt
pip install -r scripts/test/requirements.txt
npm --prefix apps/frontend install
```

## オプション
```bash
# html カバレッジ
PYTHONPATH=apps/backend pytest tests/backend --cov=apps/backend --cov-report=html

# pytest markers
PYTHONPATH=apps/backend pytest tests/backend -m "tc_id and sample"

# 並列実行
PYTHONPATH=apps/backend pytest tests/backend -n auto
```

## トラブルシューティング
- `ImportError: googleapiclient` → `pip install -r scripts/test/requirements.txt`
- `SecretNotFoundException` → `TEST_SHEETS_SECRET_ARN` の値とリージョンを確認
- `pytest: No module named 'apps'` → `PYTHONPATH=apps/backend` を付与
- `npm run check:segments` 失敗 → `apps/frontend/README.md` の Private Folder ガイドに従って修正

このテンプレートをプロジェクト用にコピーし、必要に応じてコマンドやファイルパスを追加してください。
