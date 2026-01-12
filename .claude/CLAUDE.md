# Claude Code 開発ガイド - DocDD Starter Kit

Doc Driven Development (DocDD) と 7-axis Traceability を軸にした開発テンプレートにおける Claude Code 活用ガイドです。

## プロジェクト概要

- **バックエンド**: FastAPI + モジュラーモノリスパターン
- **フロントエンド**: Next.js App Router
- **DocDD**: 7軸トレーサビリティ構造
- **開発フロー**: Issue駆動開発 + Claude Code スラッシュコマンド

---

## 重要原則

1. **品質優先**: 時間をかけてでも品質を優先する。リサーチして公式ベストプラクティスを採用する
2. **既存パターン尊重**: 新規追加より既存ファイルの編集を優先。プロジェクトの既存パターンに従う
3. **シンプルさ**: 過度な抽象化を避け、必要最小限の実装にとどめる
4. **トレーサビリティ**: Issue → Plan → Implementation → PR の流れを追跡可能に保つ

**詳細なルール**: [.claude/rules/README.md](./rules/README.md)

---

## プロジェクト構成

```
docdd-starters/
├── apps/
│   ├── backend/           # FastAPI バックエンド
│   │   └── app/
│   │       ├── kernel/    # モジュラーモノリス基盤
│   │       ├── modules/   # ドメインモジュール
│   │       └── shared/    # 全モジュール共通ユーティリティ
│   └── frontend/          # Next.js フロントエンド
│       ├── app/           # App Router Segments（画面単位）
│       └── src/           # 共通モジュール
├── docs/
│   ├── 7-axis/            # DocDD 7軸トレーサビリティ文書
│   ├── guides/            # 運用ガイド
│   └── testing/           # テスト管理・トレーサビリティmap
├── scripts/
│   ├── test/              # トレーサビリティ検証スクリプト
│   ├── frontend/          # フロントエンド用スクリプト
│   └── gas/
│       └── progress-sync/ # Sheets↔GitHub同期GAS
├── .claude/
│   ├── commands/          # カスタムスラッシュコマンド
│   ├── skills/            # AI実行知識（ドメイン・パターン）
│   └── rules/             # モジュール化ルール（命名・規約）
└── README.md
```

---

## クイックリファレンス

### カスタムコマンド

| コマンド | 説明 |
|---------|------|
| `/1` | Issue作成 |
| `/2` | 実装計画を立案してIssue本文に追記 |
| `/3` | ブランチ作成とIssue紐付け |
| `/4` | 実装フェーズ開始（進行中ラベル設定） |
| `/5` | Pull Request作成 |
| `/6` | マージ後のクリーンアップ |
| `/a`,`/b`,`/c` | Worktree並列開発 |
| `/commit-and-push` | コミットしてプッシュ |
| `/run-tests` | テスト実行 |

**詳細**: [commands/README.md](./commands/README.md)

### スキル（AI実行知識）

| スキル | 説明 |
|--------|------|
| [docdd-workflow](./skills/docdd-workflow/SKILL.md) | DocDD 7軸の運用ルール |
| [backend-patterns](./skills/backend-patterns/SKILL.md) | FastAPI/モジュラーモノリス |
| [frontend-patterns](./skills/frontend-patterns/SKILL.md) | Next.js/Private Folder実装 |
| [testing-patterns](./skills/testing-patterns/SKILL.md) | テスト戦略・フィクスチャ |

**詳細**: [skills/README.md](./skills/README.md)

### ルール

| ルール | 説明 |
|--------|------|
| [planning-quality](./rules/planning-quality.md) | 計画立案品質ルール |
| [commit-messages](./rules/commit-messages.md) | コミットメッセージ規則 |
| [branch-naming](./rules/branch-naming.md) | ブランチ命名規則 |
| [file-naming](./rules/file-naming.md) | ファイル命名規則 |

**詳細**: [rules/README.md](./rules/README.md)

---

## 開発ワークフロー

### Issue駆動開発フロー

```
1. /1 - Issue作成   → タスクをIssue化
2. /2 - 計画立案    → Issue に実装計画を追記
3. /3 - ブランチ作成 → feature/issue-xxx-short-desc
4. /4 - 実装開始    → 進行中ラベル設定 + コード実装
5. /5 - PR作成      → レビュー依頼
6. /6 - マージ      → クリーンアップ + Webhook連携
```

### 並列開発（Worktree）

複数Issueを同時進行する場合：

```
/a issue-123  → Worktree作成
/b issue-123  → Worktree移動・マージ
/c issue-123  → Worktree削除
```

---

## テスト・品質

### テスト実行

```bash
# バックエンド
make test-backend

# フロントエンド
cd apps/frontend
npm run lint:biome && npm run check:segments && npm run test:unit

# トレーサビリティ検証
make traceability
```

### 7-axis トレーサビリティ

- `BR → UC → DM → SR/NSR → EXT → API → TC` の追跡構造
- `docs/7-axis/` にテンプレートとサンプルを格納
- `docs/testing/traceability/` にマッピングファイルを配置

---

## Progress Sync（Google Sheets × GitHub）

計画表（Google Sheets）とGitHub Issuesの双方向同期機能。

- **Sheets → GitHub**: タスク追加/編集時にIssue作成/更新
- **GitHub → Sheets**: Issue/PRイベントでステータス更新
- **設定**: `scripts/gas/progress-sync/README.md` を参照
