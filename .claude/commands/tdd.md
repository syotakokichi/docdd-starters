---
description: TDD ガード付きで Failing test (RED) を先行作成し、`/develop` の実装に引き渡します。
argument-hint: "<issue-number>"
disable-model-invocation: true
---
Issue #$ARGUMENTS の TDD（Test-Driven Development）ガード付き実装を開始してください。

**`/plan` の検証定義で「TDD 必須」と判定された Issue で使用します。**

---

## 目的

- `/plan` で `TDD 必須` と判定された Issue に対して、**RED テストの先行作成 → FAILED 確認 → Issue コメントで RED 証跡を残す** までを担う
- GREEN（実装本体）への引き渡しは `/develop $ARGUMENTS` に委譲する
- TDD スキップ判定の Issue では本コマンドを使わず直接 `/develop` を呼ぶ

## 標準フロー

```
/plan <N>       # TDD 判定を確定（前段）
/tdd <N>        # 本コマンド（RED テスト + 証跡作成）
/develop <N>    # GREEN 実装
/verify <N>     # 検証
```

---

## 手順

### Step 1: TDD 判定を確認

`/plan` の検証定義から TDD 判定を読み取る。判定基準の SSOT は [`.claude/rules/tdd-gate.md`](../rules/tdd-gate.md)。

```bash
# Issue 本文の TDD 判定を確認
gh issue view $ARGUMENTS --json body --jq .body | grep -A 5 "TDD 判定"
```

| 判定 | 本コマンドの扱い |
|------|----------------|
| `TDD 必須` | 続行（Step 2 以降） |
| `TDD スキップ（理由あり）` | 中止。`/develop` を直接実行する旨を案内 |
| 空欄（証跡漏れ） | 中止。`/plan` に戻って判定を埋めるよう案内 |

> **証跡漏れの場合**: 「TDD 判定が未記載です。先に `/plan $ARGUMENTS` で TDD 判定を埋めてください」とユーザーに案内し、本コマンドを終了する。

### Step 2: 想定 RED コマンドを確認

`/plan` の Critical Path テーブルで定義された **想定 RED コマンド** と **Focused test commands** を読み取る。

```bash
gh issue view $ARGUMENTS --json body --jq .body | grep -A 5 "想定 RED コマンド"
gh issue view $ARGUMENTS --json body --jq .body | grep -A 5 "Focused test commands"
```

例:

| 項目 | 内容 |
|------|------|
| 想定 RED コマンド | `PYTHONPATH=apps/backend pytest tests/backend/.../test_xxx.py::test_new_case -v` |
| 想定 GREEN コマンド | `PYTHONPATH=apps/backend pytest tests/backend/.../test_xxx.py::test_new_case -v` |

### Step 3: Failing test を先行作成

実装本体には触れず、**期待挙動を表現する Failing test** だけを書く。
パターン集（新規ロジック / バグ修正 / 状態遷移 / API / parametrize）と heredoc 利用判断は [`.claude/skills/tdd-workflow/SKILL.md`](../skills/tdd-workflow/SKILL.md) を参照。

| レイヤー | パターン | 補足 |
|---------|---------|------|
| Backend (pytest) | `tests/backend/<unit\|integration>/test_xxx.py` に `test_新挙動` を追加 | [`.claude/skills/tdd-workflow/SKILL.md`](../skills/tdd-workflow/SKILL.md) / [`.claude/skills/testing-patterns/SKILL.md`](../skills/testing-patterns/SKILL.md) 参照 |
| Frontend (Vitest) | `tests/frontend/unit/xxx.test.ts(x)` に新ケースを追加 | [`.claude/skills/tdd-workflow/SKILL.md`](../skills/tdd-workflow/SKILL.md) / [`.claude/skills/testing-patterns/SKILL.md`](../skills/testing-patterns/SKILL.md) 参照 |

**禁止事項**:
- ❌ 実装本体（`apps/backend/app/...` の domain/service/route）には一切触れない
- ❌ 既存テストを壊して RED を作る（新規テストを追加する形にする）
- ❌ `pytest.skip` / `it.skip` で「とりあえずグリーン」にする

### Step 4: RED 確認（Failing 結果を取る）

新規テストが想定どおり FAILED で落ちることを確認する。
「`0 selected` / `all skipped` を成功扱いにしない」など完了判定の SSOT は [`.claude/skills/verification-before-completion/SKILL.md`](../skills/verification-before-completion/SKILL.md) を参照。

```bash
# Backend 例
PYTHONPATH=apps/backend pytest tests/backend/<path>/test_xxx.py::test_new_case -v

# Frontend 例
cd apps/frontend && npx vitest run ../../tests/frontend/unit/xxx.test.ts -t "test_new_case"
```

**RED として有効な結果**:
- `FAILED` (AssertionError / ImportError / TypeError 等)
- `1 failed in X.Xs` のように **明示的に失敗** している

**RED として無効な結果**（やり直す）:
- `0 selected`（marker / path 指定ミス）
- `all skipped`（skip flag が掛かっている）
- `script not found`（`npm run xxx` の script 不在）
- `PASSED`（テストが既に通っている → アサーションを強める）

### Step 5: RED 証跡を Issue コメントに記録（heredoc テンプレ）

`/develop` への引き渡し用に、RED コマンドと結果を Issue コメントとして残す。

```bash
gh issue comment $ARGUMENTS --body "$(cat <<'EOF'
## TDD RED 証跡（/tdd 完了時点）

### 判定
- TDD 判定: 必須
- 対象領域: [Backend / Frontend / 両方]

### 追加したテスト
- `tests/backend/<path>/test_xxx.py::test_new_case`（Failing で先行追加）
- [複数ある場合は箇条書き]

### RED コマンド
\`\`\`bash
PYTHONPATH=apps/backend pytest tests/backend/<path>/test_xxx.py::test_new_case -v
\`\`\`

### RED 結果
\`\`\`
FAILED tests/backend/<path>/test_xxx.py::test_new_case
- AssertionError / ImportError / 等の要点を 1〜3 行
- 1 failed in X.Xs
\`\`\`

### 次のステップ
- `/develop $ARGUMENTS` に引き渡し
- GREEN コマンドは Issue 本文の Critical Path テーブル参照
EOF
)"
```

> **記法ルール**: `/develop` Phase 5 / `/verify` Step 6 で証跡を確認するため、見出し `## TDD RED 証跡（/tdd 完了時点）` をそのまま使う。コマンドと結果はコードブロックで囲む。
> **ファイル参照**: 結果が長い場合は `/tmp/tdd_red_$ARGUMENTS.txt` に書き出して `gh issue comment --body-file` で投稿してもよい。

> **記法・ガイドライン SSOT**: 証跡フォーマット詳細は [`.claude/skills/tdd-workflow/SKILL.md`](../skills/tdd-workflow/SKILL.md)（証跡記録セクション）。完了主張前のゲート（5 ステップ）は [`.claude/skills/verification-before-completion/SKILL.md`](../skills/verification-before-completion/SKILL.md)。

### Step 6: `/develop` への引き渡し

```
RED 証跡作成完了:
  - 追加テスト: N 件（FAILED 確認済み）
  - RED コマンド: <command>

次のステップ:
  /develop $ARGUMENTS    # GREEN 実装（同一セッション可 / 別セッションでも可）
```

> `/develop` 内で GREEN にする最小実装を書き、同じコマンドが PASS することを確認する。RED → GREEN の往復で `/plan` の Critical Path を保護する。

---

## チェックリスト

`/develop` に引き渡す前に確認:

- [ ] `/plan` の TDD 判定が `必須` であることを確認した
- [ ] 想定 RED コマンドが `/plan` の Critical Path テーブルに記載されている
- [ ] 実装本体には触れず、新規 Failing test のみを追加した
- [ ] RED コマンドが `FAILED` で落ちることを確認した（`0 selected` / `all skipped` ではない）
- [ ] RED 証跡を Issue コメントとして投稿した（heredoc テンプレに従う）

---

## 注意事項

- 本コマンドは **TDD 必須判定の Issue 専用**。スキップ判定なら直接 `/develop` を呼ぶ
- 実装本体には絶対に触れない（GREEN は `/develop` の責務）
- `0 selected` / `all skipped` を成功扱いにしない
- 既存テストを壊して RED を作らない（新規追加で対応）

---

## 失敗時の対処

| 状況 | 対処 |
|------|------|
| RED にならない（既に PASS） | アサーションを強める or テストケースを再設計する。`/plan` に戻ってシナリオを見直す |
| `0 selected` | テスト discovery の path / marker / pattern を見直す |
| `script not found` | `apps/frontend/package.json` の scripts を確認、`make test-frontend` 経由に切替 |
| 想定 RED コマンドが `/plan` に記載なし | `/plan $ARGUMENTS` に戻って Critical Path テーブルを埋める |

---

## 次のステップ

RED 証跡を Issue コメントに残した。`/develop` で GREEN を達成する。

```
---
✨ **このセッションで進んだこと**
- 追加した Failing test: <M> 件（FAILED 確認済み）
- RED コマンド: `pytest <path>::<test>`（または `npx vitest run ...`）
- 実装本体は未編集

🎯 **これによって変わること**
- 期待挙動がテストとして固定され、`/develop` での GREEN 実装が同じコマンドで検証可能になる
- スコープ漏れがあれば `/plan` の Critical Path テーブルとの差分が見える

📋 **次のステップ**
- Issue #<N>（RED 証跡記録済み）
- `/develop <N>` で GREEN 実装
---
```

コピペ用:

```bash
/develop <N>
```

---

## 📋 後続 Issue で導入予定（forward reference の隔離）

| 参照先（未存在） | 用途 | 予定 Issue |
|--------------|------|----------|
| failure-escalation Level 3 hook | RED が連続 3 回失敗した場合の停止 hook | 後続 Issue（1-1 baseline 拡張 想定） |

Remember to use the GitHub CLI (`gh`) for all GitHub-related tasks.
