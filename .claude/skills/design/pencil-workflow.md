# Pencil MCP ワークフロー & リファレンス

Pencil MCP ツールを使った具体的な設計・実装ワークフローのリファレンス。
基本的なデザインスキル情報は [SKILL.md](./SKILL.md) を参照。

> **Note**: コンポーネントカタログとページテンプレートはプロジェクト固有です。初回セットアップ時に記録してください。

---

## MCP ツールカタログ

Pencil アプリ起動時に Claude Code に自動接続される。各ツールの詳細な操作構文は MCP サーバーのツール定義を参照。

### エディタ・ドキュメント操作

| ツール | 用途 | 使用タイミング |
|--------|------|----------------|
| `get_editor_state` | 現在のファイル・選択状態を取得 | タスク開始時に状況把握 |
| `open_document` | .pen ファイルを開く / `new` で新規作成 | ファイル操作時 |

### 読み取り・検索

| ツール | 用途 | 使用タイミング |
|--------|------|----------------|
| `batch_get` | ノード検索（patterns）・ID 指定一括取得（nodeIds） | 構造把握、コンポーネント一覧取得 |
| `get_screenshot` | ノードのスクリーンショット取得 | デザイン検証、コード生成の参考 |
| `snapshot_layout` | 計算済みレイアウト矩形の確認 | レイアウト問題検出、挿入位置決定 |
| `find_empty_space_on_canvas` | キャンバス上の空きスペース検索 | 新規画面・テンプレート配置時 |
| `search_all_unique_properties` | ノードツリー内のユニークプロパティ検索 | スタイル監査、不整合検出 |

### 設計・編集

| ツール | 用途 | 使用タイミング |
|--------|------|----------------|
| `batch_design` | 一括設計操作（最大 25 操作/回） | 画面構築・修正時 |
| `replace_all_matching_properties` | プロパティ一括置換 | テーマ変更、スタイルリファクタ |

#### `batch_design` 操作一覧

| 操作 | 構文 | 用途 |
|------|------|------|
| Insert | `foo=I("parent", {...})` | 新規ノード挿入 |
| Copy | `baz=C("nodeId", "parent", {...})` | ノードコピー（テンプレート複製） |
| Update | `U("nodeId", {...})` | プロパティ更新 |
| Replace | `foo2=R("nodeId", {...})` | ノード置換 |
| Move | `M("nodeId", "parent", index)` | ノード移動 |
| Delete | `D("nodeId")` | ノード削除 |
| Generate Image | `G("nodeId", "ai", "prompt")` | AI 画像生成 |

### Variables（デザイントークン）

| ツール | 用途 | 使用タイミング |
|--------|------|----------------|
| `get_variables` | 現在の Variables・テーマ定義を取得 | トークン同期時、現状把握 |
| `set_variables` | Variables・テーマを設定（`replace: false` でマージ） | トークン更新・追加時 |

### スタイルガイド・ガイドライン

| ツール | 用途 | 使用タイミング |
|--------|------|----------------|
| `get_guidelines` | ガイドライン取得（`code` / `table` / `tailwind` / `landing-page`） | コード生成、テーブル設計時 |
| `get_style_guide_tags` | 利用可能なスタイルガイドタグ一覧 | デザイン方向性検討時 |
| `get_style_guide` | タグ指定でスタイルガイド取得 | デザインインスピレーション取得時 |

---

## コンポーネントカタログ（プロジェクト固有）

> **初回セットアップ**: `batch_get` で `patterns: [{ reusable: true }]` を実行し、返却されたコンポーネントを以下の形式で記録してください。新規コンポーネント追加時にも都度更新します。

### UI Kit コンポーネント

| カテゴリ | コンポーネント | Node ID | 備考 |
|---------|-------------|---------|------|
| <!-- batch_get の結果を記録 --> | | | |

### プロジェクト固有コンポーネント

| コンポーネント名 | Node ID | 用途 |
|----------------|---------|------|
| <!-- reusable: true で作成したプロジェクト固有コンポーネントを記録 --> | | |

### コンポーネントの reusable 化

```javascript
// 既存ノードをコンポーネント化
U("nodeId", { reusable: true })

// コンポーネントインスタンスの配置（ref で参照）
instance=I("parent", { ref: "componentNodeId", ... })
```

---

## ページテンプレートカタログ（プロジェクト固有）

> **テンプレート作成**: よく使う画面パターンをテンプレート化し、以下の形式で記録してください。テンプレートのデータは汎用プレースホルダーにします（「山田太郎」→「氏名」等）。

| テンプレート名 | Node ID | サイズ | 用途 |
|---------------|---------|--------|------|
| <!-- テンプレート作成後に記録 --> | | | |

### テンプレートパターン例

| パターン | 画面幅 | 構成要素 |
|---------|--------|---------|
| 一覧ページ | 1440px (PC) | テーブル + 検索 + ページネーション |
| 詳細ページ | 1440px (PC) | ヘッダー + タブ + アクションボタン群 |
| フォームページ | 375px (スマホ) / 1440px (PC) | 入力フィールド + バリデーション + 送信 |
| モーダル | 480px | Dialog + フォーム + 確認ボタン |
| 認証画面 | 1440px (PC) | センタリングカード + ロゴ + フォーム（サイドバーなし） |
| 結果画面 | 375px (スマホ) | アイコン + メッセージ + CTA ボタン |

### テンプレート使用方法

`C()` 操作でテンプレートを複製し、新画面を作成:

```javascript
// テンプレートをコピーして新画面を作成
newScreen=C("<TEMPLATE_NODE_ID>", document, {
  name: "新しい画面名",
  positionDirection: "right",
  positionPadding: 100
})

// コピー後にテキスト・プロパティを実データに置き換え
U(newScreen+"/titleNodeId", { characters: "実際の画面タイトル" })
```

---

## デザインワークフロー

### ワークフロー 1: 既存画面の修正

```
1. 対象画面の特定
   → get_editor_state で現在の状態を取得
   → batch_get で対象ノードを検索

2. 現状のスクリーンショット取得
   → get_screenshot で修正前の状態を記録

3. 修正の実行
   → batch_design で変更操作を実行
   （U: 更新, R: 置換, I: 追加, D: 削除, M: 移動）

4. 修正結果の検証
   → get_screenshot で修正後の状態を確認
   → snapshot_layout でレイアウト崩れがないか確認

5. コード生成・差分適用
   → get_guidelines(topic: "code") でガイドライン取得
   → get_variables でデザイントークン取得
   → 変更部分のみを既存コードに反映
```

### ワークフロー 2: 新規画面の作成

```
1. テンプレートの選択・コピー
   → ページテンプレートカタログから最適なテンプレートを選択
   → C() でテンプレートをコピー

2. レイアウトのカスタマイズ
   → U() でダミーデータを実データに置き換え
   → I() でコンポーネントカタログからコンポーネントを配置

3. コンテンツ・画像の追加
   → U() でテキスト・プロパティを設定
   → G() で AI 画像を生成・配置（必要な場合）

4. 検証
   → get_screenshot でデザイン確認
   → snapshot_layout でレイアウト確認

5. コード生成・実装
   → get_guidelines(topic: "code") を取得
   → get_guidelines(topic: "tailwind") を取得（Tailwind 使用時）
   → get_variables でデザイントークン取得
   → フロントエンド実装（frontend-patterns スキル参照）
```

---

## Variables 活用 Tips

### CSS 変数へのマッピング

```css
/* get_variables の結果を CSS 変数に変換 */
:root {
  --primary: /* Pencil Variable: --primary の値 */;
  --background: /* Pencil Variable: --background の値 */;
  --foreground: /* Pencil Variable: --foreground の値 */;
}
```

### Variables の同期方法

```
Code → Pencil: set_variables で globals.css の値を Pencil に反映
Pencil → Code: get_variables で Pencil の値を取得し globals.css に反映
```

- `set_variables` の `replace: false`（マージモード）で既存値を壊さず追加・更新が可能
- ブランドカラー等の真実源（Single Source of Truth）を1箇所に定め、双方を同期する運用を推奨

### コンポーネントでの Variables 参照

- `fill: "$--primary"` のようにプロパティ値で Variables を参照すると、トークン変更時に自動反映
- ハードコードした色は Variables に置き換えることを推奨

---

## 関連ファイル

- [SKILL.md](./SKILL.md) — デザインスキル本体
- [frontend-patterns](../frontend-patterns/SKILL.md) — フロントエンド実装パターン
- [file-naming](../../rules/file-naming.md) — ファイル命名規則
