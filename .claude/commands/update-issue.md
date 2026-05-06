---
description: GitHub Issue 本文を実装中の仕様変更・方針変更に合わせて更新します。
argument-hint: "<issue-number>"
disable-model-invocation: true
---
GitHub Issue $ARGUMENTS の本文を実装変更に合わせて更新してください。

実装中に仕様変更や方針変更があった場合、GitHub Issue の本文を現状に合わせて更新します。

---

## 手順

1. **現在のIssue内容を取得**
   ```bash
   gh issue view $ARGUMENTS --json body,title
   ```
   - 既存の内容を確認し、何を更新すべきか把握

2. **変更点を特定**

   会話履歴から以下を特定:
   - 当初計画から変更された仕様・方針
   - 追加・削除された実装項目
   - 設計上の決定事項（ADR相当）

3. **Issue本文を更新**

   元の内容（背景・目的・受け入れ条件）は残しつつ、以下を追記・更新：

   ```markdown
   ---

   ## 変更履歴
   - YYYY-MM-DD: [変更内容の要約]

   ## 計画からの変更点
   [当初計画と異なる部分を明記]

   ## 追加の重要ポイント
   [実装中に判明した注意点]

   ## 実装タスク（更新）
   - [x] 完了した項目
   - [ ] 残タスク

   ## 設計決定事項
   [実装中に決定した重要な事項]
   ```

4. **更新を適用**

   長い内容の場合は一時ファイルを使用：
   ```bash
   # 1. 一時ファイルに書き出し
   cat > /tmp/issue_$ARGUMENTS_update.md << 'EOF'
   [更新後の内容]
   EOF

   # 2. Issue更新
   gh issue edit $ARGUMENTS --body-file /tmp/issue_$ARGUMENTS_update.md
   ```

5. **コメント追加（任意）**

   大きな変更の場合は、変更理由をコメントとして追加：
   ```bash
   gh issue comment $ARGUMENTS --body "本文を更新しました: [変更理由の要約]"
   ```

---

## 注意事項

- 既存の内容（背景・目的・受け入れ条件）は削除しない
- 変更履歴セクションで何が変わったかを明記
- `/plan` で立案した計画との差分を明確にする
- 日本語で記述

---

## 次のステップ

Issue 本文を最新の実装状態に同期した。

```
---
✨ **このセッションで進んだこと**
- Issue #<N> 本文更新（変更履歴 / 計画からの変更点 / 設計決定事項を追記）
- 既存セクション（背景・目的・受け入れ条件）は保全

🎯 **これによって変わること**
- 実装中の判断が Issue 本文に反映され、`/verify` `/review` `/pr` で参照する内容が最新化される
- 計画と実装の乖離が `/develop` のサマリーと突き合わせ可能になる

📋 **次のステップ**
- Issue #<N>（本文最新化済み）
- 実装続行なら `/develop <N>`、検証フェーズなら `/verify <N>`
---
```

コピペ用:

```bash
/develop <N>
```

Remember to use the GitHub CLI (`gh`) for all GitHub-related tasks.
