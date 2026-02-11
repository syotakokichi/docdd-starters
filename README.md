# DocDD Starter Kit

Doc Driven Development (DocDD) と 7-axis Traceability を軸に、バックエンド (FastAPI) とフロントエンド (Next.js) のモジュラーモノリス構成を素早く立ち上げるためのテンプレートを提供します。

## 特徴

- **DocDD**: 要件→設計→実装→テストの一貫したドキュメント管理
- **7-axis Traceability**: 要件からテストまで追跡可能（BR→UC→DM→SR/NSR→EXT→API→TC）
- **Claude Code統合**: Issue駆動開発フロー（/1〜/7）+ エージェントチーム
- **GitHub Projects**: タスク管理・ステータス自動更新
- **Pencil.dev連携**: UI設計→実装のシームレスなワークフロー
- **CI/CD**: GitHub Actions（CI + ステージング/本番デプロイ）
- **Terraform**: AWS ECS Fargate によるインフラ構成管理

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
  deploy/               # デプロイスクリプト（Terraform / ECS）
terraform/
  environments/         # 環境別設定（stg / prod）
  modules/              # 再利用可能なインフラモジュール
tests/
  backend/              # バックエンドテスト
  frontend/             # フロントエンドテスト
.claude/
  commands/             # Issue駆動開発コマンド (/1〜/7, /a〜/c)
  rules/                # 命名・コミットメッセージ規約
  skills/               # AI実行知識（パターン・ドメイン）
.github/workflows/
  docdd-starters-ci.yml # CIワークフロー
  deploy-stg.yml        # ステージングデプロイ
  deploy-prod.yml       # 本番デプロイ
```

## リンク

- [Backend ガイド](docs/backend/README.md)
- [Frontend ガイド](docs/frontend/README.md)
- [Testing ガイド](docs/testing/README.md)
- [7-axis テンプレ](docs/7-axis)
- [Traceability サンプル](docs/testing/traceability/sample_map.json)
- [Claude Code ガイド](.claude/CLAUDE.md)
- [Terraform ガイド](terraform/README.md)
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
make test-frontend

# 全テスト
make test
```

## Claude Code 開発フロー

Issue駆動開発のスラッシュコマンド:

| コマンド | 説明 |
|---------|------|
| `/1` | Issue作成 |
| `/2` | 実装計画を立案してIssue本文に追記（エージェントチーム活用可） |
| `/3` | ブランチ作成とIssue紐付け |
| `/4` | 実装フェーズ開始（進行中ラベル設定） |
| `/5` | 実装検証（品質ゲート） |
| `/6` | Pull Request作成 |
| `/7` | マージ後のクリーンアップ |
| `/a`,`/b`,`/c` | Worktree並列開発 |

### エージェントチーム

複雑なタスクではエージェントチーム機能を活用:
- `/2` 計画立案: 並列リサーチ・設計壁打ち
- `/5` 実装検証: バックエンド/フロントエンド並列検証
- 詳細は [.claude/rules/agent-teams.md](.claude/rules/agent-teams.md) を参照

詳細は [.claude/CLAUDE.md](.claude/CLAUDE.md) を参照。

## GitHub Projects 進捗管理

GitHub Projects でタスクのステータスを管理:

| コマンド | Projects Status |
|---------|-----------------|
| `/1` Issue作成 | → Backlog |
| `/2` 計画立案 | → Ready |
| `/3` ブランチ作成 | → In Progress |
| `/7` マージ完了 | → Done |

詳細は [.claude/rules/project-workflow.md](.claude/rules/project-workflow.md) を参照。

## インフラ管理（Terraform）

AWS ECS Fargate をベースとしたインフラ構成:

```
Internet → CloudFront → ALB → ECS Fargate (Frontend / Backend) → RDS (PostgreSQL)
```

### 主要コマンド

```bash
# Terraform
make tf-init                    # 初期化
make tf-plan                    # プラン確認
make tf-apply                   # 適用
make tf-plan ENV=prod           # 本番環境のプラン

# デプロイ
make deploy-stg                 # ステージングへデプロイ
make deploy-backend-prod        # 本番バックエンドデプロイ

# ECS運用
make ecs-status                 # サービス状態確認
make ecs-logs-backend           # バックエンドログ閲覧
make ecs-sh                     # コンテナにシェル接続
```

詳細は [terraform/README.md](terraform/README.md) を参照。

## CI/CD

| ワークフロー | トリガー | 内容 |
|-------------|---------|------|
| CI | PR / push to main | テスト・リント・品質チェック |
| Deploy Staging | push to main | ステージング自動デプロイ |
| Deploy Production | タグ作成 (v*) | 本番デプロイ（手動承認） |

## 技術選定

### Next.js 採用理由

Next.js App Router は Server Components や Server Actions を含む最新アーキテクチャをサポートし、段階的な導入にも向いています。高速な SSR/ISR、ルーティングの柔軟性、TypeScript との親和性、豊富なエコシステム（shadcn/ui、Biome 等）が優位点です。

### FastAPI 採用理由

FastAPI は高性能な API サーバを短時間で構築できる Python フレームワークです。非同期処理・自動ドキュメント・依存性注入・セキュリティ機構が標準で備わっており、Python の豊富なライブラリ（特に AI / データ分析系）と組み合わせることで、汎用性と拡張性に優れたバックエンド基盤を構築できます。

---

DocDD サンプル TS (`docs/7-axis/7_TC/TS-SAMPLE-001.md`) と連動するテストは `tests/backend/unit/test_balance_projection.py`（pytest）と `tests/frontend/unit/sample/balance-status.test.ts`（Vitest）を参照してください。

このスターターを基に、プロジェクト固有のモジュールやドキュメントを追加して運用してください。
