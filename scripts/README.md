# Scripts

スターター共通で利用するスクリプトを用途別に配置しています。

- `test/`: Traceability map 検証など DocDD テスト関連
- `frontend/`: Next.js Private Folder 構成チェックなどフロント専用スクリプト
- 追加スクリプトを作成する場合は用途に応じてサブディレクトリを増やしてください。

## test/ サブディレクトリの主なスクリプト

- `auto_sync_test_sheets.sh`: Google Sheets 同期のエントリポイント。`TEST_SHEETS_SECRET_ARN` や `TEST_SPREADSHEET_ID` などの環境変数を設定してから実行します（`--dry-run` / `--secret-arn` / `--spreadsheet-id` オプション対応）。
- `enhanced_sheets_sync.py`: pytest / DocDD からメタデータを収集し、シートを生成するメイン処理。本番同期前に `scripts/test/config/test_environment.json` を参考に必要な Secret/シート ID を登録してください。
- `collect_test_metadata.py` と `docdd_test_collector.py`: それぞれ pytest と 7-axis TS ドキュメントからトレーサビリティ情報を抽出します。
- `validate_traceability_map.py`: `docs/testing/traceability/<domain>_map.json` の整合性チェックに利用します。`make traceability` や pre-commit から呼び出しても OK です。
- `requirements.txt`: Sheets 連携で必要になる `google-api-python-client` / `gspread` / `boto3` / `PyYAML` などの依存セット。仮想環境を作成したら `pip install -r scripts/test/requirements.txt` を実行してください。
- `.env.example`: `PROJECT_NAME` や Sheets 連携用の Secret など共通環境変数はここから `.env` を作成し、`auto_sync_test_sheets.sh` で自動読み込みさせます。
