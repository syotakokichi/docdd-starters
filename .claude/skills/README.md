# Skills - AI実行知識

Claude Code が特定のドメインや技術パターンを適用する際に参照する知識ベースです。

本ディレクトリは **2 層運用** になっています:

1. **flat 命名（プロジェクト固有スキル）** — DocDD/FastAPI/Next.js 等のドメイン知識
2. **prefix 命名（外部 taxonomy 採用領域）** — Skill 設計品質を機械的に上げるためのメタ skill 群

新規スキルを作成する際は、まず prefix 命名（`ref-` / `run-` / `wrap-` / `assign-` / `delegate-`）の決定木に従い、ドメイン知識として既存 flat 命名に揃える方が自然な場合は flat のままにします。判定は `run-skill-creator` の Step 0–8 が代行します。

## 目次

### プロジェクト固有スキル（flat 命名）

#### ドメイン / 領域スキル

| スキル | 説明 |
|--------|------|
| [docdd-workflow](./docdd-workflow/SKILL.md) | DocDD 7軸トレーサビリティの運用ルール |
| [backend-patterns](./backend-patterns/SKILL.md) | FastAPI モジュラーモノリスパターン |
| [frontend-patterns](./frontend-patterns/SKILL.md) | Next.js App Router / Private Folder |
| [testing-patterns](./testing-patterns/SKILL.md) | pytest / Vitest テスト戦略 |
| [traceability-automation](./traceability-automation/SKILL.md) | トレーサビリティマップ活用 |
| [presentation](./presentation/SKILL.md) | Marpプレゼンテーション作成 |
| [design](./design/SKILL.md) | Pencil.dev MCP 連携によるUI設計・デザイントークン管理 |

#### Cross-Cutting Skills（フロー横断 / 必要時ロード）

ドメイン非依存で、コマンドから必要時にロードされる横断スキル群。Issue → 適用 skill のマッピングは [`../references/applicable-skills.md`](../references/applicable-skills.md) を参照。

| スキル | 説明 |
|--------|------|
| [planning-quality](./planning-quality/SKILL.md) | 計画立案品質ルール（リサーチ / 依存先トレース / 観点別チェック / Codex レビュー） |
| [issue-sizing](./issue-sizing/SKILL.md) | Issue サイジング（縦スライス / サイズ上限 / Umbrella / 観察集約） |
| [agent-teams](./agent-teams/SKILL.md) | エージェントチーム運用（粒度判断 / コンテキストフレッシュ / 検証テンプレ） |
| [parallel-development](./parallel-development/SKILL.md) | 並列開発（Worktree）運用ルール |
| [verify-input-capture](./verify-input-capture/SKILL.md) | `/verify` Step 1 の入力固定（Issue 番号検証 / merge-base diff / 実行コンテキスト） |

### 外部 taxonomy 採用領域（prefix 命名）

Skill 設計品質を機械的に上げるためのメタ skill 群です。`ref-*` は他 skill から Skill ツールで明示的に参照される正本、`assign-*-evaluator` は別コンテキストで採点する evaluator、`run-*` は orchestrator です。

| スキル | prefix 種別 | 役割 |
|--------|------------|------|
| [ref-agent-skill](./ref-agent-skill/SKILL.md) | `ref-*` (`kind: essence`) | Skill 設計の正本：4 軸（Purpose/Trigger/Shape/Role）+ 5 prefix 決定木 + 共通ルール |
| [ref-skill-component-design](./ref-skill-component-design/SKILL.md) | `ref-*` (`kind: meta`) | コンポーネント構造規定：ペア形式（ref + evaluator）/ 三組形式（ref + evaluator + generator）/ `pair:` 契約 |
| [assign-agent-skill-evaluator](./assign-agent-skill-evaluator/SKILL.md) | `assign-*-evaluator` | SKILL.md の品質を 4 観点（軸整合性 / prefix 導出 / frontmatter / 共通ルール）で採点。並置 `eval-schema.json` あり |
| [run-skill-creator](./run-skill-creator/SKILL.md) | `run-*` (orchestrator) | Step 0–8 で skill 新規作成を指揮：適格性 → 4 軸判定 → 起草 → description 最適化 → セルフチェック → evaluator レビュー |
| [delegate-codex](./delegate-codex/SKILL.md) | `delegate-*` (pass-through) | Codex CLI に任意タスクを委譲する thin wrapper。heredoc + stdin で zsh メタ文字耐性を確保。「Codex に任せて」「codex で実装して」で発動 |
| [delegate-explorer](./delegate-explorer/SKILL.md) | `delegate-*` (pass-through) | read-only でコードベースを調査する general-purpose (haiku) サブエージェント。「コード探索」「ファイル探索」で発動 |
| [delegate-planner](./delegate-planner/SKILL.md) | `delegate-*` (pass-through) | read-only で実装プランを設計する general-purpose (opus) サブエージェント。`delegate-explorer` と連携。「プラン作って」「設計プラン」で発動 |

#### prefix 決定木（5 種）

```
Step 1. Purpose（呼ぶと何が返るか）
   knowledge → ref-*
   produce / judge / pass-through → 次へ

Step 2. Role（assign-* / delegate-* の判別）
   generator / evaluator / contributor を持つ → assign-*-{役}
   pass-through で契約なし → delegate-*
   無関係 → 次へ

Step 3. base（既存 skill の派生か）
   YES → wrap-*（base: 必須）
   NO  → run-*
```

詳細は [ref-agent-skill](./ref-agent-skill/SKILL.md) §1（4 軸）/ §2（決定木）を参照。

#### 二層運用ポリシー

- 既存 8 スキル（flat 命名）はそのまま維持。外部 taxonomy への一括リネームは行わない
- 後続 Issue で `assign-agent-skill-evaluator` の採点結果を入力に、prefix 命名統一 + frontmatter 補完を進める
- `ref-*` は `disable-model-invocation: true` + `user-invocable: false`（自動発動せず、他 skill から明示参照）
- `assign-*-evaluator` は `context: fork`（別コンテキストで自己採点の sycophancy を回避）

## スキルの使い方

### 自動適用

Claude Code は関連する作業時に自動的にスキルを参照します。

例:
- FastAPI のコードを書く → `backend-patterns` を参照
- テストを追加する → `testing-patterns` を参照
- ドキュメントを更新する → `docdd-workflow` を参照

### 明示的な参照

特定のスキルを適用させたい場合:

```
@skill:backend-patterns に従ってリポジトリを実装してください
```

## スキルの追加

プロジェクト固有のスキルを追加する場合:

1. `skills/<skill-name>/` ディレクトリを作成
2. `SKILL.md` に知識を記述
3. 必要に応じて `references/` に参考資料を配置

### SKILL.md のテンプレート

```markdown
# スキル名

## 概要
このスキルが扱う内容の説明

## 適用条件
このスキルが適用される状況

## パターン
### パターン1
- 説明
- コード例

### パターン2
- 説明
- コード例

## アンチパターン
避けるべき実装パターン

## 参考資料
- 公式ドキュメントへのリンク
- 内部ドキュメントへの参照
```

## 設計思想

- **明示的**: 暗黙のルールより明文化されたルールを優先
- **具体的**: 抽象的な説明より具体的なコード例を提供
- **更新可能**: プロジェクトの成長に合わせて継続的に更新
