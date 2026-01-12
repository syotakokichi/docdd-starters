---
name: traceability-automation
description: |
  トレーサビリティマップを活用した影響範囲検知と
  自動化ワークフローを支援。
---

# トレーサビリティ自動化スキル

## 概要

トレーサビリティマップ（`*_map.json`）を読み込み、
変更の影響範囲を特定する方法を支援する。

## 使い方

- リファクタリング時: マップから影響ドキュメントを特定
- PR作成時: 影響範囲をチェックリスト化
- 新規TC追加時: マップへの登録を確認
- ドキュメント更新時: traces_to/fromの整合性確認

## 詳細

### トレーサビリティマップ構造

```
docs/testing/traceability/
├── sample_map.json         # サンプルドメイン
└── <domain>_map.json       # ドメイン別マップ
```

### マップJSONフォーマット

```json
{
  "domain": "sample",
  "description": "サンプルドメインのトレーサビリティマップ",
  "mappings": {
    "TC-SAMPLE-001-01": {
      "br": ["BR-SAMPLE-001"],
      "uc": ["UC-SAMPLE-001"],
      "dm": ["DM-Model"],
      "sr": ["SR-SAMPLE-001"],
      "api": ["POST /api/items"],
      "pytest_id": "test_create_item",
      "description": "正常系テスト"
    }
  },
  "document_references": {
    "BR-SAMPLE-001": {
      "path": "docs/7-axis/1_BR/BR-SAMPLE-001.md",
      "title": "ビジネス要件",
      "traces_to": ["UC-SAMPLE-001"]
    },
    "UC-SAMPLE-001": {
      "path": "docs/7-axis/2_UC/UC-SAMPLE-001.md",
      "title": "ユースケース",
      "traces_from": ["BR-SAMPLE-001"],
      "traces_to": ["DM-Model", "SR-SAMPLE-001"]
    }
  }
}
```

### 影響範囲検知の手順

1. **変更ファイルのパスを特定**:
   ```bash
   git diff --name-only HEAD~1
   ```

2. **document_referencesから該当ドキュメントIDを逆引き**:
   ```
   変更ファイル: docs/7-axis/4_SR/SR-SAMPLE-001.md
   → ドキュメントID: SR-SAMPLE-001
   ```

3. **traces_from（上流）とtraces_to（下流）を探索**:
   ```
   SR-SAMPLE-001
     ├─ traces_from: [UC-SAMPLE-001, DM-Model]  ← 上流
     └─ traces_to: [API-endpoint, TC-SAMPLE-001]  ← 下流
   ```

4. **影響を受けるドキュメント一覧を出力**

### Claude Codeでの活用

```bash
claude

> sample_map.json を読んで、
> SR-SAMPLE-001 を変更した場合の影響範囲を教えて。
> 更新が必要なドキュメントがあれば教えて。
```

### 検証コマンド

```bash
# マップの整合性検証
python scripts/test/validate_traceability_map.py --map docs/testing/traceability/sample_map.json

# 複数マップを検証（シェルループ）
for f in docs/testing/traceability/*_map.json; do
  python scripts/test/validate_traceability_map.py --map "$f"
done
```

### PR作成時のチェックリスト

変更を含むPR作成時は、以下を確認:

- [ ] 変更したドキュメントのtraces_to/fromが最新か
- [ ] 新規TC追加時はマップに登録したか
- [ ] 検証コマンドがパスするか
- [ ] 影響を受ける下流ドキュメントを更新したか

## 関連ファイル

- [docs/testing/traceability/sample_map.json](../../../docs/testing/traceability/sample_map.json)
- [scripts/test/validate_traceability_map.py](../../../scripts/test/validate_traceability_map.py)
- [skills/docdd-workflow/SKILL.md](../docdd-workflow/SKILL.md)
