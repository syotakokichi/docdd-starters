# DocDD Starter Kit

Doc Driven Development (DocDD) と 7-axis Traceability を軸に、バックエンド (FastAPI) とフロントエンド (Next.js) のモジュラーモノリス構成を素早く立ち上げるためのテンプレートを提供します。設計ガイド・テスト基盤・CI サンプルまで一通り揃えているため、要件定義から検証までの流れを短時間で整備できます。

## 技術スタック

| レイヤ | 採用技術 | 選定理由 |
| ------ | -------- | -------- |
| Backend | FastAPI + Python 3.11 | 高性能・非同期対応。自動ドキュメントや依存注入が充実し、AI/データ分析との親和性も高い。大規模コミュニティと拡張性があり、将来的な機能追加やスケールに対応しやすい。 |
| Frontend | Next.js App Router v15 + TypeScript | Private Folder を活用した責務分離が可能で、Server Components / Server Actions を使った最新アーキテクチャに対応。Segment 内の実装と共通コンポーネントを明確に分離できる。 |
| Testing | pytest / Vitest / Playwright (任意) | 7-axis の TC/TS と紐付けやすい構成にし、ユニット・統合・E2E を段階的に整備できる。Traceability map との整合チェックも自動化。 |
| CI | GitHub Actions | `docdd-starters/.github/workflows/docdd-starters-ci.yml` がサンプル。pre-commit、Back-end pytest、Front-end lint & unit test を実行。 |
| Docs | 7-axis + akfm-knowledge | DocDD の要求定義をテンプレ化。フロント実装は `akfm-knowledge/nextjs-basic-principle` を参照し、テストは `docs/testing/frontend-unit-testing.md` や `docs/backend/TESTING_GUIDE.md` を利用。 |

## リンク

- [Backend ガイド](docs/backend/README.md)
- [Frontend ガイド](docs/frontend/README.md)
- [Testing ガイド](docs/testing/README.md)
- [7-axis テンプレ](docs/7-axis)
- [Traceability サンプル](docs/testing/traceability/sample_map.json)
- [CI ワークフロー例](.github/workflows/docdd-starters-ci.yml)

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

## やりたいこと別の導線

| やりたいこと | 参照ポイント |
| -------------- | ------------- |
| FastAPI アーキテクチャを把握したい | `docs/backend/ARCHITECTURE.md`, `apps/backend/README.md` |
| Next.js の Private Folder を導入したい | `docs/frontend/PRIVATE_FOLDER_GUIDE.md`, `apps/frontend/README.md` |
| テストの作り方を知りたい | `docs/backend/TESTING_GUIDE.md`, `docs/testing/frontend-unit-testing.md`, `tests/README.md` |
| Traceability map を更新したい | `docs/testing/README.md`, `scripts/test/validate_traceability_map.py` |
| CI を整備したい | `.github/workflows/docdd-starters-ci.yml`, `.pre-commit-config.yaml` |

## FastAPI 採用理由（補足）

FastAPI は高性能な API サーバを短時間で構築できる Python フレームワークです。非同期処理・自動ドキュメント・依存性注入・セキュリティ機構が標準で備わっており、Python の豊富なライブラリ（特に AI / データ分析系）や大規模な開発者コミュニティと組み合わせることで、汎用性と拡張性に優れたバックエンド基盤を構築できます。Ruby on Rails や Node.js でも十分なケースはありますが、高速な API 性能・データ指向の開発・将来的な AI/機械学習との統合・スケールなどを考慮すると Python + FastAPI を選択する理由は明確です。

## 初期セットアップ

```bash
# フロントエンド依存のインストール
cd docdd-starters/apps/frontend
npm install

# バックエンド依存のインストール
cd ../../apps/backend
pip install -r requirements-dev.txt

# Docker でバックエンドを起動
cd ../..
make up  # 停止は make down
```

## テストの実行例

```bash
# Traceability map の整合性をチェック
python docdd-starters/scripts/test/validate_traceability_map.py --map docdd-starters/docs/testing/traceability/sample_map.json

# バックエンドのテスト
PYTHONPATH=docdd-starters/apps/backend pytest docdd-starters/tests/backend

# フロントエンドのテスト
cd docdd-starters/apps/frontend
npm run lint:biome
npm run check:segments
npm run test:unit
```

このスターターを基に、プロジェクト固有のモジュールやドキュメントを追加して運用してください。
