# テストスターター

`tests/` 直下にバックエンド・フロントエンド共通のテスト資産を配置し、7-axis の TC/TS と紐付けやすい構成を提供します。

```
tests/
├── backend/
│   ├── unit/
│   └── integration/
└── frontend/
    ├── unit/
    └── e2e/
```

- `backend` は pytest を想定しており、`PYTHONPATH=apps/backend` で実行する例を同梱しています。
- `frontend` は Vitest / Playwright など任意のツールで差し替え可能な README を配置しています。
- CI では `pytest tests/backend` や `pnpm test:unit` などコマンドを揃え、TC `automation.command` と一致させてください。
- 詳細なバックエンドのテストガイドは `docdd-starters/docs/backend/TESTING_GUIDE.md` を参照してください。
