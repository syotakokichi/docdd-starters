# Terraform - インフラ構成定義

AWS ECS Fargate をベースとしたインフラ構成を Terraform で管理します。

## アーキテクチャ

```
Internet
  ↓
CloudFront (CDN)
  ↓
ALB (Application Load Balancer)
  ├── Frontend (ECS Fargate / Next.js)
  └── Backend (ECS Fargate / FastAPI)
        ↓
      RDS (PostgreSQL)
        ↓
      S3 (静的ファイル)
```

## ディレクトリ構成

```
terraform/
├── environments/
│   ├── stg/              # ステージング環境
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   └── prod/             # 本番環境
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars
├── modules/
│   ├── network/          # VPC, Subnet, ALB
│   ├── ecs/              # ECS Fargate (frontend + backend)
│   ├── rds/              # PostgreSQL
│   ├── s3/               # 静的ファイルストレージ
│   ├── cloudfront/       # CDN
│   ├── secrets/          # Secrets Manager
│   └── monitoring/       # CloudWatch
└── README.md
```

## 使い方

### 初期セットアップ

```bash
cd terraform/environments/stg
terraform init
```

### プラン確認

```bash
terraform plan
```

### 適用

```bash
terraform apply
```

## 環境変数・シークレット

| 変数 | 説明 | 設定場所 |
|------|------|---------|
| `AWS_ROLE_ARN_STG` | ステージング用IAMロール | GitHub Secrets |
| `AWS_ROLE_ARN_PROD` | 本番用IAMロール | GitHub Secrets |
| `PROJECT_NAME` | プロジェクト名 | GitHub Variables |
| `db_password` | DBパスワード | terraform.tfvars (gitignore) |

## 使用バージョン

| ツール | バージョン |
|--------|-----------|
| Terraform | >= 1.9 |

> 異なるバージョンをお使いの場合は、プロバイダの互換性を確認のうえ適宜読み替えてください。

## 注意事項

- `terraform.tfvars` は `.gitignore` に含め、シークレット情報をコミットしない
- 本番環境への apply は CI/CD 経由で実行（手動 apply は緊急時のみ）
- ステートファイルは S3 バックエンドで管理
