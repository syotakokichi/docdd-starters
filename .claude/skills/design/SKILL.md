---
name: design
description: |
  Pencil.dev MCP 連携を活用した UI 設計ワークフロー。
  デザイントークン管理、コンポーネント設計、画面テンプレートの運用を支援。
---

# Design Skill - Pencil.dev MCP 連携によるUI設計

## 概要

Pencil.dev MCP 統合を活用した UI 設計ワークフロー。デザインから実装まで一貫した品質を確保する。

**対象範囲**:
- Pencil.dev MCP ツールを使った画面設計・修正
- デザイントークン（Variables）の管理・同期
- コンポーネントベースの画面構築
- テンプレートを活用した新規画面の高速作成

**非ゴール**:
- 画面レイアウトの実装パターン（→ [frontend-patterns](../frontend-patterns/SKILL.md)）
- バックエンド API 連携（→ [backend-patterns](../backend-patterns/SKILL.md)）

> **Note**: コンポーネント ID やテンプレート ID はプロジェクト固有です。初回セットアップ後に [pencil-workflow.md](./pencil-workflow.md) のカタログを記録してください。

## Pencil.dev セットアップ

### VS Code 拡張

```
ext install highagency.pencildev
```

### MCP 接続確認

Pencil アプリ起動時に Claude Code へ自動接続される。接続を確認:

```
# MCP サーバー一覧に pencil が表示されること
claude mcp list
```

### .pen ファイル配置

```
apps/frontend/
├── design.pen            # メインデザインファイル（推奨: 1プロジェクト1ファイル）
└── src/components/       # 実装コンポーネント
```

- `design.pen` にすべての画面・テンプレート・コンポーネントを集約
- ファイル内を「画面セクション」「テンプレートセクション」で整理
- 複数 pen ファイルが必要な場合: `design/pages/`, `design/components/` 等で分割

### 初期操作

```
1. open_document("apps/frontend/design.pen") でファイルを開く
   （新規の場合: open_document("new") で作成）
2. get_editor_state() で現在の状態を確認
3. get_variables() で既存の Variables を確認
```

## デザイントークン管理

### Variables 同期の概念

```
Pencil Variables ←→ CSS Custom Properties（globals.css）
         ↑
    Single Source of Truth（ブランドガイドライン等）
```

- Pencil Variables = CSS Custom Properties のデザインツール側ミラー
- 真実源を1箇所に定め、Pencil と CSS の双方を同期する運用を推奨
- `set_variables` の `replace: false`（マージモード）で安全に更新可能

### デザイントークンテーブル（テンプレート）

> プロジェクトのデザイントークンを以下の形式で記録してください。

| CSS 変数 | 値 | Pencil 変数 | 用途 |
|---------|-----|------------|------|
| `--primary` | | `--primary` | メインカラー |
| `--background` | | `--background` | ページ背景 |
| `--foreground` | | `--foreground` | 本文テキスト |
| `--destructive` | | `--destructive` | 削除・エラー |
| `--border` | | `--border` | ボーダー |
| `--ring` | | `--ring` | フォーカスリング |
| <!-- プロジェクト固有のトークンを追記 --> | | | |

### トークン同期手順

```
Code → Pencil:
  1. globals.css の値を確認
  2. set_variables で Pencil に反映（replace: false でマージ）

Pencil → Code:
  1. get_variables で Pencil の値を取得
  2. globals.css に反映
```

## コンポーネント管理

### コンポーネント分割ルール

| 種別 | 配置先 | 例 |
|------|--------|-----|
| 再利用可能 UI | `src/components/ui/` | Button, Card, Dialog, Badge |
| 機能固有 | `src/components/features/` | LoginForm, BalanceChart |
| ページ固有 | `app/{route}/_components/` | DashboardHeader |

### Pencil コンポーネントの reusable 化

Pencil 上で再利用可能なコンポーネントを作成する方法:

1. **UI 上**: コンポーネントを選択 → `Cmd+Option+K`
2. **MCP**: `batch_design` で `U("nodeId", { reusable: true })`

コンポーネントインスタンスは `ref` で配置:

```javascript
instance=I("parent", { ref: "componentNodeId", ... })
```

### コンポーネント設計のポイント

- UI Kit（shadcn/ui 等）由来のコンポーネントはそのまま活用
- プロジェクト固有のパターンのみ新規コンポーネント化（ステータスバッジ、カスタムナビ等）
- 細かすぎる粒度は避ける（Button 単体等は UI Kit に任せる）

## 設計フロー

### /2 計画コマンドとの連携

UI 変更を伴う Issue の計画立案時:

1. Pencil で対象画面のモックアップを作成
2. `get_screenshot` でスクリーンショットを取得し Issue に添付
3. 実装計画にコンポーネント分割とデザイントークンの変更を記載

### /4 実装コマンドとの連携

```
Pencil でデザイン確定
  ↓
get_guidelines("code") でコーディングガイドライン取得
  ↓
get_variables でデザイントークン取得
  ↓
フロントエンド実装（frontend-patterns スキル参照）
```

詳細なワークフローは [pencil-workflow.md](./pencil-workflow.md) を参照。

### /5 検証コマンドとの連携

- `get_screenshot` でデザインと実装を視覚比較
- `get_variables` でトークンの一貫性を確認
- `snapshot_layout` でレイアウト崩れを検出

## 命名規則

| 対象 | 規則 | 例 |
|------|------|-----|
| デザインファイル | kebab-case | `design.pen` |
| Pencil フレーム名 | 画面名（日本語可） | `会員管理（一覧）` |
| テンプレートフレーム名 | `Template: ` プレフィックス | `Template: 一覧ページ` |
| React コンポーネント | PascalCase | `BalanceCard.tsx` |

ファイル命名の詳細は [file-naming.md](../../rules/file-naming.md) を参照。

## 関連ファイル

- **[pencil-workflow.md](./pencil-workflow.md)** — Pencil MCP ツールカタログ、コンポーネント/テンプレートカタログ、ワークフロー詳細
- [frontend-patterns](../frontend-patterns/SKILL.md) — フロントエンド実装パターン
- [file-naming](../../rules/file-naming.md) — ファイル命名規則
