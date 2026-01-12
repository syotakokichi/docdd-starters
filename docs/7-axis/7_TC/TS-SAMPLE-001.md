---
test_id: TS-SAMPLE-001
type: test_specification
title: リアルタイム残高同期テスト設計
domain: sample
category: functional
status: draft
priority: medium

# トレーサビリティ
br_traces_from:
  - BR-SAMPLE-001
uc_traces_from:
  - UC-SAMPLE-001
dm_traces_from:
  - DM-SAMPLE-001
sr_validates:
  - FR-SAMPLE-001
nsr_validates:
  - NFR-SAMPLE-001
ext_traces:
  - EXT-SAMPLE-001
api_refs:
  - GET /api/sample/supporters/{supporterId}/balance
  - POST /api/sample/transactions
tc_defines:
  - TC-SAMPLE-001-001
  - TC-SAMPLE-001-002

# メタデータ
created: 2024-01-15
updated: 2024-01-15
tags: [docdd, sample, balance]
---

# TS-SAMPLE-001: リアルタイム残高同期テスト設計

DocDD Starters のサンプル TS です。残高が即時に同期されるシナリオと、遅延時のフォールバック表示をカバーします。必要に応じて {PROJECT} 固有のテスト観点に置き換えてください。

## 概要
- フロントエンドは決済直後に projected balance を表示する
- バックエンドは 5 秒以内に確定イベントを push/poll する
- 失敗時はステータスを Pending → Failed に更新する

## テスト範囲
1. `TC-SAMPLE-001-001`: 正常系（即時反映）
2. `TC-SAMPLE-001-002`: 遅延フォールバック通知

## 準備
- {PROJECT} の backend API をローカルで起動
- `docs/testing/traceability/sample_map.json` を更新し、`python scripts/test/validate_traceability_map.py --map docs/testing/traceability/sample_map.json` で検証

## 期待する出力
- pytest 実装時は `pytest_id` をマップに追加
- `python scripts/test/validate_traceability_map.py --map docs/testing/traceability/sample_map.json` で整合性をチェック
