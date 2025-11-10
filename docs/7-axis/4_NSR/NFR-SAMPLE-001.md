---
id: NFR-SAMPLE-001
title: トランザクション同期の耐久性
domain: sample
status: draft
metric: p95<=3s
---

# NFR-SAMPLE-001 トランザクション同期の耐久性

- API 応答の p95 を 3 秒以内に保つ
- 失敗時のリトライ成功率を 99% 以上に保つ
- 監視メトリクスは 1 分未満の粒度でアラート化する
