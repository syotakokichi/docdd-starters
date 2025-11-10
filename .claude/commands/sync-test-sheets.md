# Google Sheets テスト同期

DocDD Starters では `scripts/test/auto_sync_test_sheets.sh` が環境チェック → 依存解決 → `enhanced_sheets_sync.py` 実行までを自動化します。{PROJECT} でテストを書いたら以下の手順で Google Sheets を更新してください。

## 🚀 推奨コマンド
```bash
scripts/test/auto_sync_test_sheets.sh
```
- `TEST_SHEETS_SECRET_ARN` に AWS Secrets Manager の ARN を設定（`<<set-your-secret-arn>>` を置き換え）
- Secret に `credentials`（サービスアカウント JSON）と `spreadsheet_id` を格納するか、`TEST_SPREADSHEET_ID` で外だし
- `PROJECT_NAME` を指定するとログ/ダッシュボードに {PROJECT} 名が出力されます

## 🔧 オプション
```bash
scripts/test/auto_sync_test_sheets.sh --force-install   # 依存を再インストール
scripts/test/auto_sync_test_sheets.sh --setup-only      # セットアップだけ実行
scripts/test/auto_sync_test_sheets.sh --check-only      # 環境チェックのみ
scripts/test/auto_sync_test_sheets.sh --dry-run         # Sheets を更新せず差分確認
scripts/test/auto_sync_test_sheets.sh --verbose         # 詳細ログ
scripts/test/auto_sync_test_sheets.sh --secret-arn arn:aws:...     # 環境変数を上書き
scripts/test/auto_sync_test_sheets.sh --spreadsheet-id 1Abc...     # Secret にない場合に指定
```

## 🧰 手動コマンド
```bash
apps/backend/venv/bin/python3 scripts/test/enhanced_sheets_sync.py \
  --secret-arn "$TEST_SHEETS_SECRET_ARN" \
  --spreadsheet-id "$TEST_SPREADSHEET_ID" \
  --dry-run
```
> Secret ではなくローカル JSON を使う場合は `--credentials /path/to/credentials.json --spreadsheet-id <id>` を指定してください。
>
> `.env.example` から `.env` を作成して値をセットしておくと、`scripts/test/auto_sync_test_sheets.sh` が自動読み込みします。

## 📋 前提条件
- Python 3.8+ / AWS CLI / Google Sheets API 有効化済み
- `scripts/test/requirements.txt` をインストール（google-api-python-client, google-auth, gspread, boto3, PyYAML, pandas）
- 7-axis TS (`docs/7-axis/7_TC/TS-SAMPLE-001.md`) とマップ (`docs/testing/traceability/<domain>_map.json`) が最新
- `python scripts/test/validate_traceability_map.py --map ...` が成功していること

## ⚠️ 注意ポイント
- Secrets Manager / Spreadsheet ID はテンプレート値のままだと失敗します。README と `docs/testing/test-sheets-integration-guide.md` を参照し、自分のプロジェクト用に登録してください。
- Dry run で確認 → 本番同期の順序を徹底し、Google Sheets 側でもタブ追加やダッシュボード更新を確認します。

## 🔍 トラブルシューティング
| 症状 | 解決策 |
| --- | --- |
| `Secret ARN がプレースホルダ` | `export TEST_SHEETS_SECRET_ARN=...` または `--secret-arn` で指定 |
| `googleapiclient import error` | `pip install -r scripts/test/requirements.txt` |
| `403: The caller does not have permission` | サービスアカウントを対象シートに共有 |
| `Spreadsheet ID not found` | Secret に `spreadsheet_id` を追加 or `--spreadsheet-id` を付与 |

## 📖 関連ドキュメント
- `docs/testing/test-sheets-integration-guide.md`
- `docs/7-axis/README.md`
- `docs/testing/README.md`
