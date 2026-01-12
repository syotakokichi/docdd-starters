# Skills - AI実行知識

Claude Code が特定のドメインや技術パターンを適用する際に参照する知識ベースです。

## 目次

| スキル | 説明 |
|--------|------|
| [docdd-workflow](./docdd-workflow/SKILL.md) | DocDD 7軸トレーサビリティの運用ルール |
| [backend-patterns](./backend-patterns/SKILL.md) | FastAPI モジュラーモノリスパターン |
| [frontend-patterns](./frontend-patterns/SKILL.md) | Next.js App Router / Private Folder |
| [testing-patterns](./testing-patterns/SKILL.md) | pytest / Vitest テスト戦略 |
| [traceability-automation](./traceability-automation/SKILL.md) | トレーサビリティマップ活用 |
| [presentation](./presentation/SKILL.md) | Marpプレゼンテーション作成 |

## スキルの使い方

### 自動適用

Claude Code は関連する作業時に自動的にスキルを参照します。

例:
- FastAPI のコードを書く → `backend-patterns` を参照
- テストを追加する → `testing-patterns` を参照
- ドキュメントを更新する → `docdd-workflow` を参照

### 明示的な参照

特定のスキルを適用させたい場合:

```
@skill:backend-patterns に従ってリポジトリを実装してください
```

## スキルの追加

プロジェクト固有のスキルを追加する場合:

1. `skills/<skill-name>/` ディレクトリを作成
2. `SKILL.md` に知識を記述
3. 必要に応じて `references/` に参考資料を配置

### SKILL.md のテンプレート

```markdown
# スキル名

## 概要
このスキルが扱う内容の説明

## 適用条件
このスキルが適用される状況

## パターン
### パターン1
- 説明
- コード例

### パターン2
- 説明
- コード例

## アンチパターン
避けるべき実装パターン

## 参考資料
- 公式ドキュメントへのリンク
- 内部ドキュメントへの参照
```

## 設計思想

- **明示的**: 暗黙のルールより明文化されたルールを優先
- **具体的**: 抽象的な説明より具体的なコード例を提供
- **更新可能**: プロジェクトの成長に合わせて継続的に更新
