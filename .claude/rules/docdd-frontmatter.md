# DocDD Frontmatter 規則

## 概要

DocDD（7軸トレーサビリティ）のドキュメントには、必ず frontmatter（YAMLヘッダー）を記述する。

## 必須フィールド

| フィールド | 説明 | 例 |
|-----------|------|-----|
| `title` | ドキュメントタイトル | `契約作成API` |
| `domain` | ドメイン名 | `billing`, `subscription`, `auth` |
| `category` | カテゴリ | `functional`, `non-functional` |
| `status` | ステータス | `draft`, `approved`, `deprecated` |

## 推奨フィールド

| フィールド | 説明 | 例 |
|-----------|------|-----|
| `traces_to` | 前方リンク（下流ドキュメント） | `[API-001, TC-001]` |
| `traces_from` | 後方リンク（上流ドキュメント） | `[UC-001]` |
| `created` | 作成日 | `2025-01-05` |
| `updated` | 更新日 | `2025-01-05` |

## 軸別フォーマット

### BR（ビジネス要求）

```yaml
---
id: BR-001
title: ビジネス要件
domain: sample
category: functional
status: approved
stakeholders:
  - システム管理者
business_goals:
  - 業務効率化
traces_to:
  - UC-001
---
```

### UC（ユースケース）

```yaml
---
id: UC-001
title: ユースケース
domain: sample
category: functional
status: approved
actors:
  - システム
preconditions:
  - 前提条件
traces_from:
  - BR-001
traces_to:
  - DM-Model
  - SR-001
---
```

### SR（システム要件）

```yaml
---
id: SR-001
title: システム要件
domain: sample
category: functional
status: approved
traces_from:
  - UC-001
traces_to:
  - API: endpoint.yaml
  - TC-001
---
```

### TC（テストケース）

```yaml
---
id: TC-001-01
title: テストケース
domain: sample
category: functional
status: approved
test_type: integration
automation:
  framework: pytest
  command: pytest tests/test_sample.py::test_case
traces_from:
  - SR-001
---
```

## 検証コマンド

```bash
# トレーサビリティマップ検証
python scripts/test/validate_traceability_map.py --map docs/testing/traceability/sample_map.json
```

## 関連ファイル

- [docs/7-axis/_templates/](../../docs/7-axis/_templates/) - テンプレート集
- [skills/docdd-workflow/SKILL.md](../skills/docdd-workflow/SKILL.md) - 運用スキル
