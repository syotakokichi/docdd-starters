# TDD ゲートルール

高リスク領域では **RED → GREEN の証跡** がない限り完了扱いにしない。
RED-GREEN サイクル・証跡チェーン・コマンド・パターンの詳細は [`.claude/skills/tdd-workflow/SKILL.md`](../skills/tdd-workflow/SKILL.md) を参照。

## TDD 必須（RED テスト先行が必要）

| 領域 | 例 |
|------|-----|
| Backend の domain / service / api | service 新設、ビジネスロジック変更 |
| Frontend pure logic（validation / mapper / store / util） | Zod スキーマ変更、Zustand store ロジック変更 |
| 認証・権限 | JWT 検証、権限チェック |
| 状態遷移を含む業務フロー | 申込・契約・決済フロー、ステータス変更 |
| API 契約変更 | request / response / status code 変更 |
| バグ修正（再現できるもの） | 再現テストを先に書く |

## TDD スキップ可（理由を必ず記録。空欄 = 証跡漏れ）

| 理由 | 例 |
|------|-----|
| Pencil 調整のみ / Frontend Presentational のみ | デザイン・CSS・文言変更のみ |
| 既存テストで保護されている配線変更（テスト名を明記） | import パス変更、型エイリアス追加 |
| `.claude/` 内の非実行物のみの変更 | commands・rules・skills・templates・references。**hooks / settings.json / scripts は対象外（挙動変更を含む場合は TDD 必須）** |

> **原則**: 迷ったら TDD 必須として扱う。

## Critical Path との連携

- Critical Path = Critical → 対象領域は原則 TDD 必須
- Critical Path = Non-critical → 上記の判断基準に従う
- 詳細: [`.claude/skills/test-design/SKILL.md`](../skills/test-design/SKILL.md)

## 関連ファイル

- [skills/tdd-workflow/SKILL.md](../skills/tdd-workflow/SKILL.md) - RED-GREEN サイクル・証跡チェーン・パターン集
- [skills/test-design/SKILL.md](../skills/test-design/SKILL.md) - Critical Path 判定・保護レイヤー選択
- [skills/verification-before-completion/SKILL.md](../skills/verification-before-completion/SKILL.md) - 完了主張前のゲート
- [skills/testing-patterns/SKILL.md](../skills/testing-patterns/SKILL.md) - DB フィクスチャ・CI 戦略
- [commands/develop.md](../commands/develop.md) - `/develop` 実装フロー
- [commands/tdd.md](../commands/tdd.md) - `/tdd` RED テスト先行
