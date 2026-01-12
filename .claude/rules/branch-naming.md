# Branch Naming - ブランチ命名規則

## 形式

```
<type>/issue-<number>-<short-description>
```

## Type

| Type | 用途 |
|------|------|
| `feature` | 新機能開発 |
| `fix` | バグ修正 |
| `hotfix` | 緊急修正（本番直接） |
| `refactor` | リファクタリング |
| `docs` | ドキュメント更新 |
| `test` | テスト追加・修正 |
| `chore` | 雑務（依存更新等） |

## Short Description

- kebab-case を使用
- 3〜5単語程度
- Issue のタイトルを簡潔に要約

## 例

```
feature/issue-123-add-login-page
fix/issue-456-billing-date-calculation
refactor/issue-789-extract-auth-module
docs/issue-101-update-api-docs
test/issue-202-add-payment-tests
chore/issue-303-upgrade-dependencies
```

## 特殊ブランチ

| ブランチ | 用途 |
|---------|------|
| `main` | 本番リリース用 |
| `develop` | 開発統合用（採用している場合） |
| `release/vX.Y.Z` | リリース準備用 |

## ルール

1. **Issue番号必須**: 必ず対応するIssue番号を含める
2. **小文字のみ**: 大文字は使用しない
3. **アンダースコア禁止**: ハイフンのみ使用
4. **短く**: 50文字以内を目安
