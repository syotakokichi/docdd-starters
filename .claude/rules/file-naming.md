# File Naming - ファイル・ディレクトリ命名規則

## 基本ルール

| 対象 | 規則 | 例 |
|------|------|-----|
| ディレクトリ | kebab-case | `user-settings/`, `api-client/` |
| TypeScript/JS ファイル | kebab-case | `user-service.ts`, `api-client.ts` |
| React コンポーネント | PascalCase | `UserProfile.tsx`, `BalanceStatus.tsx` |
| Python ファイル | snake_case | `user_service.py`, `api_client.py` |
| テストファイル | 元ファイル名 + `.test`/`_test` | `user-service.test.ts`, `test_user_service.py` |
| 設定ファイル | kebab-case | `jest.config.ts`, `next.config.js` |
| Markdown | kebab-case または UPPER_SNAKE | `setup-guide.md`, `README.md` |

## フロントエンド（Next.js）

### App Router

```
app/
├── (auth)/              # Route Group（URL に含まれない）
│   ├── login/
│   │   └── page.tsx
│   └── register/
│       └── page.tsx
├── dashboard/
│   ├── _components/     # Private Folder（ルーティング対象外）
│   │   └── DashboardChart.tsx
│   └── page.tsx
└── layout.tsx
```

### コンポーネント

```
src/
├── components/
│   ├── ui/              # 汎用UIコンポーネント
│   │   ├── Button.tsx
│   │   └── Input.tsx
│   └── features/        # 機能別コンポーネント
│       └── auth/
│           ├── LoginForm.tsx
│           └── useAuth.ts
└── lib/
    └── api-client.ts
```

## バックエンド（FastAPI）

### モジュラーモノリス

```
app/
├── kernel/              # 共通基盤
│   ├── __init__.py
│   ├── config.py
│   └── database.py
├── modules/             # ドメインモジュール
│   └── billing/
│       ├── __init__.py
│       ├── domain/
│       │   ├── models.py
│       │   └── services.py
│       ├── infrastructure/
│       │   └── repositories.py
│       └── presentation/
│           └── routes.py
└── shared/              # 共通ユーティリティ
    └── utils.py
```

## テスト

```
tests/
├── backend/
│   ├── unit/
│   │   └── test_billing_service.py
│   └── integration/
│       └── test_billing_api.py
└── frontend/
    ├── unit/
    │   └── LoginForm.test.tsx
    └── e2e/
        └── login.spec.ts
```

## DocDD（7-axis）

```
docs/7-axis/
├── 1_BR/
│   └── BR-001.md
├── 2_UC/
│   └── UC-001.md
├── 7_TC/
│   ├── TS-SAMPLE-001.md
│   └── TC-SAMPLE-001-001.yaml
└── _templates/
```

## ルール

1. **一貫性**: 同一ディレクトリ内は同じ命名規則を適用
2. **明確さ**: ファイル名から内容が推測できるようにする
3. **短さ**: 不必要に長い名前は避ける
4. **検索性**: 一般的すぎる名前（`utils.ts`）は避け、具体的に（`date-utils.ts`）
