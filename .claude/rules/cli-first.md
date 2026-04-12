# CLI-First 原則

## 概要

MCP サーバーより CLI ツール（`gh`, `git`, `make`, `jq` 等）を優先する設計原則。
CLI は透過的でログが残り、hook で制御でき、CI でも再現可能。

---

## 判断フロー

```
操作を実行したい
  │
  ├─ gh / git / make / jq で完結する？
  │    └─ YES → CLI を使う（MCP 不要）
  │
  ├─ CLI では不可能 or 著しく非効率？
  │    └─ YES → MCP 例外リストに該当する？
  │         ├─ YES → MCP を使う
  │         └─ NO  → CLI の組み合わせで代替できないか再検討
  │
  └─ どちらでも可能？
       └─ CLI を優先（hook / CI 再現性のため）
```

---

## CLI で十分な操作

以下の操作は CLI で完結する。MCP を使わない。

| 操作 | CLI コマンド |
|------|-------------|
| Issue 作成・編集・検索 | `gh issue create / edit / list / view` |
| PR 作成・レビュー | `gh pr create / review / merge` |
| ラベル管理 | `gh label create --force` |
| Projects 操作 | `gh project item-add / item-edit` |
| ブランチ操作 | `git branch / checkout / switch` |
| diff / log 確認 | `git diff / log / show` |
| ビルド・テスト | `make test / make shell-lint` |
| JSON 加工 | `jq` |
| ファイル検索 | `find / grep / rg` |

---

## MCP 例外ケース

以下は CLI では実現できない、または著しく非効率なため MCP の使用を許可する。

| MCP サーバー | 用途 | CLI 代替が不十分な理由 |
|-------------|------|----------------------|
| `chrome-devtools` | ブラウザ操作・スクリーンショット | CLI ではブラウザ制御不可 |
| `postgres` | DB クエリ・スキーマ確認 | `psql` は対話的で自動化が煩雑 |
| `aws-docs` | AWS ドキュメント検索 | CLI (`aws`) はドキュメント検索非対応 |
| `terraform` | Terraform state 参照 | `terraform` CLI で可能だが MCP の方が安全 |
| `pencil` | Pencil.dev デザイン操作 | CLI API が存在しない |

---

## ルール

1. **CLI 優先**: `gh` / `git` / `make` で完結する操作は MCP を使わない
2. **例外明示**: MCP を使う場合は、なぜ CLI では不十分かを説明できること
3. **Hook 互換**: CLI 経由の操作は `.claude/hooks/` でガードレールが効く。MCP 経由だと hook をバイパスするリスクがある
4. **CI 再現性**: CLI コマンドは CI workflow にそのまま転用できる。MCP は CI では利用不可

---

## 関連ファイル

- [.claude/hooks/](../hooks/) - CLI 操作に対する PreToolUse / PostToolUse hook
- [completion-quality.md](./completion-quality.md) - 完了品質ルール
