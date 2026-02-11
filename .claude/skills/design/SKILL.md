# Design Skill - Pencil.dev 連携によるUI設計

## 概要

Pencil.dev を活用して UI 設計を行い、実装へ繋げるワークフローを定義する。

## Pencil.dev とは

Pencil.dev は AI を活用した UI デザインツール。プロンプトからワイヤーフレームやモックアップを生成し、フロントエンド実装の基盤として活用できる。

## ワークフロー

### 1. UI 設計が必要な場面

以下のケースで Pencil.dev を活用:

- 新しい画面・ページの追加
- 既存 UI の大幅な変更
- ユーザーフロー全体の設計
- コンポーネントライブラリの拡充

### 2. 設計フロー

```
要件定義（Issue）
  ↓
Pencil.dev でモックアップ作成
  ↓
ユーザーとレビュー・フィードバック
  ↓
デザイン確定
  ↓
フロントエンド実装（/4 コマンド）
```

### 3. Pencil.dev → 実装の橋渡し

#### デザイントークンの抽出

Pencil.dev のデザインから以下を抽出:

- カラーパレット → CSS 変数 / Tailwind 設定
- タイポグラフィ → フォント設定
- スペーシング → レイアウトルール
- コンポーネント構造 → React コンポーネント設計

#### コンポーネント分割

モックアップを見て、以下の観点で分割:

1. **再利用可能な UI コンポーネント** → `src/components/ui/`
2. **機能固有のコンポーネント** → `src/components/features/`
3. **ページ固有のコンポーネント** → `app/{route}/_components/`

### 4. 計画コマンド（/2）との連携

`/2` で計画立案する際、UI 変更を伴う Issue では:

1. Pencil.dev でモックアップを作成
2. モックアップの URL または スクリーンショットを Issue に添付
3. 実装計画にコンポーネント分割を記載

## 命名規則

- デザインファイル: `{画面名}-{バージョン}` (例: `dashboard-v1`)
- コンポーネント名: PascalCase (例: `BalanceCard.tsx`)
- ファイル命名: `.claude/rules/file-naming.md` に準拠

## 関連ファイル

- [frontend-patterns](../frontend-patterns/SKILL.md) - フロントエンド実装パターン
- [file-naming](../../rules/file-naming.md) - ファイル命名規則
