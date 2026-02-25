# GitHub Projects 運用ルール

GitHub Projects V2 でのタスク管理ルールを定義します。

## フィールド

| フィールド | 用途 |
|-----------|------|
| **Status** | `Backlog` → `Ready` → `In Progress` → `Done` |
| **Stage** | `Pencil` → `DB` → `API` → `UI` → `QA` |
| **Feature** | 機能エリア（プロジェクトに合わせて定義） |
| **Priority** | 優先度（`P0`: 緊急 / `P1`: 重要 / `P2`: 通常） |

---

## Issue 作成時

```
Status: Backlog
Stage: 開始ステージ（Pencil/DB/API/UI）
Feature: 機能エリア
Priority: P0 / P1 / P2
```

### Stage の選び方

| 最初に必要な作業 | Stage |
|-----------------|:-----:|
| デザイン・設計が必要 | Pencil |
| DBスキーマ変更から | DB |
| API追加のみ | API |
| 画面修正のみ | UI |

---

## ステージ遷移

```
Pencil → DB → API → UI → QA → (Status: Done)
```

| 遷移 | 条件 | DocDD 更新（同一 Issue 内） |
|------|------|--------------------------|
| Pencil → DB/API | 設計確定後 | - |
| DB → API | スキーマ確定後 | DM-*.md + DM-ER-Diagram.md |
| API → UI | API実装完了後 | 6_API/*.yaml（API仕様書） |
| UI → QA | UI実装完了後 | UC/SR（該当あれば） |
| QA → Done | テスト・レビュー完了後 | `make traceability` パス |

**Note**: Stage に Done は入れない。完了は `Status: Done` で管理。

### DocDD 更新ルール

- **実装と同じ Issue 内で更新する**（サイズ上限 20 ファイル以内なら分割しない）
- 各 Stage で書けるドキュメントはその Stage 内で書く（後回し禁止）
- 超過する場合のみ DocDD を別 Issue に分割（`[DocDD]` 接頭辞を付ける）

---

## Stage 更新タイミング

| タイミング | 更新内容 |
|-----------|---------|
| PR マージ後 | 完了した Stage の次へ移動 |
| 日次確認時 | In Progress の Stage が実態と合っているか確認 |

**基本ルール**: 「PR を出すタイミングで Stage を見直す」

---

## Status 遷移

| Status | 状態 | コマンド |
|--------|------|---------|
| Backlog | Issue作成済み、未計画 | `/1` |
| Ready | 計画立案済み、着手待ち | `/2` |
| In Progress | 実装中 | `/4` |
| Done | 完了 | `/7` |

## 計画済みの表示

計画完了した Issue はタイトルに `[実装計画]` を追加。

---

## ラベルによるステータス管理

GitHub Projects 未設定の場合は、ラベルでステータスを管理:

```bash
# 進行中に設定
gh issue edit <number> --remove-label "status:todo" --add-label "status:in-progress"

# 完了に設定
gh issue edit <number> --remove-label "status:in-progress" --add-label "status:done"
```

---

## WIP制限

- `Status: In Progress` は **最大3件**まで

---

## 依存関係

1. **Pencil が完了するまで DB/API に進まない**
2. **DB スキーマ変更がある場合は先に確定**
3. UI は DB/API 並列 or 後追い可
4. **DocDD は各レイヤー完了時に更新**（QA まで後回しにしない）

---

## Pencil 調整ルール

Pencil デザインと実装の間で乖離が見つかるタイミングは2つある。
それぞれ修正の方向が異なる。

| 発見タイミング | Pencil 修正タイミング | 方向 | 理由 |
|:---:|:---:|:---:|------|
| `/2`（計画立案） | **実装前** | Pencil → 実装 | 正しいデザインを元に実装したい |
| `/4`〜`/5`（実装・検証） | **実装後** | 実装 → Pencil | 実装で判明した改善を Pencil に反映 |

### `/2` で発見した場合

- **`/2` の中で Pencil を修正する**（`/4` に先送りしない）
- 修正手順:
  1. `batch_design` で修正を実施
  2. **確認ゲート**: `get_screenshot` でユーザーに提示し、承認を得る
  3. 修正中に新たな問題が発覚した場合、計画に反映する
- 修正完了後、**正しい Pencil を元に計画を立案**する
- **理由**: 修正を `/4` に先送りすると、修正中の発見で計画変更が必要になり手戻りが発生する

### `/4`〜`/5` で発見した場合

- `/4` で目視確認時にコード修正 → Pencil も実装に合わせて更新（実装が正）
- `/5` Step 5 で Pencil と実装の一致を**検証**（修正は `/4` で完了している前提）
- `/4` で漏れた修正があれば `/5` で対応

---

## Feature（機能エリア）

| Feature | 含まれるもの |
|---------|-------------|
| 基盤 | インフラ、CI/CD、共通UI、DB設計 |
| 認証 | ログイン、招待、権限管理 |
| ユーザー管理 | ユーザーCRUD、プロフィール |
| 決済 | 決済連携、請求、プラン管理 |
| 運用 | FAQ、ヘルプ、CS対応 |

> プロジェクトの機能エリアに合わせてカスタマイズしてください。
> **迷ったら**: メインの機能エリアを選ぶ / 基盤に入れておく

---

## 運用ルール

1. **自動更新**: 各コマンドがステータスを自動的に更新
2. **手動更新不要**: コマンドフローに従えば手動更新は不要
3. **一貫性**: 全 Issue が同じステータス遷移を経る
4. **可視性**: Projects ボードで全タスクの進捗を一覧表示

---

## 関連ファイル

- [issue-workflow.md](./issue-workflow.md) - Issue駆動開発フロー
- [commands/README.md](../commands/README.md) - カスタムコマンド
