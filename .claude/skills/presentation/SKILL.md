---
name: presentation
description: |
  Marp形式でプレゼンテーション資料を生成。
  「スライド」「Marp」「資料作成」「プレゼン」などのリクエストで使用。
---

# プレゼンテーションスキル

## 概要

MarpによるMarkdownプレゼンテーション作成を支援するスキル。

**重要**: このスキルはテンプレートです。実際のプロジェクトでは独自のブランドテーマを作成して差し替えてください。

## 使い方

| シーン | 参照 |
|--------|------|
| 新規スライド作成 | `/slide` コマンド |
| レイアウト選択 | [layout-patterns.md](references/layout-patterns.md) |
| Marp構文 | [marp-syntax.md](references/marp-syntax.md) |

## テーマ

### Minimal Theme（プレースホルダー）

```yaml
---
marp: true
theme: minimal
paginate: true
size: 16:9
---
```

**スライドの置き場所**: `docs/slides/` を推奨

### カスタムテーマの作成

独自ブランドのテーマを作成する場合:

1. `references/themes/` に CSS ファイルを作成
2. カラーパレット、フォント、ロゴを定義
3. `.vscode/settings.json` にテーマパスを追加

```json
{
  "markdown.marp.themes": [
    "./.claude/skills/presentation/references/themes/your-theme.css"
  ]
}
```

### 利用可能なレイアウトクラス

| クラス | 用途 |
|--------|------|
| `title` | タイトルスライド |
| `section` | セクション区切り |
| `content` | 通常コンテンツ |
| `image-right` | 画像右配置（50:50） |
| `comparison` | Before/After比較 |
| `summary` | まとめ |

## Marp CLIコマンド

```bash
# インストール
npm install -g @marp-team/marp-cli

# プレビュー（リポジトリルートから実行）
marp docs/slides/my-presentation.md --preview \
  --theme .claude/skills/presentation/references/themes/minimal.css

# HTML出力
marp docs/slides/my-presentation.md --html \
  --theme .claude/skills/presentation/references/themes/minimal.css \
  --output docs/slides/my-presentation.html

# PDF出力
marp docs/slides/my-presentation.md --pdf \
  --theme .claude/skills/presentation/references/themes/minimal.css \
  --output docs/slides/my-presentation.pdf
```

## VSCode設定

プロジェクトの `.vscode/settings.json` にテーマパスを追加:

```json
{
  "markdown.marp.themes": [
    "./.claude/skills/presentation/references/themes/minimal.css"
  ]
}
```

VSCodeで「Marp for VS Code」拡張機能をインストールすると、プレビュー時に自動適用される。

## 関連ファイル

- [references/themes/minimal.css](references/themes/minimal.css) - ミニマルテーマ
- [references/layout-patterns.md](references/layout-patterns.md) - レイアウトパターン詳細
- [references/marp-syntax.md](references/marp-syntax.md) - Marp構文リファレンス
- [../../commands/slide.md](../../commands/slide.md) - /slide コマンド
