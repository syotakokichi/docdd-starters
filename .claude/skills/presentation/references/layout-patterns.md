# レイアウトパターン

Marpテーマで使用可能な基本レイアウト。

> **Note**: これは汎用テンプレートです。独自ブランドに合わせてカスタマイズしてください。

## 1. タイトルスライド (`title`)

プレゼンテーションの表紙。

```markdown
<!-- _class: title -->

# プレゼンのタイトル

副題やドキュメントタイトル

登壇者の氏名
```

**特徴**:
- 中央寄せ
- ページ番号なし
- ロゴ配置可能

**カスタマイズ例**:
```markdown
<!-- _class: title -->

<style scoped>
.logo {
  position: absolute;
  top: 40px;
  left: 40px;
  width: 150px;
}
</style>

<img src="path/to/logo.png" class="logo">

# タイトル
```

---

## 2. セクション区切り (`section`)

新しいセクションの開始。

```markdown
<!-- _class: section -->

# セクション名

サブタイトル（任意）
```

**特徴**:
- 背景色変更可能
- 大きい見出し
- 中央寄せ

---

## 3. 通常スライド (デフォルト)

標準的なコンテンツスライド。

```markdown
# スライドタイトル

## 最初のセクション

- ポイント1
- ポイント2
- ポイント3

補足テキスト
```

**注意**:
- `## 見出し` で始めると適切な余白が確保される
- 直接リストやテーブルで始めるとタイトルと詰まる

---

## 4. 画像右配置 (`image-right`)

テキストと画像を50:50で並べる。

```markdown
<!-- _class: image-right -->

# タイトル

説明テキスト

- ポイント1
- ポイント2

![bg right](image.jpg)
```

**特徴**:
- 左半分: テキスト
- 右半分: 画像
- `bg left:40%` で比率調整可能

---

## 5. 比較レイアウト (`comparison`)

Before/After や 2つの選択肢を比較。

```markdown
<!-- _class: comparison -->

# 比較タイトル

<div class="columns">
<div>

## Before
- 問題点1
- 問題点2

</div>
<div>

## After
- 改善点1
- 改善点2

</div>
</div>
```

**CSS定義**:
```css
.comparison .columns {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 40px;
}
```

---

## 6. まとめ (`summary`)

プレゼンの締めくくり。

```markdown
<!-- _class: summary -->

# まとめ

## 本日のポイント

1. **ポイント1**: 説明
2. **ポイント2**: 説明
3. **ポイント3**: 説明

## 次のステップ

- アクション1
- アクション2
```

---

## 7. 引用・出典

出典を明記するパターン。

```markdown
# データ分析結果

> 重要な引用やデータ

<div class="citation">[出典] 調査レポート 2025</div>
```

**CSS定義**:
```css
.citation {
  font-size: 0.7em;
  color: #666;
  margin-top: 20px;
}
```

---

## カスタマイズのヒント

### ロゴの配置

```css
.logo {
  position: absolute;
  top: 30px;
  right: 30px;
  width: 100px;
}
```

### カラーパレット

テーマCSSで定義:
```css
:root {
  --primary: #333333;
  --secondary: #666666;
  --accent: #0066cc;
  --background: #ffffff;
}
```

### フォント

```css
section {
  font-family: 'Noto Sans JP', sans-serif;
}
```

## 関連ファイル

- [marp-syntax.md](./marp-syntax.md) - Marp構文
- [themes/minimal.css](./themes/minimal.css) - ミニマルテーマ
