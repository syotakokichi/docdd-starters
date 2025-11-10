---
id: FR-SAMPLE-001
title: 即時残高更新 API
domain: sample
status: draft
---

# FR-SAMPLE-001 即時残高更新 API

- API は 1 秒以内に projected balance を返す
- 更新後 5 秒以内に最終状態をポーリング経由で返却する
- 失敗時はリトライ用の `sync_token` を返す
