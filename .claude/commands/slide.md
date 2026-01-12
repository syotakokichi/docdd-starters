スライド作成の壁打ちを行います。

## ヒアリング

以下の質問に答えてもらい、最適なスライド構成を提案してください。

### 1. 用途

- 営業・商談
- 社内報告
- 勉強会・発表
- 提案・企画
- その他

### 2. 対象者

- 誰に見せるか
- 相手の知識レベル
- 相手が求めていること

### 3. 時間

- 何分で話すか
- じっくり or さっと

### 4. ゴール

- 見た人にどうなってほしいか
- 何を持ち帰ってほしいか

## 提案フォーマット

ヒアリング後、以下を提案してください：

```markdown
## 提案

### 構成案
- 枚数: X枚
- 構成: [各スライドの内容]

### 推奨レイアウト
- タイトル: `title`
- セクション区切り: `section`
- 本文: デフォルト
- まとめ: `summary`
```

## 利用可能なレイアウト

| クラス | 用途 |
|--------|------|
| `title` | タイトルスライド |
| `section` | セクション区切り |
| `image-right` | 画像右配置 |
| `comparison` | Before/After比較 |
| `summary` | まとめ |

## スライド生成

ヒアリング後、Marp形式でスライドを生成：

```markdown
---
marp: true
theme: minimal
paginate: true
size: 16:9
---

<!-- _class: title -->

# タイトル

副題

---

## 内容

- ポイント1
- ポイント2

---

<!-- _class: summary -->

# まとめ

...
```

## 関連スキル

- [presentation](../skills/presentation/SKILL.md) - プレゼンテーションスキル
- [layout-patterns](../skills/presentation/references/layout-patterns.md) - レイアウト詳細
- [marp-syntax](../skills/presentation/references/marp-syntax.md) - Marp構文

## 生成ルール

スライド生成時に守ること：

### 1. タイトルと内容の間隔

通常スライドは `## 見出し` で始める。

```markdown
# スライドタイトル

## 最初のセクション（必須）

内容...
```

### 2. ロゴ配置（任意）

ブランドロゴがある場合は各スライドに配置:

```markdown
<img src="path/to/logo.png" class="logo">
```

### 3. スライド配置

- 生成したスライドは `docs/slides/` に配置
- ファイル名: `YYYY-MM-DD_タイトル.md`

## その他

- テーマは `minimal`（デフォルト）または独自テーマを使用
- ページ番号は `paginate: true` で自動表示
- 強調には `<mark>テキスト</mark>` を使用
