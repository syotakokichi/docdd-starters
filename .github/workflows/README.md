# docdd-starters CI ワークフロー

`docdd-starters-ci.yml` は以下のジョブを実行します。

1. **pre-commit**: `.pre-commit-config.yaml` に定義された Black / Ruff / Biome などのフックを全ファイルに対して実行します。
2. **backend-tests**: `PYTHONPATH=apps/backend pytest tests/backend` を実行します。
3. **frontend-tests**: npm 依存をインストールした後、Biome lint、Next.js lint、Private Folder 構成チェック、`npm run test:unit` を順に実行します。

`docdd-starters/**` に変更が含まれる Pull Request および `main` / `develop` ブランチへの push で起動し、DocDD スターターの品質チェック・テスト整合性を自動的に検証します。
