---
description: 新しい GitHub Issue を作成します。
disable-model-invocation: true
---
新しい GitHub Issue を作成してください。canonical workflow の起点となるコマンドです。

**CLAUDE.md の開発フローに従って進めてください。**

---

## 役割

- 新しい GitHub Issue を作成する
- サイズチェックでスコープが適切に切れているか確認する
- 次に進むべきフェーズ（`/worktree` → `/plan`）を案内する

## 使い方

- 新規作業を起票する場合は `/issue`
- やりたいことが曖昧なら `/discuss` で壁打ちしてから `/issue`
- 既存 Issue の本文更新は `/update-issue` を使用する

タスクの内容を伝えてください。以下の情報があると良いです:

- 何を実現したいか
- 背景や理由
- 完了条件

## 標準フロー

Issue 作成後の正規フロー:

```
/worktree <N>     # worktree 作成 + ブランチ命名（推奨。詳細は parallel-development スキル参照）
/plan <N>         # Issue 本文に仕様固定済みの計画を反映
```

---

## 手順

### Step 1: サイズチェック

Issue の概要から影響範囲を概算し、`.claude/rules/issue-sizing.md` に照らす:

| 指標 | 上限 |
|------|:----:|
| 変更対象ファイル | 20 |
| 実装タスク数 | 8 |
| 起因 Issue / 負債 | 1 |
| Phase 数 | 1 |

**超過しそうな場合**: 縦スライス（ドメイン概念ごと）に分割して複数 Issue を作成する。
特に「負債まとめて返済」パターンは禁止。棚卸し Issue + 個別 Issue に分ける。

### Step 2: Issue 作成

```bash
gh issue create --title "[タイトル]" --body "$(cat <<'EOF'
# Issue: [タイトル]

## 背景
[なぜ必要か]

## 目的
[何を実現したいか]

## 受け入れ条件
- [ ] [どうなれば完了か]
EOF
)"
```

### Step 3: ラベル付与（最低 2 つ）

`.github/labels.json` で管理されている canonical labels を **第一候補** として提示し、必要に応じて legacy alias も使用可（移行期間中の互換性確保のため）。

#### 優先度（1 つ選択）— canonical 優先

| canonical | legacy alias | 用途 |
|-----------|--------------|------|
| `P0` | `High` | 1〜2 営業日以内に対応すべき緊急タスク |
| `P1` | `Medium` | 通常の機能追加やバグ修正 |
| `P2` | `Low` | 将来的に対応で良い小変更 |

#### 領域（1 つ以上選択）— canonical 優先

| canonical | legacy alias | 用途 |
|-----------|--------------|------|
| `BE` | `バックエンド` | API・サーバーサイド実装 |
| `FE` | `フロントエンド` | UI/UX 実装・修正 |
| `infra` | `インフラ` | インフラ基盤・CI/CD |
| `docs` | `ドキュメント` | ドキュメント作成・更新 |
| `tests` | `テスト` | テストコードの追加・修正 |
| `bug` | `バグ` | 不具合修正 |
| `chore` | （なし） | ビルド・依存・メタ作業 |

#### ステータス

- `status:todo` を初期付与（`/develop` で `status:in-progress`、`/merge` で `status:done` に遷移）

#### 適用例

```bash
# canonical（推奨）
gh issue create --title "..." --body "..." --label "P1" --label "BE" --label "status:todo"

# legacy alias（移行期間中の互換性）
gh issue create --title "..." --body "..." --label "Medium" --label "バックエンド" --label "status:todo"
```

> ラベル整合の詳細は `.github/labels.json` を参照。canonical / legacy alias どちらでマージされても動作するよう、両方のラベルが定義されている。

### Step 4: 後続フローの案内

Issue 番号を控えて、`## 次のステップ` セクションの ✨/🎯/📋 trailer をユーザーに出力する（trailer SSOT: `.claude/rules/command-trailer.md`）。

---

## 注意事項

- Issue 作成後、`/plan` で実装計画を立案して Issue 本文に追記する
- 並列開発する場合は `/worktree <N>` を先に実行し、worktree 内で `/plan` 〜 `/pr` を進める
- 単独 sequential で進める場合は `/plan` 直後に `/develop` でも可（`.claude/skills/parallel-development/SKILL.md` 参照）

---

## 次のステップ

Issue 起票完了。並列開発するなら `/worktree` を先に、単独 sequential なら `/plan` を直接呼ぶ。

```
---
✨ **このセッションで進んだこと**
- Issue #<N> 作成（labels: <優先度> / <領域> / status:todo）
- サイズチェック PASS（変更ファイル <M> 件想定 / 実装タスク <K> 件想定）

🎯 **これによって変わること**
- 起票内容が Issue tracker 上の単一参照源になり、`/plan` 以降が Issue 番号で追跡可能になる
- 並列開発する場合は次の `/worktree` で worktree + 専用ブランチが立ち上がる

📋 **次のステップ**
- Issue #<N>（status:todo）
- 並列開発するなら `/worktree <N>`、単独 sequential なら `/plan <N>` を直接
---
```

コピペ用:

```bash
/worktree <N>
```

---

## 📋 後続 Issue で導入予定（forward reference の隔離）

| 参照先（未存在） | 用途 | 予定 Issue |
|--------------|------|----------|
| `/brainstorm` コマンド | 曖昧な要望から Issue 化前のアイデア出し | 後続 Issue（2-2 想定） |

Remember to use the GitHub CLI (`gh`) for all GitHub-related tasks.
