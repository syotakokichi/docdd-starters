# DocDD Starter Kit

Doc Driven Development (DocDD) と 7-axis Traceability を軸に、バックエンド (FastAPI) とフロントエンド (Next.js) のモジュラーモノリス構成を素早く立ち上げるためのテンプレートを提供します。

## 特徴

- **DocDD**: 要件→設計→実装→テストの一貫したドキュメント管理
- **7-axis Traceability**: 要件からテストまで追跡可能（BR→UC→DM→SR/NSR→EXT→API→TC）
- **Claude Code統合**: Issue駆動開発フロー（/1〜/6）をテンプレート化
- **Progress Sync**: Google Sheets × GitHub Issues の双方向同期
- **CI/CD**: GitHub Actions + GAS自動デプロイ

## ディレクトリ構成

```
apps/
  backend/              # FastAPI モジュラーモノリス
  frontend/             # Next.js App Router
docs/
  7-axis/               # DocDD 7軸トレーサビリティドキュメント
  backend/              # バックエンド設計ガイド
  frontend/             # フロントエンド設計ガイド
  testing/              # テスト運用ガイド
scripts/
  test/                 # トレーサビリティ検証スクリプト
  frontend/             # フロントエンド用スクリプト
  gas/progress-sync/    # Sheets × GitHub 同期 (GAS)
tests/
  backend/              # バックエンドテスト
  frontend/             # フロントエンドテスト
.claude/
  commands/             # Issue駆動開発コマンド (/1〜/6, /a〜/c)
  rules/                # 命名・コミットメッセージ規約
  skills/               # AI実行知識（パターン・ドメイン）
.github/workflows/
  docdd-starters-ci.yml # CI/CDワークフロー
  deploy-gas.yml        # GAS自動デプロイ
```

## リンク

- [Backend ガイド](docs/backend/README.md)
- [Frontend ガイド](docs/frontend/README.md)
- [Testing ガイド](docs/testing/README.md)
- [7-axis テンプレ](docs/7-axis)
- [Traceability サンプル](docs/testing/traceability/sample_map.json)
- [Claude Code ガイド](.claude/CLAUDE.md)
- [Progress Sync ガイド](scripts/gas/progress-sync/README.md)
- [CI ワークフロー例](.github/workflows/docdd-starters-ci.yml)
  - 詳細説明: [docs/ci.md](docs/ci.md)

## 初期セットアップ

1. `.env.example` をコピーし、`PROJECT_NAME` を設定
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
cd apps/frontend
npm run lint:biome
npm run check:segments
npm run test:unit
```

## Claude Code 開発フロー

Issue駆動開発のスラッシュコマンド:

| コマンド | 説明 |
|---------|------|
| `/1` | Issue作成 |
| `/2` | 実装計画を立案してIssue本文に追記 |
| `/3` | ブランチ作成とIssue紐付け |
| `/4` | 実装フェーズ開始（進行中ラベル設定） |
| `/5` | Pull Request作成 |
| `/6` | マージ後のクリーンアップ |
| `/a`,`/b`,`/c` | Worktree並列開発 |

詳細は [.claude/CLAUDE.md](.claude/CLAUDE.md) を参照。

## Progress Sync（Sheets × GitHub）

Google Sheets の計画表と GitHub Issues を双方向同期:

- **Sheets → GitHub**: タスク追加/編集時にIssue作成/更新
- **GitHub → Sheets**: Issue/PRイベントでステータス更新

セットアップ手順は [scripts/gas/progress-sync/README.md](scripts/gas/progress-sync/README.md) を参照。

## 技術選定

### Next.js 採用理由

Next.js App Router は Server Components や Server Actions を含む最新アーキテクチャをサポートし、段階的な導入にも向いています。高速な SSR/ISR、ルーティングの柔軟性、TypeScript との親和性、豊富なエコシステム（shadcn/ui、Biome 等）が優位点です。

### FastAPI 採用理由

FastAPI は高性能な API サーバを短時間で構築できる Python フレームワークです。非同期処理・自動ドキュメント・依存性注入・セキュリティ機構が標準で備わっており、Python の豊富なライブラリ（特に AI / データ分析系）と組み合わせることで、汎用性と拡張性に優れたバックエンド基盤を構築できます。

---

DocDD サンプル TS (`docs/7-axis/7_TC/TS-SAMPLE-001.md`) と連動するテストは `tests/backend/unit/test_balance_projection.py`（pytest）と `tests/frontend/unit/sample/balance-status.test.ts`（Vitest）を参照してください。

このスターターを基に、プロジェクト固有のモジュールやドキュメントを追加して運用してください。
