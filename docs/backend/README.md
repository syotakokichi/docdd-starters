# バックエンドスターター ガイド

FastAPI モジュラーモノリス構成を採用したスターターです。概要は以下を参照してください。

- [ARCHITECTURE.md](ARCHITECTURE.md): ディレクトリ構造、モジュール作成フロー、依存ガバナンス
- [TESTING_GUIDE.md](TESTING_GUIDE.md): pytest を用いたバックエンドテストのテンプレート。フロントのテストは `docdd-starters/docs/testing/frontend-unit-testing.md` を参照
- `docdd-starters/apps/backend/README.md`: プロジェクト直下のセットアップ手順
- Docker 起動: `docdd-starters/Makefile` を使い `make up` / `make down`

## 使用バージョン

| ツール | バージョン |
|--------|-----------|
| Python | 3.11+ |
| FastAPI | 0.110.0 |
| Uvicorn | 0.27.0 |

> 異なるバージョンをお使いの場合は、API の互換性を確認のうえ適宜読み替えてください。

カスタマイズ手順や追加のベストプラクティスがあれば、このディレクトリに追記して共有してください。
