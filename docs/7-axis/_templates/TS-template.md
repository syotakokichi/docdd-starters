# テスト設計書テンプレート

---
test_id: TS-XXX-001               # TODO: テスト設計書ID (例: TS-PAY-001)
type: test_specification
title: TODO: テスト設計書タイトル
domain: TODO
status: draft
priority: high
owners:
  - TODO
created_at: YYYY-MM-DD
updated_at: YYYY-MM-DD
traces_to: []           # 例: [FR-XXX-001, NFR-XXX-001]
traces_from: []         # 例: [BR-XXX-001, UC-XXX-001]
tc_defines:
  - TC-XXX-001-001    # TODO: TS の ID に続く 3 桁連番で管理
  - TC-XXX-001-002
tc_naming_note: |
  テストケースIDは `TC-<TS番号>-<3桁連番>` 形式を推奨。
  例: TS-XXX-001 に紐づくケースは TC-XXX-001-001, TC-XXX-001-002 ...
tags: [test]
---

# 概要
- TODO: テストの目的・背景
- TODO: スコープと除外範囲

# テスト対象
## 対象コンポーネント
- TODO

## 関連 API / 外部連携
- TODO

# テスト観点とケース一覧
| テストケースID | 観点 | シナリオ | 自動化レベル | 備考 |
| -------------- | ---- | -------- | ------------ | ---- |
| TC-XXX-001-001 | TODO | TODO     | manual       | TODO |
| TC-XXX-001-002 | TODO | TODO     | automated    | TODO |

# テスト環境
- 環境: TODO (local / staging など)
- データセット: TODO
- 外部サービス条件: TODO

# 注意事項
- TODO

# 参考資料
- TODO: 関連ドキュメントやダッシュボードリンク
