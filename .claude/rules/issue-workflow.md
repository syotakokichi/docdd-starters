# Issue駆動開発フロー

Issue の計画・管理に関するルールを定義します。

## ルール

### 1. 計画はIssue本文に追記

- コメントではなく **Issue本文を `gh issue edit` で編集**
- 元の内容（背景・目的・受け入れ条件）は残す
- 計画セクションを追記する形式

### 2. 計画済みの表示

- 計画済みのIssueはタイトルに `[実装計画]` を追加
- これにより計画済みかどうか一目で判断できる

```bash
gh issue edit <issue_number> --title "[実装計画] 元のタイトル"
```

### 3. コマンドフロー

```
/issue → /plan → /worktree → /develop → /verify → /review → /pr → /merge
   ↓       ↓         ↓          ↓         ↓         ↓        ↓      ↓
 作成    計画    ブランチ     実装      検証     独立     PR    マージ
                + worktree                       レビュー  作成   + cleanup
```

- `/issue`: Issue作成
- `/plan`: 計画立案 → Issue本文更新（エージェントチーム活用可）
- `/worktree`: worktree 作成 + ブランチ命名（並列開発の起点）
- `/develop`: 実装（進行中ラベル設定）
- `/verify`: 実装検証（品質ゲート + Codex 差分レビュー）
- `/review`: 独立レビュー（実装文脈外）
- `/pr`: PR作成
- `/merge`: マージ + worktree クリーンアップ
- `/discard-worktree`: 未マージ worktree の破棄

> コマンド名 SSOT: [.claude/rules/terminology.md](./terminology.md)
> 旧コマンドからの移行: [docs/guides/migration-from-legacy-commands.md](../../docs/guides/migration-from-legacy-commands.md)

---

## 関連ファイル

- [planning-quality.md](./planning-quality.md) - 計画品質ルール
- [commands/README.md](../commands/README.md) - カスタムコマンド
