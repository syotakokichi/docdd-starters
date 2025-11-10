# Google Sheets 同期ガイド

DocDD Starters には ClubPay で利用している Google Sheets 同期スクリプトをテンプレートとして同梱しています。AWS Secrets Manager と Google Sheets API の設定だけ差し替えれば、DocDD + テストシート同期フローをそのまま再利用できます。

## 1. 前提条件
- Python 3.8 以上（`scripts/test/auto_sync_test_sheets.sh` が仮想環境を自動作成）
- AWS CLI で `aws sts get-caller-identity` が成功すること
- Google Cloud でサービスアカウントと Sheets API を有効化済み

## 2. Secrets Manager の準備
1. Google サービスアカウント JSON を作成
2. AWS Secrets Manager に以下の形式で登録（キー名は固定）

```json
{
  "credentials": { ...service account json... },
  "spreadsheet_id": "1AbcDEF..."
}
```

3. Secret の ARN を控え、環境変数に設定

```bash
export TEST_SHEETS_SECRET_ARN="arn:aws:secretsmanager:ap-northeast-1:123456789012:secret:your-secret"
```

> Spreadsheet ID を Secrets Manager で管理しない場合は `export TEST_SPREADSHEET_ID="your-id"` をセットします。

## 2.5 `.env` で共通設定を管理

```
cp .env.example .env
# PROJECT_NAME / TEST_SHEETS_SECRET_ARN / TEST_SPREADSHEET_ID を編集
```

`scripts/test/auto_sync_test_sheets.sh` はプロジェクトルートの `.env` を自動で読み込むため、各マシンでエクスポートし直す必要がなくなります。

## 3. スクリプトの実行順序
1. `python scripts/test/validate_traceability_map.py --map docs/testing/traceability/<domain>_map.json`
2. `scripts/test/auto_sync_test_sheets.sh --dry-run` で接続確認
3. 本番同期: `scripts/test/auto_sync_test_sheets.sh`

オプション:

```bash
scripts/test/auto_sync_test_sheets.sh --force-install  # 依存を再インストール
scripts/test/auto_sync_test_sheets.sh --secret-arn arn:aws:...  # 環境変数を上書き
scripts/test/auto_sync_test_sheets.sh --spreadsheet-id 1Abc...  # Secret ではなくローカル値を利用
```

## 4. 依存関係
- `scripts/test/requirements.txt` を仮想環境でインストール（`google-api-python-client`, `gspread`, `boto3`, `PyYAML` など）
- 依存の確認/再インストールは `--check-only` / `--force-install` で自動化済み

## 5. Google Sheets 側の構成
- 1 ファイル内に「ドメイン別」「DocDD」「pytest」「ダッシュボード」など複数のシートを持たせる想定
- 同期スクリプトがシートを自動作成するため、事前にシート名を揃える必要はありません
- 変更履歴や KPI チャートを利用する場合は `scripts/test/enhanced_sheets_sync.py` のロジックを参照し、必要に応じてタブ追加をカスタマイズしてください

## 6. カスタマイズポイント
- `PROJECT_NAME` 環境変数を設定するとログや Google Sheets のタイトルに {PROJECT} 名が反映されます
- `DOCDD_TS_ROOT` / `DOCDD_TRACEABILITY_ROOT` を設定すると TS フォルダやマップの場所を変更できます
- カテゴリの分類ロジックは `scripts/test/enhanced_sheets_sync.py` の `_determine_category` を参照し、{PROJECT} のドメインラベルへ置き換えてください

## 7. トラブルシューティング
- Secret ARN が未設定の場合: `TEST_SHEETS_SECRET_ARN` を確認
- Spreadsheet ID がシークレットに含まれていない場合: `--spreadsheet-id` で明示的に指定
- Google API 403/404: サービスアカウントを対象スプレッドシートに共有
- `googleapiclient` ImportError: `pip install -r scripts/test/requirements.txt`

このガイドを README と併せてプロジェクト初期セットアップ手順に組み込んでください。
