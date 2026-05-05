---
description: run-skill-creator を起動し、Step 0–8 で新しい Skill を設計・採点して提示します。
argument-hint: "<skill description>"
disable-model-invocation: true
---

`$ARGUMENTS` を入力として `run-skill-creator` skill に委譲します。Step 0–8（適格性 → 4 軸判定 → 起草 → description 最適化 → セルフチェック → assign-agent-skill-evaluator レビュー → 提示）の手順は本コマンドでは持たず、SKILL.md 側に SSOT を置きます（命令の二重管理を避けるため）。

## 起動

Skill ツールで委譲してください:

```
Skill({ skill: "run-skill-creator", args: "$ARGUMENTS" })
```

## 詳細

- 手順・適格性判定・prefix 決定木・description 最適化・evaluator レビュー契約は [.claude/skills/run-skill-creator/SKILL.md](../skills/run-skill-creator/SKILL.md) を参照
- 採点 schema・breakdown キーは [.claude/skills/assign-agent-skill-evaluator/SKILL.md](../skills/assign-agent-skill-evaluator/SKILL.md) と並置の `eval-schema.json` を参照
- 設計原則（4 軸 / 5 prefix / 共通ルール）は [.claude/skills/ref-agent-skill/SKILL.md](../skills/ref-agent-skill/SKILL.md) を参照
