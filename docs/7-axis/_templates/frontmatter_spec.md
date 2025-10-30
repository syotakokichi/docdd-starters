# Frontmatter 仕様

すべての 7-axis ドキュメントは先頭に YAML frontmatter を定義します。  
以下は共通で推奨されるフィールドです。プロジェクトに合わせて追加・削除してください。

```yaml
---
{id_field}: {ID}               # 軸に応じた識別子 (BR / UC / DM …)
type: {document_type}         # ドキュメント種別 (例: business_requirement)
title: {タイトル}              # ドキュメントの表題
domain: {ドメイン}             # 対象領域 (payment, auth など)
category: functional|non-functional
status: draft|approved|deprecated
tags: [draft]                 # 任意のタグ
owners:                       # ドキュメント責任者
  - {owner_name}
created_at: YYYY-MM-DD
updated_at: YYYY-MM-DD
traces_to: [{ID}]             # 下位ドキュメントへの参照
traces_from: [{ID}]           # 上位/横断ドキュメントからの参照
additional_fields:
  tc_defines: [TC-XXX-001-001]
  sr_validates: [FR-XXX-001]  # テスト仕様で検証する要件
  automation:                 # 自動化レベルや実行コマンドを管理
    level: manual|semi|auto
    command: "pytest -k xxx"
---
```

- `traces_to` / `traces_from` は双方向で整合するよう必ず更新します。
- フィールド名は必要に応じて増やして構いません（例: `metrics`, `actors`, `api_defines`）。
- YAML 内でコメントを残す場合は `#` を活用し、テンプレ生成後は削除して構いません。
- TS / TC では `tc_defines`, `test_axes`, `automation` などテスト固有のフィールドを活用し、CI で参照できる情報を残すと便利です。
