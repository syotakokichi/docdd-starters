# Rules - コーディング規約・命名規則

Claude Code が従うべきコーディング規約と命名規則を定義します。

## 目次

| ルール | 説明 |
|--------|------|
| [commit-messages.md](./commit-messages.md) | コミットメッセージの形式 |
| [branch-naming.md](./branch-naming.md) | ブランチ命名規則 |
| [file-naming.md](./file-naming.md) | ファイル・ディレクトリ命名規則 |
| [planning-quality.md](./planning-quality.md) | 計画立案時の品質基準 |
| [docdd-frontmatter.md](./docdd-frontmatter.md) | DocDD frontmatter検証ルール |
| [issue-workflow.md](./issue-workflow.md) | Issue駆動開発のフロー |
| [test-fixtures.md](./test-fixtures.md) | DBフィクスチャのCI対応ルール |
| [agent-teams.md](./agent-teams.md) | エージェントチーム運用ルール |
| [project-workflow.md](./project-workflow.md) | GitHub Projects 連携ルール |
| [completion-quality.md](./completion-quality.md) | 完了品質ルール |
| [issue-sizing.md](./issue-sizing.md) | Issue サイジングルール |
| [brand.md](./brand.md) | ブランドガイドライン（テンプレート） |

## 基本原則

1. **一貫性**: プロジェクト全体で同じ命名規則を適用
2. **可読性**: 名前から目的が推測できるようにする
3. **検索性**: grep/検索で見つけやすい命名にする
4. **シンプルさ**: 不必要に長い名前は避ける

## 適用範囲

これらのルールは Claude Code がコード生成・修正を行う際に自動的に適用されます。
プロジェクト固有のルールがある場合は、このディレクトリにファイルを追加してください。
