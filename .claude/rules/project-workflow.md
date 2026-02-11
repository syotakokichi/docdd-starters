# Project Workflow - GitHub Projects 連携ルール

## 概要

GitHub Projects を使用してタスクのステータスを管理する。
各コマンド実行時に、対応する Issue のステータスを自動更新する。

## ステータス定義

| ステータス | 説明 |
|-----------|------|
| Backlog | 未着手・バックログ |
| Ready | 計画済み・着手可能 |
| In Progress | 実装中 |
| Done | 完了 |

## コマンドごとのステータス遷移

| コマンド | 説明 | Projects Status |
|---------|------|-----------------|
| `/1` | Issue作成 | → Backlog |
| `/2` | 計画立案（Issue本文を編集） | → Ready |
| `/3` | ブランチ作成 | → In Progress |
| `/4` | 実装開始 | In Progress |
| `/5` | 実装検証 | In Progress |
| `/6` | PR作成 | In Progress |
| `/7` | マージ後クリーンアップ | → Done |

## ラベルによるステータス管理

GitHub Projects 未設定の場合は、ラベルでステータスを管理:

```bash
# 進行中に設定
gh issue edit <number> --remove-label "status:todo" --add-label "status:in-progress"

# 完了に設定
gh issue edit <number> --remove-label "status:in-progress" --add-label "status:done"
```

## 運用ルール

1. **自動更新**: 各コマンドがステータスを自動的に更新
2. **手動更新不要**: コマンドフローに従えば手動更新は不要
3. **一貫性**: 全 Issue が同じステータス遷移を経る
4. **可視性**: Projects ボードで全タスクの進捗を一覧表示

## 関連ファイル

- [issue-workflow.md](./issue-workflow.md) - Issue駆動開発フロー
- [commands/README.md](../commands/README.md) - カスタムコマンド
