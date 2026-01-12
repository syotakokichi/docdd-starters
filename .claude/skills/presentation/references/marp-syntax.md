# Marp構文リファレンス

Marp（Markdown Presentation Ecosystem）の基本構文。

## フロントマター

スライドの設定をYAMLで記述。

```yaml
---
marp: true
theme: minimal
paginate: true
size: 16:9
---
```

### 主要オプション

| オプション | 説明 | 例 |
|-----------|------|-----|
| `marp` | Marp有効化 | `true` |
| `theme` | テーマ名 | `minimal`, `default`, `gaia` |
| `paginate` | ページ番号 | `true` / `false` |
| `header` | ヘッダー | テキストまたは画像 |
| `footer` | フッター | テキスト |
| `size` | スライドサイズ | `16:9` / `4:3` |
| `class` | デフォルトクラス | `title` |
| `backgroundColor` | 背景色 | `#ffffff` |

## スライド区切り

3つのハイフン `---` でスライドを区切る。

```markdown
# スライド1

内容

---

# スライド2

内容
```

## ディレクティブ

### グローバルディレクティブ

フロントマターで設定。全スライドに適用。

### ローカルディレクティブ

HTMLコメントで特定スライドに適用。

```markdown
<!-- _class: title -->
<!-- _backgroundColor: #f5f5f5 -->
<!-- _paginate: false -->
<!-- _header: "" -->
<!-- _footer: "" -->
```

**注意**: `_`（アンダースコア）で始まるとそのスライドのみに適用。

## 画像

### 基本

```markdown
![](path/to/image.jpg)
```

### サイズ指定

```markdown
![width:300px](image.jpg)
![w:300](image.jpg)        <!-- 省略形 -->
![h:200](image.jpg)        <!-- 高さ指定 -->
![w:300 h:200](image.jpg)  <!-- 両方指定 -->
```

### 背景画像

```markdown
![bg](background.jpg)           <!-- 全面背景 -->
![bg left](image.jpg)           <!-- 左半分に配置 -->
![bg right](image.jpg)          <!-- 右半分に配置 -->
![bg left:40%](image.jpg)       <!-- 左40%に配置 -->
![bg contain](image.jpg)        <!-- アスペクト比維持 -->
![bg cover](image.jpg)          <!-- 全面カバー -->
![bg fit](image.jpg)            <!-- フィット -->
![bg 50%](image.jpg)            <!-- サイズ50% -->
```

### 複数背景

```markdown
![bg](image1.jpg)
![bg](image2.jpg)
<!-- 左右に並ぶ -->
```

## テキストスタイル

### 強調

```markdown
**太字**
*イタリック*
~~取り消し線~~
<mark>ハイライト</mark>
```

### リスト

```markdown
- 箇条書き1
- 箇条書き2
  - ネスト

1. 番号付き1
2. 番号付き2
```

### 引用

```markdown
> 引用テキスト
```

### コード

```markdown
`インラインコード`

\`\`\`javascript
const code = "block";
\`\`\`
```

## レイアウト制御

### クラス指定

```markdown
<!-- _class: title -->
```

### HTML使用

```markdown
<div class="columns">
<div>左</div>
<div>右</div>
</div>
```

### スタイル上書き

```markdown
<style scoped>
h1 {
  color: red;
}
</style>
```

## フィット

### 見出しの自動フィット

```markdown
# <!-- fit --> 長いタイトルも自動でフィット
```

### 画像の自動フィット

```markdown
![fit](large-image.jpg)
```

## 出力コマンド

```bash
# プレビュー（ライブリロード）
marp slides.md --preview

# HTML出力
marp slides.md --html -o slides.html

# PDF出力
marp slides.md --pdf -o slides.pdf

# PowerPoint出力
marp slides.md --pptx -o slides.pptx

# テーマ指定
marp docs/slides/my-presentation.md \
  --theme .claude/skills/presentation/references/themes/minimal.css

# 複数ファイル変換
marp --input-dir docs/slides --output-dir docs/slides/output \
  --theme .claude/skills/presentation/references/themes/minimal.css
```

## VSCode設定

Marp for VS Code拡張機能を使用。

`.vscode/settings.json`:
```json
{
  "markdown.marp.themes": [
    "./.claude/skills/presentation/references/themes/minimal.css"
  ]
}
```

プレビュー: `Cmd+Shift+V`（Mac）/ `Ctrl+Shift+V`（Windows）

## 参考リンク

- [Marp 公式サイト](https://marp.app/)
- [Marp CLI](https://github.com/marp-team/marp-cli)
- [Marpit Framework](https://marpit.marp.app/)
- [Theme CSS - Marpit](https://marpit.marp.app/theme-css)
