# Progress Sync - Google Sheets ↔ GitHub Issues 双方向同期

計画表（Google Sheets）とGitHub Issuesの双方向同期を実現するGoogle Apps Script。

## 概要

- **マスター**: Google Sheets（計画表）
- **同期方向**: 双方向
  - Sheets → GitHub: タスク追加/編集時にIssue作成/更新
  - GitHub → Sheets: Issue/PRイベントでステータス更新

## アーキテクチャ

```
┌─────────────────────────────────────┐
│   計画表（Google Sheets）           │  ← マスター
│   + Issue番号/PR番号/同期ステータス列 │
└─────────────────────────────────────┘
         │ onEdit              ▲ Webhook
         ▼                      │
┌─────────────────────────────────────┐
│     GAS Progress Sync Service       │
│  - SheetsToGitHub.gs (Issue作成)    │
│  - GitHubToSheets.gs (Webhook受信)  │
└─────────────────────────────────────┘
         │ GitHub API          ▲ Webhook
         ▼                      │
┌─────────────────────────────────────┐
│        GitHub Repository            │
│   Issues + Labels (status:*)        │
└─────────────────────────────────────┘
```

## セットアップ

### 1. clasp設定

```bash
# clasp インストール
npm install -g @google/clasp

# ログイン
clasp login

# .clasp.json 作成
cp .clasp.json.template .clasp.json
# scriptId を実際のGASプロジェクトIDに置き換え
```

### 2. GASプロジェクト作成

1. Google Sheetsで対象スプレッドシートを開く
2. 拡張機能 → Apps Script
3. スクリプトIDをコピーして `.clasp.json` に設定

### 3. コードをデプロイ

```bash
cd scripts/gas/progress-sync
clasp push
```

### 4. 初期設定（Sheets UI）

1. スプレッドシートをリロード
2. メニュー「進捗同期」→「設定」
3. GitHub Token、リポジトリ情報を入力
4. メニュー「進捗同期」→「トリガーを設定」

### 5. Webhook設定（GitHub）

1. リポジトリ Settings → Webhooks → Add webhook
2. Payload URL: GASのWeb App URL
3. Content type: `application/json`
4. Events: `Issues`, `Pull requests`

## ファイル構成

```
src/
├── Main.gs           # エントリーポイント・メニュー・トリガー
├── Config.gs         # 設定・定数管理
├── Utils.gs          # 共通ユーティリティ
├── StatusMapping.gs  # ステータス ↔ Issue state変換
├── GitHubClient.gs   # GitHub API クライアント
├── SheetsClient.gs   # Sheets操作
├── SheetsToGitHub.gs # Sheets → GitHub同期
├── GitHubToSheets.gs # GitHub → Sheets同期（Webhook）
└── ConfigDialog.html # 設定ダイアログUI
```

## ステータスマッピング

| Sheets ステータス | GitHub 状態 |
|-----------------|-------------|
| 未着手 | Open + `status:todo` |
| 進行中 | Open + `status:in-progress` |
| 完了 | Closed |
| 保留 | Open + `status:on-hold` |

## 使い方

### メニュー操作

| メニュー | 説明 |
|---------|------|
| GitHubと同期 | 全未同期行をGitHubに同期 |
| 選択行を同期 | 選択している行のみ同期 |
| 必要なLabelsを作成 | GitHubに必要なラベルを作成 |
| 必要な列を追加 | Issue番号/PR番号/同期ステータス列を追加 |
| トリガーを設定 | onEditトリガーを設定 |
| 設定 | GitHub Token等の設定 |

### 自動同期

トリガー設定後、以下のタイミングで自動同期:

- **行編集時**: 該当行のIssueを更新
- **GitHubイベント時**: Webhook経由でSheetsを更新

## 同期対象外

以下のステータスの行は同期をスキップ:

- 対象外
- 中リスク
- 低リスク
- 高リスク

## セキュリティ

- **GitHub Token**: PropertiesServiceで暗号化保存
- **Webhook検証**: 直結GAS構成では実施しない（URLの秘匿性で担保）
- **冪等性**: ペイロード由来のイベントキーをCacheServiceでトラッキング

## CI/CD

GitHub Actionsで自動デプロイ:

```yaml
# .github/workflows/deploy-gas.yml
name: Deploy GAS
on:
  push:
    paths: ['scripts/gas/progress-sync/**']
```

必要なSecrets:
- `CLASPRC_JSON`: clasp認証情報
- `GAS_SCRIPT_ID`: デプロイ先のスクリプトID

## トラブルシューティング

### 同期されない

1. 「設定」でGitHub Tokenが正しいか確認
2. 「トリガーを設定」を再実行
3. 実行ログ（Apps Script → 実行数）を確認

### Webhookが動作しない

1. Web AppをデプロイしてURLを取得
2. GitHub Webhook設定でURLが正しいか確認
3. Recent Deliveriesでレスポンスを確認

## 開発

### ローカル編集 → GASデプロイ

```bash
clasp push  # src/ 内の .gs ファイルをアップロード
```

### GAS → ローカル同期

```bash
clasp pull  # GASの変更をローカルに反映
```
