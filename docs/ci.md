# CI ワークフロー

`.github/workflows/docdd-starters-ci.yml` の構成:

1. **pre-commit**: Python/Node をセットアップし `./.pre-commit-config.yaml` の hooks を実行します。
2. **backend-tests**: `PYTHONPATH=apps/backend pytest tests/backend` を実行します。
3. **frontend-tests**: npm install 後、Biome lint、Next.js lint、Private Folder チェック、`npm run test:unit` を順に実行します。

Pull Request と `main` / `develop` への push で起動し、DocDD スターターの品質を自動検証します。
