# 外部連携テンプレート

---
ext_id: EXT-SYSTEM-001
type: external_integration
title: TODO: 連携名
system: TODO: 外部システム名
status: draft
owners:
  - TODO
created_at: YYYY-MM-DD
updated_at: YYYY-MM-DD
traces_to: []           # 例: [API-XXX-001, TC-XXX-001-001]
traces_from: []         # 例: [FR-XXX-001, NFR-XXX-001]
---

## 連携概要
- 目的: TODO
- データフロー: TODO
- プロトコル: TODO (REST / gRPC / Message Queue など)

## 接続情報
- エンドポイント: TODO
- 認証方式: TODO
- 必要なシークレット: TODO

## メッセージ / フィールド仕様
| フィールド | 型 | 必須 | 説明 |
| ---------- | -- | ---- | ---- |
| TODO       | TODO | yes/no | TODO |

## エラーハンドリング
- ケース: TODO
  - 通知先: TODO
  - リトライ戦略: TODO

## 運用・監視
- 監視項目: TODO
- アラート条件: TODO
- 連絡手順: TODO

## 依存関係
- 内部システム: TODO
- 外部ベンダー窓口: TODO
