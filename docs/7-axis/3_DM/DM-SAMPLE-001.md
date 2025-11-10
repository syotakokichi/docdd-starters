---
id: DM-SAMPLE-001
title: SampleTransactionProjection
domain: sample
status: draft
---

# DM-SAMPLE-001 SampleTransactionProjection

リアルタイム残高更新のために、決済イベントとキャッシュの整合性を表現するドメインモデル。

- `transaction_id`
- `supporter_id`
- `projected_balance`
- `last_synced_at`

## ルール
- API 層では projected balance を返し、非同期確定後に確定残高へ置き換える
- モニタリングでは `last_synced_at` の遅延を検知する
