# Commit Messages - コミットメッセージ規則

## 形式

Conventional Commits 形式を採用します。

```
<type>(<scope>): <subject>

<body>

<footer>
```

## Type

| Type | 用途 |
|------|------|
| `feat` | 新機能追加 |
| `fix` | バグ修正 |
| `docs` | ドキュメントのみの変更 |
| `style` | コードの意味に影響しない変更（空白、フォーマット等） |
| `refactor` | バグ修正や機能追加を伴わないコード変更 |
| `perf` | パフォーマンス改善 |
| `test` | テストの追加・修正 |
| `chore` | ビルドプロセスや補助ツールの変更 |

## Scope（任意）

変更対象のモジュールやコンポーネントを括弧内に記載します。

例:
- `feat(auth): add JWT refresh token`
- `fix(billing): correct invoice calculation`
- `docs(readme): update setup instructions`

## Subject

- 先頭は小文字
- 末尾にピリオドを付けない
- 命令形で記述（"add" not "added"）
- 50文字以内を目安

## Body（任意）

- 変更の理由や背景を記述
- 72文字で改行

## Footer

Claude Code で生成したコミットには以下を付与:

```
Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

## 例

```
feat(frontend): add balance status component

残高ステータスを表示するReactコンポーネントを追加。
リアルタイム更新に対応し、残高変動時にアニメーション表示。

Closes #123

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

```
fix(backend): correct date calculation in billing

請求日計算で月末日が正しく処理されない問題を修正。
31日がない月の場合、翌月1日にずれる問題を解消。

Fixes #456

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```
