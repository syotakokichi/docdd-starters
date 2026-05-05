---
description: バックエンド/フロントエンド/トレーサビリティのテスト実行コマンド集を提示します。
disable-model-invocation: true
---

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
```

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
- `pytest: No module named 'apps'` → `PYTHONPATH=apps/backend` を付与
- `npm run check:segments` 失敗 → `apps/frontend/README.md` の Private Folder ガイドに従って修正

このテンプレートをプロジェクト用にコピーし、必要に応じてコマンドやファイルパスを追加してください。
