# Drift Audit — 上流参照ハーネス baseline 501049a vs docdd-starters `.claude/` (2026-05-20)

- **baseline_id**: `b1-501049a`
- **upstream_commit**: `501049acd4ff568d12ace19412e9ebe5a16860c3` (`501049a`)
- **captured_at**: 2026-05-20
- **captured_by_issue**: #70

> Audit ledger SSOT: [`baseline-commits.json`](./baseline-commits.json)（machine-readable, append-only）。本 Markdown は人間レビュー用の hand-curated 派生物。件数と record_id は ledger と ±0 で一致する。

## サマリ

| Classification | Count | 説明 |
|----|:--:|------|
| **Adopt now** | 14 | fork 即効性・汎用性高 + Core 結合度高。W1〜3 で移植 |
| **Adapt later** | 121 | 価値あるが汎用化・差分レビュー要。W2〜4 で再ベースライン |
| **Document only** | 22 | 取り込まずローカル保持 or references/guide に reflect |
| **Reject** | 117 | 特定ドメイン / 組織 / 環境固有 + churn 高。理由 + 再評価トリガつきで台帳記録 |
| **Total** | 274 | — |

変更タイプ別:

- `added` (上流のみ存在 = 我々が追従していない): 178
- `removed` (ローカルのみ存在 = 上流から削除済 / ローカル独自追加): 19
- `modified` (両側存在 + sha256 差異): 77

> baseline 501049a と local の両側に存在し sha256 一致するファイル数: **0**（docdd-starters は上流から派生して全 common file をローカル目的で改変済）。

## TOP10 — 暫定区分 → 確定区分 diff

計画立案時の暫定区分（Issue 本文）と、本 audit による確定区分の対応:

| # | 項目 | 優先度 | 暫定区分 | 確定区分 | Wave | 対象パス |
|:-:|------|:------:|:--------:|:--------:|:----:|---------|
| 1 | `block-dangerous.sh` 強化 + Codex auth 流出3層防御（`.codex/auth*` read/copy/tar/`git add -f` block） | 🔴 | Adopt now | Adopt now | W1 | `./hooks/block-dangerous.sh` |
| 2 | `protect-files.sh` VCS-aware 化 + `hooks/lib/protected_paths.sh`（merge-base baseline / test 新規 allow・既存 block） | 🔴 | Adopt now | Adopt now | W1 | `./hooks/protect-files.sh`, `./hooks/lib/protected_paths.sh` |
| 3 | `validate-merge-cwd.sh`（worktree からの `/merge` 誤実行を機械ブロック） | 🔴 | Adopt now | Adopt now | W1 | `./hooks/validate-merge-cwd.sh` |
| 4 | `rules/non-negotiable-gates.md` + commands の `## Non-negotiable Gates` 節 | 🔴 | Adopt now | Adopt now | W1 | `./rules/non-negotiable-gates.md` |
| 5 | `gh comment --edit-last` hard block + `scripts/claude/gh-safe-comment.sh`（コメント盲目上書き事故防止）— 本 baseline では rule のみ。script 本体は Wave 1 子 Issue で起こす | 🟡→実質🔴 | Adopt now | Adopt now | W1 | `./rules/gh-comment-edit.md` |
| 6 | `rules/multi-model-review.md` + `review-orchestrator` / `llm-debate` skill（D-1 実体） | 🟡 | Adapt later | Adapt later | W3 | `./rules/multi-model-review.md`, `./skills/review-orchestrator/SKILL.md`, `./skills/llm-debate/SKILL.md` |
| 7 | `references/mcp-setup.md`（C-1 そのもの） | 🟡 | Adopt now | Adopt now | W3 | `./references/mcp-setup.md` |
| 8 | skill-registry 自動生成（`generate_skill_registry.py` + sync target + drift gate）— scripts/ 配下の予定で `.claude/` drift には含まれない | 🟡 | Adapt later | Adapt later — out of scope for .claude/ | W4/W2 | / |
| 9 | `references/askuserquestion-usage.md`（Core `/plan` Phase 2 の SSOT） | 🟡 | Adopt now | Adopt now | W2 | `./references/askuserquestion-usage.md` |
| 10 | `develop-precommit-gate.sh` + parser（`/develop` 完了主張前 pre-commit 強制） | 🟡 | Adapt later | Adapt later | W1/W2 | `./hooks/develop-precommit-gate.sh`, `./hooks/lib/develop_precommit_parser.py` |

> 暫定 → 確定の差異 (`(Δ)` マーク) は 0 件（TOP10 候補は全て暫定区分どおり確定）。TOP10 #5 の `gh-safe-comment.sh` script 本体は本 baseline では .claude/ 配下に未到着（rule のみ）。TOP10 #8 の skill-registry 自動生成は `scripts/claude/` 配下に出る想定のため `.claude/` drift には含まれない（Wave 4 子 Issue で別途扱う）。

## Adopt now（全件 — 即移植候補）

| # | path | category | change_type | target Wave | notes |
|:-:|------|----------|:-----------:|:-----------:|-------|
| r010 | `./hooks/audit-bash-writes.sh` | hooks | added | W1 | TOP10 外の安全 hook（書き込み audit） |
| r216 | `./hooks/block-dangerous.sh` | hooks | modified | W1 | TOP10 候補（計画固定） |
| r013 | `./hooks/lib/protected_paths.sh` | hooks | added | W1 | TOP10 候補（計画固定） |
| r218 | `./hooks/protect-files.sh` | hooks | modified | W1 | TOP10 候補（計画固定） |
| r015 | `./hooks/tests/test_audit_bash_writes.sh` | hooks | added | W1 | TOP10 外の安全 hook（書き込み audit） |
| r016 | `./hooks/tests/test_block_dangerous.sh` | hooks | added | W1 | TOP10 候補（計画固定） |
| r018 | `./hooks/tests/test_protect_files.sh` | hooks | added | W1 | TOP10 候補（計画固定） |
| r019 | `./hooks/tests/test_protected_paths.sh` | hooks | added | W1 | TOP10 候補（計画固定） |
| r020 | `./hooks/tests/test_validate_merge_cwd.sh` | hooks | added | W1 | TOP10 候補（計画固定） |
| r021 | `./hooks/validate-merge-cwd.sh` | hooks | added | W1 | TOP10 候補（計画固定） |
| r038 | `./rules/gh-comment-edit.md` | rules | added | W1 | TOP10 候補（計画固定） |
| r041 | `./rules/non-negotiable-gates.md` | rules | added | W1 | TOP10 候補（計画固定） |
| r027 | `./references/askuserquestion-usage.md` | references | added | W2 | TOP10 候補（計画固定） |
| r033 | `./references/mcp-setup.md` | references | added | W3 | TOP10 候補（計画固定） |

## Adapt later（全件 — Wave 別）

### W1（3 件）

| # | path | category | change_type | notes |
|:-:|------|----------|:-----------:|-------|
| r011 | `./hooks/develop-precommit-gate.sh` | hooks | added | TOP10 候補（汎用化・再設計が必要） |
| r012 | `./hooks/lib/develop_precommit_parser.py` | hooks | added | TOP10 候補（汎用化・再設計が必要） |
| r017 | `./hooks/tests/test_develop_precommit_gate.sh` | hooks | added | TOP10 候補（汎用化・再設計が必要） |

### W2（103 件）

| # | path | category | change_type | notes |
|:-:|------|----------|:-----------:|-------|
| r198 | `./CLAUDE.md` | CLAUDE.md | modified | 上流の CLAUDE.md 改良。docdd-starters 固有部分（FastAPI / Next.js / Terraform / ECS 構成）と統合して反映 |
| r002 | `./agents/docdd-agent.md` | agents | added | 汎用化可能な agent。Wave 2 で再ベースライン |
| r003 | `./agents/frontend-agent.md` | agents | added | 汎用化可能な agent。Wave 2 で再ベースライン |
| r004 | `./agents/kernel-agent.md` | agents | added | 汎用化可能な agent。Wave 2 で再ベースライン |
| r005 | `./agents/readonly-tester.md` | agents | added | 汎用化可能な agent。Wave 2 で再ベースライン |
| r006 | `./agents/reviewer.md` | agents | added | 汎用化可能な agent。Wave 2 で再ベースライン |
| r007 | `./agents/test-agent.md` | agents | added | 汎用化可能な agent。Wave 2 で再ベースライン |
| r199 | `./commands/README.md` | commands | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r200 | `./commands/brainstorm.md` | commands | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r201 | `./commands/commit-and-push.md` | commands | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r202 | `./commands/develop.md` | commands | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r203 | `./commands/discard-worktree.md` | commands | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r204 | `./commands/discuss.md` | commands | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r205 | `./commands/issue.md` | commands | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r206 | `./commands/merge.md` | commands | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r207 | `./commands/plan.md` | commands | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r208 | `./commands/pr.md` | commands | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r209 | `./commands/review.md` | commands | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r210 | `./commands/skill-create.md` | commands | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r211 | `./commands/slide.md` | commands | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r212 | `./commands/tdd.md` | commands | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r213 | `./commands/update-issue.md` | commands | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r214 | `./commands/verify.md` | commands | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r215 | `./commands/worktree.md` | commands | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r217 | `./hooks/detect-quality-issues.sh` | hooks | modified | 上流の品質検知 hook 改良。Wave 2 で差分採用判定 |
| r014 | `./hooks/prevent-schedulewakeup-misuse.sh` | hooks | added | TOP10 外。汎用化検討対象 |
| r025 | `./references/3-layer-architecture.md` | references | added | TOP10 外。汎用化検討対象 |
| r219 | `./references/README.md` | references | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r026 | `./references/agent-essence.md` | references | added | TOP10 外。汎用化検討対象 |
| r220 | `./references/applicable-skills.md` | references | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r028 | `./references/auto-mode-gate-template.md` | references | added | TOP10 外。汎用化検討対象 |
| r029 | `./references/baseline-measurement.md` | references | added | TOP10 外。汎用化検討対象 |
| r030 | `./references/facilitation-best-practices.md` | references | added | TOP10 外。汎用化検討対象 |
| r035 | `./rules/admin-ui-patterns.md` | rules | added | TOP10 外。汎用化検討対象 |
| r221 | `./rules/branch-naming.md` | rules | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r222 | `./rules/brand.md` | rules | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r223 | `./rules/cli-first.md` | rules | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r224 | `./rules/commit-messages.md` | rules | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r225 | `./rules/completion-quality.md` | rules | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r226 | `./rules/docdd-frontmatter.md` | rules | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r227 | `./rules/file-naming.md` | rules | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r228 | `./rules/issue-workflow.md` | rules | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r039 | `./rules/language.md` | rules | added | TOP10 外。汎用化検討対象 |
| r229 | `./rules/project-workflow.md` | rules | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r042 | `./rules/schedulewakeup-safety.md` | rules | added | TOP10 外。汎用化検討対象 |
| r230 | `./rules/tdd-gate.md` | rules | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r231 | `./rules/terminology.md` | rules | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r232 | `./rules/test-fixtures.md` | rules | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r043 | `./rules/test-layout.md` | rules | added | TOP10 外。汎用化検討対象 |
| r234 | `./skills/README.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r235 | `./skills/agent-teams/SKILL.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r044 | `./skills/auto-mode-guard/SKILL.md` | skills | added | TOP10 外。汎用化検討対象 |
| r045 | `./skills/auto-mode-guard/eval.md` | skills | added | TOP10 外。汎用化検討対象 |
| r236 | `./skills/backend-patterns/SKILL.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r237 | `./skills/backend-patterns/references/api-design.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r238 | `./skills/backend-patterns/references/ddd-patterns.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r239 | `./skills/backend-patterns/references/dependency-injection.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r240 | `./skills/backend-patterns/references/error-handling.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r241 | `./skills/backend-patterns/references/middleware.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r242 | `./skills/backend-patterns/references/testing.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r243 | `./skills/delegate-explorer/SKILL.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r244 | `./skills/delegate-planner/SKILL.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r048 | `./skills/design-system/SKILL.md` | skills | added | TOP10 外。汎用化検討対象 |
| r049 | `./skills/design-system/references/pencil-workflow.md` | skills | added | TOP10 外。汎用化検討対象 |
| r245 | `./skills/docdd-workflow/SKILL.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r246 | `./skills/frontend-patterns/SKILL.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r247 | `./skills/frontend-patterns/references/auth-error-handling.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r248 | `./skills/frontend-patterns/references/cache-strategy.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r249 | `./skills/frontend-patterns/references/component-design.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r250 | `./skills/frontend-patterns/references/data-fetching.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r251 | `./skills/frontend-patterns/references/rendering-strategy.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r252 | `./skills/issue-sizing/SKILL.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r253 | `./skills/parallel-development/SKILL.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r254 | `./skills/planning-quality/SKILL.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r255 | `./skills/presentation/SKILL.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r063 | `./skills/presentation/eval.md` | skills | added | TOP10 外。汎用化検討対象 |
| r256 | `./skills/presentation/references/layout-patterns.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r257 | `./skills/presentation/references/marp-syntax.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r067 | `./skills/presentation/references/templates/general.md` | skills | added | 未分類フォールバック（要レビュー） |
| r258 | `./skills/receiving-code-review/SKILL.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r259 | `./skills/ref-agent-skill/SKILL.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r260 | `./skills/ref-skill-component-design/SKILL.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r261 | `./skills/run-skill-creator/SKILL.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r071 | `./skills/run-skill-creator/references/description-optimization.md` | skills | added | 未分類フォールバック（要レビュー） |
| r262 | `./skills/systematic-debugging/SKILL.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r263 | `./skills/tdd-workflow/SKILL.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r264 | `./skills/test-design/SKILL.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r265 | `./skills/testing-patterns/SKILL.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r079 | `./skills/testing-patterns/eval.md` | skills | added | TOP10 外。汎用化検討対象 |
| r266 | `./skills/traceability-automation/SKILL.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r080 | `./skills/traceability-automation/eval.md` | skills | added | TOP10 外。汎用化検討対象 |
| r267 | `./skills/update-knowledge/SKILL.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r268 | `./skills/verification-before-completion/SKILL.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r269 | `./skills/verify-input-capture/SKILL.md` | skills | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r081 | `./skills/verify-input-capture/eval.md` | skills | added | TOP10 外。汎用化検討対象 |
| r084 | `./templates/codex-consult-handoff.md` | templates | added | TOP10 外。汎用化検討対象 |
| r085 | `./templates/codex-reverify-handoff.md` | templates | added | TOP10 外。汎用化検討対象 |
| r270 | `./templates/codex-review-handoff.md` | templates | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r086 | `./templates/evidence-manifest.yaml` | templates | added | TOP10 外。汎用化検討対象 |
| r271 | `./templates/implementation-summary-comment.md` | templates | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r272 | `./templates/independent-review-result-comment.md` | templates | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r273 | `./templates/issue-implementation-plan.md` | templates | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |
| r274 | `./templates/verification-result-comment.md` | templates | modified | 上流改良あり。Wave 2 以降で差分レビュー → 採用可否判定（既存実装に部分採用 or 全体置換） |

### W3（12 件）

| # | path | category | change_type | notes |
|:-:|------|----------|:-----------:|-------|
| r036 | `./rules/command-self-healing.md` | rules | added | TOP10 外。汎用化検討対象 |
| r037 | `./rules/failure-escalation.md` | rules | added | TOP10 外。汎用化検討対象 |
| r040 | `./rules/multi-model-review.md` | rules | added | TOP10 候補（汎用化・再設計が必要） |
| r054 | `./skills/ephemeral-session-memory/SKILL.md` | skills | added | TOP10 外。汎用化検討対象 |
| r055 | `./skills/ephemeral-session-memory/eval.md` | skills | added | TOP10 外。汎用化検討対象 |
| r061 | `./skills/llm-debate/SKILL.md` | skills | added | TOP10 候補（汎用化・再設計が必要） |
| r062 | `./skills/llm-debate/eval.md` | skills | added | TOP10 候補（汎用化・再設計が必要） |
| r069 | `./skills/review-orchestrator/SKILL.md` | skills | added | TOP10 候補（汎用化・再設計が必要） |
| r070 | `./skills/review-orchestrator/eval.md` | skills | added | TOP10 候補（汎用化・再設計が必要） |
| r083 | `./templates/browser-check-result.md` | templates | added | TOP10 外。汎用化検討対象 |
| r087 | `./templates/post-merge-implementation-summary.md` | templates | added | TOP10 外。汎用化検討対象 |
| r089 | `./templates/user-acceptance-check.md` | templates | added | TOP10 外。汎用化検討対象 |

### W4（3 件）

| # | path | category | change_type | notes |
|:-:|------|----------|:-----------:|-------|
| r034 | `./references/rules-index.md` | references | added | TOP10 外。汎用化検討対象 |
| r059 | `./skills/harness-capability-probe/SKILL.md` | skills | added | TOP10 外。汎用化検討対象 |
| r060 | `./skills/harness-capability-probe/eval.md` | skills | added | TOP10 外。汎用化検討対象 |

## Document only（全件 — ローカル保持 / 参照のみ）

| # | path | category | change_type | notes |
|:-:|------|----------|:-----------:|-------|
| r046 | `./skills/backend-patterns/references/ecs-deployment.md` | skills | added | ECS/perf reference の上流改良。docdd-starters は references/guide に reflect 程度で十分 |
| r056 | `./skills/frontend-patterns/references/ecs-deployment.md` | skills | added | ECS/perf reference の上流改良。docdd-starters は references/guide に reflect 程度で十分 |
| r057 | `./skills/frontend-patterns/references/performance-optimization.md` | skills | added | ECS/perf reference の上流改良。docdd-starters は references/guide に reflect 程度で十分 |
| r179 | `./references/capability-matrix.md` | references | removed | ローカル独自 governance file。上流側で削除されたが docdd-starters は SSOT として保持。drift として解消しない |
| r180 | `./rules/README.md` | rules | removed | ローカル独自 governance file。上流側で削除されたが docdd-starters は SSOT として保持。drift として解消しない |
| r181 | `./rules/agent-teams.md` | rules | removed | ローカル独自 governance file。上流側で削除されたが docdd-starters は SSOT として保持。drift として解消しない |
| r182 | `./rules/codex-review.md` | rules | removed | ローカル独自 governance file。上流側で削除されたが docdd-starters は SSOT として保持。drift として解消しない |
| r183 | `./rules/command-trailer.md` | rules | removed | ローカル独自 governance file。上流側で削除されたが docdd-starters は SSOT として保持。drift として解消しない |
| r184 | `./rules/issue-sizing.md` | rules | removed | ローカル独自 governance file。上流側で削除されたが docdd-starters は SSOT として保持。drift として解消しない |
| r185 | `./rules/planning-quality.md` | rules | removed | ローカル独自 governance file。上流側で削除されたが docdd-starters は SSOT として保持。drift として解消しない |
| r186 | `./skills/assign-agent-skill-evaluator/SKILL.md` | skills | removed | ローカル独自 governance file。上流側で削除されたが docdd-starters は SSOT として保持。drift として解消しない |
| r187 | `./skills/assign-agent-skill-evaluator/eval-schema.json` | skills | removed | ローカル独自 governance file。上流側で削除されたが docdd-starters は SSOT として保持。drift として解消しない |
| r188 | `./skills/delegate-codex/SKILL.md` | skills | removed | ローカル独自 governance file。上流側で削除されたが docdd-starters は SSOT として保持。drift として解消しない |
| r189 | `./skills/delegate-codex/codex-delegate.sh` | skills | removed | ローカル独自 governance file。上流側で削除されたが docdd-starters は SSOT として保持。drift として解消しない |
| r190 | `./skills/design/SKILL.md` | skills | removed | ローカル独自 governance file。上流側で削除されたが docdd-starters は SSOT として保持。drift として解消しない |
| r191 | `./skills/design/pencil-workflow.md` | skills | removed | ローカル独自 governance file。上流側で削除されたが docdd-starters は SSOT として保持。drift として解消しない |
| r192 | `./skills/presentation/references/themes/minimal.css` | skills | removed | ローカル独自 governance file。上流側で削除されたが docdd-starters は SSOT として保持。drift として解消しない |
| r193 | `./skills/run-skill-creator/description-optimization.md` | skills | removed | ローカル独自 governance file。上流側で削除されたが docdd-starters は SSOT として保持。drift として解消しない |
| r194 | `./templates/codex-plan-review-prompt.md` | templates | removed | ローカル独自 governance file。上流側で削除されたが docdd-starters は SSOT として保持。drift として解消しない |
| r195 | `./templates/codex-verify-review-prompt.md` | templates | removed | ローカル独自 governance file。上流側で削除されたが docdd-starters は SSOT として保持。drift として解消しない |
| r196 | `./templates/pr-body.md` | templates | removed | ローカル独自 governance file。上流側で削除されたが docdd-starters は SSOT として保持。drift として解消しない |
| r197 | `./templates/verify-issue-result.json` | templates | removed | ローカル独自 governance file。上流側で削除されたが docdd-starters は SSOT として保持。drift として解消しない |

## Reject（全件 — 採否理由 + 再評価トリガつき）

### Project field 連携（1 件）

| # | path | change_type | reject_reason | reevaluation_trigger |
|:-:|------|:-----------:|---------------|---------------------|
| r031 | `./references/github-project-fields.md` | added | docdd-starters は label 運用採用済（project-workflow.md） | label 運用が破綻し Project 運用へ移行する判断が出たとき |

### STG 前提 UI 検証（8 件）

| # | path | change_type | reject_reason | reevaluation_trigger |
|:-:|------|:-----------:|---------------|---------------------|
| r072 | `./skills/screen-verify/SKILL.md` | added | STG URL / secret 前提のため汎用化困難 | STG 非依存の代替テスト手法が確立したとき |
| r073 | `./skills/screen-verify/eval.md` | added | STG URL / secret 前提のため汎用化困難 | STG 非依存の代替テスト手法が確立したとき |
| r074 | `./skills/screen-verify/references/email-verification.md` | added | STG URL / secret 前提のため汎用化困難 | STG 非依存の代替テスト手法が確立したとき |
| r075 | `./skills/screen-verify/references/input-validation.md` | added | STG URL / secret 前提のため汎用化困難 | STG 非依存の代替テスト手法が確立したとき |
| r076 | `./skills/screen-verify/references/stg-preflight.md` | added | STG URL / secret 前提のため汎用化困難 | STG 非依存の代替テスト手法が確立したとき |
| r077 | `./skills/screen-verify/references/stg-seed-recovery.md` | added | STG URL / secret 前提のため汎用化困難 | STG 非依存の代替テスト手法が確立したとき |
| r078 | `./skills/screen-verify/references/triage.md` | added | STG URL / secret 前提のため汎用化困難 | STG 非依存の代替テスト手法が確立したとき |
| r088 | `./templates/screen-verify-result.md` | added | STG URL / secret 前提のため汎用化困難 | STG 非依存の代替テスト手法が確立したとき |

### org/STG/secret 前提 settings（1 件）

| # | path | change_type | reject_reason | reevaluation_trigger |
|:-:|------|:-----------:|---------------|---------------------|
| r233 | `./settings.json` | modified | 個人/組織前提のため逆移植禁止 | N/A — sanitize 方針と恒久不整合 |

### メール連携（6 件）

| # | path | change_type | reject_reason | reevaluation_trigger |
|:-:|------|:-----------:|---------------|---------------------|
| r008 | `./commands/email.md` | added | Gmail MCP 前提のため Optional/別 plugin 化が筋 | 汎用 plugin / 別配布チャネルができたとき |
| r032 | `./references/gmail-workflow.md` | added | Gmail MCP 前提のため Optional/別 plugin 化が筋 | 汎用 plugin / 別配布チャネルができたとき |
| r050 | `./skills/email-writing/SKILL.md` | added | Gmail MCP 前提のため Optional/別 plugin 化が筋 | 汎用 plugin / 別配布チャネルができたとき |
| r051 | `./skills/email-writing/references/review-checklist.md` | added | Gmail MCP 前提のため Optional/別 plugin 化が筋 | 汎用 plugin / 別配布チャネルができたとき |
| r052 | `./skills/email-writing/references/templates.md` | added | Gmail MCP 前提のため Optional/別 plugin 化が筋 | 汎用 plugin / 別配布チャネルができたとき |
| r053 | `./skills/email-writing/references/tone-guide.md` | added | Gmail MCP 前提のため Optional/別 plugin 化が筋 | 汎用 plugin / 別配布チャネルができたとき |

### 上流ハーネス固有 verify scripts/fixtures（89 件）

| # | path | change_type | reject_reason | reevaluation_trigger |
|:-:|------|:-----------:|---------------|---------------------|
| r090 | `./verify/fixtures-472/bad_find_delete.md` | added | 上流ハーネス自前の per-Issue 検証 script と fixture（上流 Issue 番号紐づけ）。docdd-starters は独自の verify-issue.sh / hooks を持つため逆移植不要 | N/A — 上流組織内テスト前提 |
| r091 | `./verify/fixtures-472/bad_git_push.md` | added | 上流ハーネス自前の per-Issue 検証 script と fixture（上流 Issue 番号紐づけ）。docdd-starters は独自の verify-issue.sh / hooks を持つため逆移植不要 | N/A — 上流組織内テスト前提 |
| r092 | `./verify/fixtures-472/bad_indented_fence.md` | added | 上流ハーネス自前の per-Issue 検証 script と fixture（上流 Issue 番号紐づけ）。docdd-starters は独自の verify-issue.sh / hooks を持つため逆移植不要 | N/A — 上流組織内テスト前提 |
| r093 | `./verify/fixtures-472/bad_ls_abs.md` | added | 上流ハーネス自前の per-Issue 検証 script と fixture（上流 Issue 番号紐づけ）。docdd-starters は独自の verify-issue.sh / hooks を持つため逆移植不要 | N/A — 上流組織内テスト前提 |
| r094 | `./verify/fixtures-472/bad_ls_flag.md` | added | 上流ハーネス自前の per-Issue 検証 script と fixture（上流 Issue 番号紐づけ）。docdd-starters は独自の verify-issue.sh / hooks を持つため逆移植不要 | N/A — 上流組織内テスト前提 |
| r095 | `./verify/fixtures-472/bad_ls_glob.md` | added | 上流ハーネス自前の per-Issue 検証 script と fixture（上流 Issue 番号紐づけ）。docdd-starters は独自の verify-issue.sh / hooks を持つため逆移植不要 | N/A — 上流組織内テスト前提 |
| r096 | `./verify/fixtures-472/bad_ls_traversal.md` | added | 上流ハーネス自前の per-Issue 検証 script と fixture（上流 Issue 番号紐づけ）。docdd-starters は独自の verify-issue.sh / hooks を持つため逆移植不要 | N/A — 上流組織内テスト前提 |
| r097 | `./verify/fixtures-472/bad_node_eval.md` | added | 上流ハーネス自前の per-Issue 検証 script と fixture（上流 Issue 番号紐づけ）。docdd-starters は独自の verify-issue.sh / hooks を持つため逆移植不要 | N/A — 上流組織内テスト前提 |
| r098 | `./verify/fixtures-472/bad_pipe.md` | added | 上流ハーネス自前の per-Issue 検証 script と fixture（上流 Issue 番号紐づけ）。docdd-starters は独自の verify-issue.sh / hooks を持つため逆移植不要 | N/A — 上流組織内テスト前提 |
| r099 | `./verify/fixtures-472/bad_redirect.md` | added | 上流ハーネス自前の per-Issue 検証 script と fixture（上流 Issue 番号紐づけ）。docdd-starters は独自の verify-issue.sh / hooks を持つため逆移植不要 | N/A — 上流組織内テスト前提 |
| r100 | `./verify/fixtures-472/bad_subshell.md` | added | 上流ハーネス自前の per-Issue 検証 script と fixture（上流 Issue 番号紐づけ）。docdd-starters は独自の verify-issue.sh / hooks を持つため逆移植不要 | N/A — 上流組織内テスト前提 |
| r101 | `./verify/fixtures-472/false_positive_image.md` | added | 上流ハーネス自前の per-Issue 検証 script と fixture（上流 Issue 番号紐づけ）。docdd-starters は独自の verify-issue.sh / hooks を持つため逆移植不要 | N/A — 上流組織内テスト前提 |
| r102 | `./verify/fixtures-472/safe_basic.md` | added | 上流ハーネス自前の per-Issue 検証 script と fixture（上流 Issue 番号紐づけ）。docdd-starters は独自の verify-issue.sh / hooks を持つため逆移植不要 | N/A — 上流組織内テスト前提 |
| r103 | `./verify/fixtures-474/auto_mode_decision_table.yml` | added | 上流ハーネス自前の per-Issue 検証 script と fixture（上流 Issue 番号紐づけ）。docdd-starters は独自の verify-issue.sh / hooks を持つため逆移植不要 | N/A — 上流組織内テスト前提 |
| r104 | `./verify/fixtures-582/broken-link.md` | added | 上流ハーネス自前の per-Issue 検証 script と fixture（上流 Issue 番号紐づけ）。docdd-starters は独自の verify-issue.sh / hooks を持つため逆移植不要 | N/A — 上流組織内テスト前提 |
| r105 | `./verify/fixtures-582/digit-only-name.md` | added | 上流ハーネス自前の per-Issue 検証 script と fixture（上流 Issue 番号紐づけ）。docdd-starters は独自の verify-issue.sh / hooks を持つため逆移植不要 | N/A — 上流組織内テスト前提 |
| r106 | `./verify/fixtures-582/duplicate-gate.md` | added | 上流ハーネス自前の per-Issue 検証 script と fixture（上流 Issue 番号紐づけ）。docdd-starters は独自の verify-issue.sh / hooks を持つため逆移植不要 | N/A — 上流組織内テスト前提 |
| r107 | `./verify/fixtures-582/empty-symptom.md` | added | 上流ハーネス自前の per-Issue 検証 script と fixture（上流 Issue 番号紐づけ）。docdd-starters は独自の verify-issue.sh / hooks を持つため逆移植不要 | N/A — 上流組織内テスト前提 |
| r108 | `./verify/fixtures-582/malformed-marker.md` | added | 上流ハーネス自前の per-Issue 検証 script と fixture（上流 Issue 番号紐づけ）。docdd-starters は独自の verify-issue.sh / hooks を持つため逆移植不要 | N/A — 上流組織内テスト前提 |
| r109 | `./verify/fixtures-582/marker-bullet-mismatch.md` | added | 上流ハーネス自前の per-Issue 検証 script と fixture（上流 Issue 番号紐づけ）。docdd-starters は独自の verify-issue.sh / hooks を持つため逆移植不要 | N/A — 上流組織内テスト前提 |
| r110 | `./verify/fixtures-582/misplaced-section.md` | added | 上流ハーネス自前の per-Issue 検証 script と fixture（上流 Issue 番号紐づけ）。docdd-starters は独自の verify-issue.sh / hooks を持つため逆移植不要 | N/A — 上流組織内テスト前提 |
| r111 | `./verify/fixtures-582/missing-heading.md` | added | 上流ハーネス自前の per-Issue 検証 script と fixture（上流 Issue 番号紐づけ）。docdd-starters は独自の verify-issue.sh / hooks を持つため逆移植不要 | N/A — 上流組織内テスト前提 |
| r112 | `./verify/fixtures-582/no-separator.md` | added | 上流ハーネス自前の per-Issue 検証 script と fixture（上流 Issue 番号紐づけ）。docdd-starters は独自の verify-issue.sh / hooks を持つため逆移植不要 | N/A — 上流組織内テスト前提 |
| r113 | `./verify/fixtures-582/non-kebab-name.md` | added | 上流ハーネス自前の per-Issue 検証 script と fixture（上流 Issue 番号紐づけ）。docdd-starters は独自の verify-issue.sh / hooks を持つため逆移植不要 | N/A — 上流組織内テスト前提 |
| r114 | `./verify/fixtures-582/pipe-in-field.md` | added | 上流ハーネス自前の per-Issue 検証 script と fixture（上流 Issue 番号紐づけ）。docdd-starters は独自の verify-issue.sh / hooks を持つため逆移植不要 | N/A — 上流組織内テスト前提 |
| r115 | `./verify/fixtures-592/README.md` | added | 上流ハーネス自前の per-Issue 検証 script と fixture（上流 Issue 番号紐づけ）。docdd-starters は独自の verify-issue.sh / hooks を持つため逆移植不要 | N/A — 上流組織内テスト前提 |
| r116 | `./verify/fixtures-592/commits_clean_refs.txt` | added | 上流ハーネス自前の per-Issue 検証 script と fixture（上流 Issue 番号紐づけ）。docdd-starters は独自の verify-issue.sh / hooks を持つため逆移植不要 | N/A — 上流組織内テスト前提 |
| r117 | `./verify/fixtures-592/commits_with_closes.txt` | added | 上流ハーネス自前の per-Issue 検証 script と fixture（上流 Issue 番号紐づけ）。docdd-starters は独自の verify-issue.sh / hooks を持つため逆移植不要 | N/A — 上流組織内テスト前提 |
| r118 | `./verify/fixtures-592/pr_body_closes_no_ui.md` | added | 上流ハーネス自前の per-Issue 検証 script と fixture（上流 Issue 番号紐づけ）。docdd-starters は独自の verify-issue.sh / hooks を持つため逆移植不要 | N/A — 上流組織内テスト前提 |
| r119 | `./verify/fixtures-592/pr_body_refs_screen_no_keyword.md` | added | 上流ハーネス自前の per-Issue 検証 script と fixture（上流 Issue 番号紐づけ）。docdd-starters は独自の verify-issue.sh / hooks を持つため逆移植不要 | N/A — 上流組織内テスト前提 |
| ... | (+59 件、全件は [`baseline-commits.json`](./baseline-commits.json) 参照) | | | |

### 上流内部 plan doc（1 件）

| # | path | change_type | reject_reason | reevaluation_trigger |
|:-:|------|:-----------:|---------------|---------------------|
| r009 | `./docs/plans/skill-reorganization-after-624.md` | added | 上流の作業計画 doc。汎用テンプレに持ち込まない | N/A — 上流組織前提 |

### 上流組織ガバナンス YAML（3 件）

| # | path | change_type | reject_reason | reevaluation_trigger |
|:-:|------|:-----------:|---------------|---------------------|
| r022 | `./policies/__index__.yaml` | added | 上流組織の内部運用 policy。汎用化されていない | N/A — 上流組織前提 |
| r023 | `./policies/landing-path-state.yaml` | added | 上流組織の内部運用 policy。汎用化されていない | N/A — 上流組織前提 |
| r024 | `./policies/review-deferral-policy.yaml` | added | 上流組織の内部運用 policy。汎用化されていない | N/A — 上流組織前提 |

### 実験物（1 件）

| # | path | change_type | reject_reason | reevaluation_trigger |
|:-:|------|:-----------:|---------------|---------------------|
| r058 | `./skills/grandchild-agent-chain-experiment/SKILL.md` | added | 実験ステータスのため churn 高、本 baseline では不採用 | 上流で stable 化 + 半年以上の churn 低下が観測されたとき |

### 特定ドメイン業務（2 件）

| # | path | change_type | reject_reason | reevaluation_trigger |
|:-:|------|:-----------:|---------------|---------------------|
| r001 | `./agents/billing-agent.md` | added | docdd-starters は汎用テンプレ。決済ドメインを持ち込まない | N/A — 汎用化方針と恒久不整合 |
| r047 | `./skills/billing-domain/SKILL.md` | added | docdd-starters は汎用テンプレ。決済ドメインを持ち込まない | N/A — 汎用化方針と恒久不整合 |

### 組織ブランド資産（4 件）

| # | path | change_type | reject_reason | reevaluation_trigger |
|:-:|------|:-----------:|---------------|---------------------|
| r064 | `./skills/presentation/references/assets/logos/<上流組織ロゴ>_H.jpg` | added | 上流組織のロゴ・テーマ資産 | N/A — sanitize 方針と恒久不整合 |
| r065 | `./skills/presentation/references/assets/logos/<上流組織ロゴ>_W.jpg` | added | 上流組織のロゴ・テーマ資産 | N/A — sanitize 方針と恒久不整合 |
| r066 | `./skills/presentation/references/assets/logos/<上流組織ロゴ>_white.png` | added | 上流組織のロゴ・テーマ資産 | N/A — sanitize 方針と恒久不整合 |
| r068 | `./skills/presentation/references/themes/<上流組織テーマ>.css` | added | 上流組織のロゴ・テーマ資産 | N/A — sanitize 方針と恒久不整合 |

### 週次/月次レポート（1 件）

| # | path | change_type | reject_reason | reevaluation_trigger |
|:-:|------|:-----------:|---------------|---------------------|
| r082 | `./skills/weekly-report/SKILL.md` | added | OSS テンプレに組織運用前提を持ち込まない | N/A — 汎用化方針と恒久不整合 |

## 分類方法（再現性確保）

1. **drift inventory 生成**（V4 機械検証）: 両側に対して `find . -type f -exec shasum -a 256 {} \;` で manifest 作成 → path-key join で `added` / `removed` / `modified` を集計
2. **Reject 既定の機械適用**: 7 カテゴリ（特定ドメイン業務 / 週次月次レポート / メール連携 / STG 前提 UI / Project field 連携 / 実験物 / org・STG・secret 前提）と上流組織固有（verify/ / policies/ / docs/plans/ / 上流組織ブランド資産）を path predicate で先に flag
3. **TOP10 explicit assignment**: Issue 本文の TOP10 候補は暫定区分どおり Adopt now / Adapt later に固定。Wave は計画固定
4. **残余の分類**: 計画立案時に同定された hooks 安全強化 / rules 追加（admin-ui-patterns / language / test-layout 等）/ references 追加 / templates 追加 / 汎用 agents は Adapt later W2 ベースに分類。modified core files (commands / skills / rules / templates / references) は default Adapt later W2 とし、差分レビューと部分採用判定は per-Wave 子 Issue へ deferred
5. **`removed` 種別の扱い**: ローカルのみ存在するファイルは docdd-starters の SSOT として保持。`Document only` に分類して「上流側で削除されたが我々は維持」と明記

評価軸スコア (`fork_immediacy × genericity × core_coupling ÷ maintenance_cost`) は **TOP10 のみ per-item 入力** し、他は `null`。理由: 274 件を主観で per-item 採点すると再現性が崩れるため、Reject 既定 / TOP10 / dir+change_type の rule-based 分類を一次根拠とし、TOP10 のみスコア提示で audit 透明性を担保する。

## 再評価トリガ運用

- `Reject` 全件に `reject_reason` と `reevaluation_trigger` を必須記録（trigger 空欄禁止）
- `N/A — ...` は「永久 reject」を意味し、`/plan` Phase 1 での再検討対象外（汎用化方針と恒久不整合なもの）
- それ以外の trigger（汎用 plugin 登場 / STG 非依存代替 / label 運用破綻 / 上流 stable 化）が **観測可能になった月次監査** で該当 record を **v0.X 新 baseline に re-emit** することで再分類する（既存 record は immutable）

## 再現コマンド（本 audit を別 baseline で再実行する場合）

```bash
# 1) baseline SHA を取得・固定
REMOTE_SHA=$(git ls-remote <上流参照ハーネス URL> refs/heads/main | awk '{print $1}')
git -C /tmp/<上流参照> fetch origin $REMOTE_SHA --depth 1
# overlay 防止: 上流で削除/リネームされた path が manifest に残らないよう .claude/ を毎回掃除する
rm -rf /tmp/<上流参照>/.claude
git -C /tmp/<上流参照> checkout FETCH_HEAD -- .claude/

# 2) 両側 manifest（local 側は untracked file による bogus removed drift を防ぐため git ls-files で tracked に限定）
(cd /tmp/<上流参照>/.claude && find . -type f -exec shasum -a 256 {} \;) | sort > /tmp/upstream_manifest.txt
(cd .claude && git ls-files . | xargs -I{} shasum -a 256 ./{}) | sort > /tmp/local_manifest.txt

# 3) drift 集計（added/removed/modified）— Python で path-key join
# scripts/upstream-sync/ 配下に audit script を Wave 4 で配置予定
```

> 上流参照 URL は OSS sanitize 規約に従い本 doc にハードコードしない（[`monthly-audit-procedure.md`](./monthly-audit-procedure.md) の内部 memo 参照節に集約）
