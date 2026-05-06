# References

Claude Code のコマンド / スキルから参照される静的ドキュメント置き場です。

| ドキュメント | 用途 |
|-------------|------|
| [capability-matrix.md](./capability-matrix.md) | Epic #23 の Phase 0-F × capability 対応表。`scripts/claude/detect-capabilities.sh` の出力を consumer 側がどう扱うかを定義 |
| [applicable-skills.md](./applicable-skills.md) | Issue 種別 → 適用 skill のマッピング SSOT（`/plan` Phase 1 / `/issue` / `/verify` Step 1 から参照） |

## 関連ファイル

- [../../scripts/claude/detect-capabilities.sh](../../scripts/claude/detect-capabilities.sh) - capability 検出スクリプト
- [../../scripts/bootstrap.sh](../../scripts/bootstrap.sh) - bootstrap wrapper
- [../../docs/guides/bootstrap.md](../../docs/guides/bootstrap.md) - fork 直後のセットアップ手順
