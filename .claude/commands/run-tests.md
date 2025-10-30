# テスト実行コマンド

このファイルは、ClubPayバックエンドのテスト実行を効率化するClaude Commandsファイルです。

## 基本的なテスト実行

### 単体テスト実行
```bash
# 仮想環境を作成・有効化
python3 -m venv /tmp/test-env
source /tmp/test-env/bin/activate

# 必要な依存関係をインストール（Phase 1.5: 監視基盤テスト用の依存関係を含む）
pip install -r requirements.txt python-multipart pytest-asyncio boto3 moto

# 単体テストを実行
cd apps/backend
python -m pytest app/tests/test_image_processor.py -v
```

### 包括的テストレポート実行
```bash
# 仮想環境を有効化
source /tmp/test-env/bin/activate

# 包括的レポートを有効にしてテストを実行
cd apps/backend
python -m pytest app/tests/test_image_processor.py -p app.tests.pytest_comprehensive_reporter --comprehensive-report -v
```

### 特定のテストカテゴリを実行
```bash
# セキュリティテストを実行
python -m pytest app/tests/security/ -v

# パフォーマンステストを実行
python -m pytest app/tests/performance/ -v

# 統合テストを実行
python -m pytest app/tests/integration/ -v

# Phase 1.5: 監視基盤テストを実行
python -m pytest app/tests/e2e/test_monitoring_phase1.py -v -m monitoring
```

## テストメタデータ収集

### テストケース情報の収集
```bash
# 仮想環境を有効化
source /tmp/test-env/bin/activate

# テストメタデータを収集
python3 scripts/test/collect_test_metadata.py
```

### Google Sheetsへの同期（認証情報が必要）
```bash
# 環境変数を設定
export TEST_SHEETS_SECRET_ARN="clubpay-stg-test-sheets"
# または
export GOOGLE_SHEETS_CREDENTIALS_PATH="/path/to/credentials.json"
export TEST_SPREADSHEET_ID="your-spreadsheet-id"

# 拡張シート同期を実行
python3 scripts/test/enhanced_sheets_sync.py
```

## 環境設定

### 基本的な環境設定ファイル (.env)
```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=test_db
DB_USER=test_user
DB_PASS=test_password
STAFF_SUPABASE_URL=http://localhost:54321
STAFF_SUPABASE_KEY=test_key
SUPPORTER_SUPABASE_URL=http://localhost:54321
SUPPORTER_SUPABASE_KEY=test_key
```

## 高度なテスト実行

### カバレッジ付きテスト実行
```bash
# カバレッジレポートを生成
python -m pytest app/tests/ --cov=app --cov-report=html --cov-report=term
```

### 特定のマーカー付きテスト実行
```bash
# セキュリティマーカー付きテスト
python -m pytest -m security

# パフォーマンスマーカー付きテスト
python -m pytest -m performance

# 統合テスト
python -m pytest -m integration

# Phase 1.5: 監視基盤マーカー付きテスト
python -m pytest -m monitoring

# Phase 1.5: tc_idマーカー付きテスト（特定のTC IDでフィルタ）
python -m pytest -m "tc_id and monitoring"

# Phase 1.5: End-to-Endテスト
python -m pytest -m "e2e and monitoring"
```

### 並列テスト実行（pytest-xdist使用）
```bash
# 並列実行用ライブラリをインストール
pip install pytest-xdist

# 4つのワーカーで並列実行
python -m pytest app/tests/ -n 4
```

## テストレポート生成

### 包括的レポートの生成
```bash
# 包括的レポートを生成（Google Sheets連携なし）
python -m pytest app/tests/ -p app.tests.pytest_comprehensive_reporter --comprehensive-report

# 基本的なシートレポートを生成
python -m pytest app/tests/ -p app.tests.pytest_sheets_reporter --sheets-report
```

### カスタムレポートの実行
```bash
# HTMLレポートを生成
python -m pytest app/tests/ --html=report.html --self-contained-html

# JUnitXMLレポートを生成
python -m pytest app/tests/ --junitxml=report.xml

# Phase 1.5: 監視基盤テスト専用レポート生成
python -m pytest app/tests/e2e/test_monitoring_phase1.py -m monitoring --junitxml=monitoring_results.xml

# Phase 1.5: レポート結果をCSVに出力（リポジトリルートで実行）
cd ../../
python scripts/test/export_monitoring_results.py --input apps/backend/monitoring_results.xml --output monitoring_results.csv
```

## トラブルシューティング

### よくある問題と解決方法

#### 1. モジュールが見つからない場合
```bash
# 必要なライブラリを追加インストール
pip install fastapi sqlalchemy alembic uvicorn pytest-cov httpx python-multipart pytest-asyncio
```

#### 2. データベース接続エラー
```bash
# PostgreSQLドライバをインストール
pip install psycopg2-binary
```

#### 3. 非同期テストの実行エラー
```bash
# pytest-asyncioをインストール
pip install pytest-asyncio
```

#### 4. Google Sheets認証エラー
```bash
# 認証情報を確認
echo $TEST_SHEETS_SECRET_ARN
echo $GOOGLE_SHEETS_CREDENTIALS_PATH
```

## 継続的インテグレーション

### GitHub Actions用のテスト実行
```yaml
# .github/workflows/test.yml での使用例
- name: Run comprehensive tests
  run: |
    source /tmp/test-env/bin/activate
    cd apps/backend
    python -m pytest app/tests/ -p app.tests.pytest_comprehensive_reporter --comprehensive-report -v
```

### 定期的なテスト実行
```bash
# 日次テスト実行（cronジョブ用）
#!/bin/bash
cd /workspace/apps/backend
source /tmp/test-env/bin/activate
python -m pytest app/tests/ -p app.tests.pytest_comprehensive_reporter --comprehensive-report --junitxml=daily_report.xml
```

## 便利なエイリアス

bashrcやzshrcに追加することで効率化できます：

```bash
# テスト実行エイリアス
alias test-setup="python3 -m venv /tmp/test-env && source /tmp/test-env/bin/activate && pip install -r requirements.txt python-multipart pytest-asyncio"
alias test-run="cd apps/backend && source /tmp/test-env/bin/activate && python -m pytest"
alias test-comprehensive="cd apps/backend && source /tmp/test-env/bin/activate && python -m pytest -p app.tests.pytest_comprehensive_reporter --comprehensive-report"
alias test-security="cd apps/backend && source /tmp/test-env/bin/activate && python -m pytest app/tests/security/ -v"
alias test-performance="cd apps/backend && source /tmp/test-env/bin/activate && python -m pytest app/tests/performance/ -v"
alias test-metadata="source /tmp/test-env/bin/activate && python3 scripts/test/collect_test_metadata.py"
```

## テスト結果の確認

### 生成されるファイル
- `test_cases_YYYYMMDD_HHMMSS.csv`: テストメタデータ（CSV形式）
- `test_cases_YYYYMMDD_HHMMSS.json`: テストメタデータ（JSON形式）
- `htmlcov/`: カバレッジレポート（HTML形式）
- `report.html`: テストレポート（HTML形式）
- `report.xml`: テストレポート（JUnit XML形式）

### ログの確認
```bash
# テスト実行ログを確認
tail -f /tmp/test-env/var/log/pytest.log

# 包括的レポートのセッション情報
grep "Session ID" pytest.log
```

## Phase 1.5: 監視基盤テスト実行標準化

### 監視基盤テストの特徴
Phase 1.5では、監視基盤テストにtc_idマーカーを使用してトレーサビリティを確保します。

### tc_idマーカーの使用例
```python
@pytest.mark.tc_id("TC-OPS-001")
@pytest.mark.priority("critical")
@pytest.mark.monitoring
def test_vgw_timeout_critical_alert_flow():
    """VGW timeout → P1 alert → notification within 15 minutes"""
    pass
```

### 監視基盤テスト専用コマンド
```bash
# 全監視基盤テストを実行
python -m pytest -m monitoring -v

# 特定のTC IDでフィルタ
python -m pytest -k "TC-OPS-001" -v

# 優先度でフィルタ（critical priority）
python -m pytest -m "monitoring and priority" -k "critical" -v

# レポート生成付きで実行
python -m pytest -m monitoring --junitxml=monitoring_results.xml -v
```

### tc_id一覧とテスト内容
- **TC-OPS-001**: VGWタイムアウト→P1アラート→15分以内通知フロー
- **TC-OPS-002**: 複数アラート同時発生時の優先度順処理
- **TC-OPS-003**: SLA違反予測と先制エスカレーション
- **TC-OPS-004**: Do Not Disturb期間の通知ルーティング
- **TC-OPS-005**: 15分間ウィンドウ内での重複アラート抑制
- **TC-OPS-006**: 監視ダッシュボード用メトリクス収集
- **TC-OPS-007**: アラート発生から解決までの完全E2Eフロー

### CI/CD統合例
```yaml
# GitHub Actions例
- name: Run monitoring tests
  run: |
    cd apps/backend
    python -m pytest -m monitoring --junitxml=monitoring_results.xml
    cd ../../
    python scripts/test/export_monitoring_results.py --input apps/backend/monitoring_results.xml
```

これらのコマンドを使用することで、ClubPayバックエンドのテスト実行をスムーズに行うことができます。
