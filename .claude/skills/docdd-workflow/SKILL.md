# DocDD Workflow - 7軸トレーサビリティ運用スキル

## 概要

Doc Driven Development (DocDD) における 7軸トレーサビリティモデルの運用ルールを定義します。

## 7軸構造

```
BR → UC → DM → SR/NSR → EXT → API → TC
```

| 軸 | 名称 | 説明 |
|----|------|------|
| BR | Business Requirement | ビジネス要件・課題定義 |
| UC | Use Case | ユースケース・操作シナリオ |
| DM | Domain Model | ドメインモデル・データ構造 |
| SR | System Requirement | 機能要件 |
| NSR | Non-functional Requirement | 非機能要件 |
| EXT | External Integration | 外部システム連携 |
| API | API Specification | API定義・インターフェース |
| TC | Test Case | テストケース |
| TS | Test Specification | テスト設計書（TCをグループ化） |

## ドキュメント作成フロー

### 1. 新機能追加時

```
1. BR を作成/更新（ビジネス価値の定義）
2. UC を作成（ユーザー操作シナリオ）
3. DM を更新（必要に応じて）
4. SR/NSR を作成（実装仕様）
5. API を定義（エンドポイント仕様）
6. TS/TC を作成（テスト設計）
7. トレーサビリティマップを更新
```

### 2. バグ修正時

```
1. 関連する TC を確認
2. TC から SR/API を辿って影響範囲を特定
3. 修正後、TC を更新/追加
4. トレーサビリティマップを更新
```

## ID 命名規則

| 種別 | 形式 | 例 |
|------|------|-----|
| BR | BR-XXX | BR-001 |
| UC | UC-XXX | UC-001 |
| SR | SR-XXX | SR-001 |
| API | API-XXX | API-001 |
| TS | TS-{DOMAIN}-XXX | TS-BILLING-001 |
| TC | TC-{TS-ID}-XXX | TC-BILLING-001-001 |

## Frontmatter 構造

### TS (テスト設計書)

```yaml
---
id: TS-SAMPLE-001
title: サンプル機能テスト設計
domain: sample
status: draft  # draft | review | approved | deprecated
version: "1.0"
traces_to:
  - SR-001
  - UC-001
created: 2024-01-01
updated: 2024-01-15
---
```

### TC (テストケース)

```yaml
---
test_case_id: TC-SAMPLE-001-001
title: 正常系テスト
domain: sample
priority: high  # critical | high | medium | low
automation:
  status: automated  # automated | manual | pending
  command: npm run test:unit -- balance-status.test.ts
traces_to:
  - TS-SAMPLE-001
  - SR-001
---
```

## トレーサビリティマップ

`docs/testing/traceability/<domain>_map.json` で管理:

```json
{
  "domain": "sample",
  "version": "1.0.0",
  "mappings": [
    {
      "test_case_id": "TC-SAMPLE-001-001",
      "title": "残高即時反映テスト",
      "traces_to": ["SR-001", "UC-001"],
      "automation": {
        "command": "pytest tests/backend/unit/test_balance.py"
      }
    }
  ],
  "document_references": {
    "TS-SAMPLE-001": "docs/7-axis/7_TC/TS-SAMPLE-001.md",
    "SR-001": "docs/7-axis/4_SR/SR-001.md"
  }
}
```

## 検証コマンド

```bash
# トレーサビリティマップの整合性チェック
python scripts/test/validate_traceability_map.py \
  --map docs/testing/traceability/sample_map.json

# 全マップの検証
make traceability
```

## アンチパターン

### NG: トレースなしのドキュメント

```yaml
---
id: SR-999
title: なんとなく追加した要件
# traces_to がない
---
```

### OK: トレース付きドキュメント

```yaml
---
id: SR-999
title: ユーザー認証要件
traces_to:
  - BR-001
  - UC-001
verified_by:
  - TC-AUTH-001-001
---
```

## 参考資料

- [7-axis テンプレート](../../../docs/7-axis/_templates/)
- [OPERATIONS_GUIDE.md](../../../docs/7-axis/OPERATIONS_GUIDE.md)
- [サンプル TS](../../../docs/7-axis/7_TC/TS-SAMPLE-001.md)
