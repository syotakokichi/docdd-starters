# DocDD Starter Kit

Doc Driven Development (DocDD) と 7-axis Traceability を軸に、バックエンド (FastAPI) とフロントエンド (Next.js) のモジュラーモノリス構成を素早く立ち上げるためのテンプレートを提供します。

設計ガイド・テスト基盤・CI サンプルまで一通り揃えているため、要件定義から検証までの流れを短時間で整備できます。


## リンク

- [Backend ガイド](docs/backend/README.md)
- [Frontend ガイド](docs/frontend/README.md)
- [Testing ガイド](docs/testing/README.md)
- [7-axis テンプレ](docs/7-axis)
- [Traceability サンプル](docs/testing/traceability/sample_map.json)
- [Sheets 同期ガイド](docs/testing/test-sheets-integration-guide.md)
- [Claude Commands ガイド](.claude/commands/README.md)
- [CI ワークフロー例](.github/workflows/docdd-starters-ci.yml)
  - 詳細説明: [docs/ci.md](docs/ci.md)

## ディレクトリ構成

```
Makefile            # Docker コンテナ起動 / 停止 (`make up`, `make down`)
apps/
  backend/          # FastAPI モジュラーモノリス (Dockerfile, README 付き)
  frontend/         # Next.js Private Folder スターター
docs/               # 7-axis, ガイド、akfm-knowledge
scripts/            # Traceability 検証 / Private Folder チェックなど
tests/              # backend / frontend のテストハブ
.github/workflows/  # docdd-starters CI
```

## Next.js 採用理由（補足）

Next.js App Router は Server Components や Server Actions を含む最新アーキテクチャをサポートし、段階的な導入にも向いています。

高速な SSR/ISR、ルーティングの柔軟性、TypeScript との親和性、豊富なエコシステム（shadcn/ui、Biome 等）、セキュリティ対応の早さが優位点です。



React/Next.js はグローバルコミュニティや採用実績が多く、クラウド／Vercel などのホスティングとの相性も良いため、運用コストと開発速度のバランスが取れます。

## FastAPI 採用理由（補足）

FastAPI は高性能な API サーバを短時間で構築できる Python フレームワークです。

非同期処理・自動ドキュメント・依存性注入・セキュリティ機構が標準で備わっており、Python の豊富なライブラリ（特に AI / データ分析系）や大規模な開発者コミュニティと組み合わせることで、汎用性と拡張性に優れたバックエンド基盤を構築できます。

Ruby on Rails や Node.js でも十分なケースはありますが、高速な API 性能・データ指向の開発・将来的な AI/機械学習との統合・スケールなどを考慮すると Python + FastAPI を選択する理由は明確です。

## 初期セットアップ

1. `.env.example` をコピーし、`PROJECT_NAME` や `TEST_SHEETS_SECRET_ARN` を設定（`auto_sync_test_sheets.sh` が自動で読み込みます）
2. 依存関係をインストールし、Docker でバックエンドを起動

```bash
cp .env.example .env
npm --prefix apps/frontend install
pip install -r apps/backend/requirements-dev.txt
pip install -r scripts/test/requirements.txt
make up        # 停止は make down
```

## テストの実行例

```bash
# Traceability map の整合性をチェック
make traceability


# バックエンドのテスト
make test-backend


# フロントエンドのテスト
cd docdd-starters/apps/frontend
npm run lint:biome
npm run check:segments
npm run test:unit
```

DocDD サンプル TS (`docs/7-axis/7_TC/TS-SAMPLE-001.md`) と連動するテストは `tests/backend/unit/test_balance_projection.py`（pytest）と `tests/frontend/unit/sample/balance-status.test.ts`（Vitest）を参照してください。

このスターターを基に、プロジェクト固有のモジュールやドキュメントを追加して運用してください。

## DocDD + Sheets 同期フロー

1. 7-axis に TS/TC を追加し、`docs/testing/traceability/<domain>_map.json` を更新
2. `python scripts/test/validate_traceability_map.py --map docs/testing/traceability/<domain>_map.json`
3. AWS Secrets Manager に Google Sheets 認証情報と Spreadsheet ID を登録し、`TEST_SHEETS_SECRET_ARN`（必要なら `TEST_SPREADSHEET_ID`）を設定
4. `scripts/test/auto_sync_test_sheets.sh --dry-run` で依存関係とアクセス権を検証
5. `scripts/test/auto_sync_test_sheets.sh` で本番同期 → Google Sheets のタブ構成/ダッシュボードを確認

詳細は `docs/testing/test-sheets-integration-guide.md` と `.claude/commands/sync-test-sheets.md` を参照してください。
