# Google Sheetsテスト同期

## 🚀 自動実行コマンド（推奨）

```bash
# プロジェクトルートから実行
scripts/test/auto_sync_test_sheets.sh
```

このコマンドは以下を自動で実行します：
- 環境チェック
- 依存関係の自動解決
- 認証情報の検証
- Google Sheets同期の実行
- 結果の表示

## 🔧 セットアップオプション

```bash
# 初回実行時または依存関係に問題がある場合
scripts/test/auto_sync_test_sheets.sh --force-install

# セットアップのみ実行（同期は行わない）
scripts/test/auto_sync_test_sheets.sh --setup-only

# 環境チェックのみ実行
scripts/test/auto_sync_test_sheets.sh --check-only

# ドライランモード（実際の同期は行わない）
scripts/test/auto_sync_test_sheets.sh --dry-run

# 詳細ログ出力
scripts/test/auto_sync_test_sheets.sh --verbose
```

## 🔄 従来のコマンド（手動）

```bash
# 手動実行する場合（非推奨）
apps/backend/venv/bin/python3 scripts/test/enhanced_sheets_sync.py --secret-arn="clubpay-stg-test-sheets"
```

## 📋 前提条件

自動実行コマンドが以下を自動でチェック・セットアップします：
- Python 3.8以上
- AWS認証情報（`aws sts get-caller-identity`で確認）
- 必要な依存関係（google-api-python-client, google-auth, boto3等）
- Google Sheets API認証情報（AWS Secret Manager経由）

## 🎯 実行結果

- 935件のテストケースをGoogle Sheetsに同期
- カテゴリ別シート（認証システム、決済システム、ポイント管理、店舗管理、サポーター管理、管理機能、インフラ・共通）
- 📊 テスト管理ダッシュボード
- リアルタイム進捗追跡とビジュアルチャート

## 🔍 確認方法

実行後に表示されるGoogle SheetsのURLを開いて同期結果を確認してください。

## 🛠️ トラブルシューティング

### 依存関係のエラー
```bash
scripts/test/auto_sync_test_sheets.sh --force-install
```

### AWS認証エラー
```bash
aws configure
# または
aws sts get-caller-identity
```

### Google Sheets接続エラー
```bash
# 環境チェックで詳細な診断
scripts/test/auto_sync_test_sheets.sh --check-only
```

### 詳細な診断
```bash
# 詳細ログで実行
scripts/test/auto_sync_test_sheets.sh --verbose
```

## 📖 関連ドキュメント

- [テスト管理システム統合ガイド](../../docs/test-sheets-integration-guide.md)
- [セットアップスクリプト](../test/setup_test_environment.py)
- [設定ファイル](../test/config/test_environment.json)
