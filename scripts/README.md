# Scripts

スターター共通で利用するスクリプトを用途別に配置しています。

- `test/`: Traceability map 検証など DocDD テスト関連
- `frontend/`: Next.js Private Folder 構成チェックなどフロント専用スクリプト
- 追加スクリプトを作成する場合は用途に応じてサブディレクトリを増やしてください。

## test/ サブディレクトリの主なスクリプト

- `collect_test_metadata.py` と `docdd_test_collector.py`: それぞれ pytest と 7-axis TS ドキュメントからトレーサビリティ情報を抽出します。
- `validate_traceability_map.py`: `docs/testing/traceability/<domain>_map.json` の整合性チェックに利用します。`make traceability` や pre-commit から呼び出しても OK です。
- `requirements.txt`: テストスクリプトで必要な依存セット。仮想環境を作成したら `pip install -r scripts/test/requirements.txt` を実行してください。
