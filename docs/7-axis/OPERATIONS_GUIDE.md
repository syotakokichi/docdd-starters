# 7-Axis 運用ガイド

このガイドは 7-axis トレーサビリティモデルをスターター上で活用する際の基本フローをまとめたものです。

## ドキュメントチェーン

```
BR → UC → DM → SR / NSR → EXT → API → TC
                          ↘ TS
```

- `BR` から `TC` までのチェーンを必ずつなぎ、`traces_to` / `traces_from` を双方向で維持します。
- テスト設計書（`TS`）は `TC` を束ねる補助ドキュメントとして扱い、同じフォルダに管理して問題ありません。

## テンプレートの使い方

1. `docdd-starters/docs/7-axis/_templates/` から該当テンプレートをコピーする。
2. frontmatter のプレースホルダを採番ルール (`BR-{DOMAIN}-{###}` など) に従って埋める。
3. 本文の `TODO` コメントを全て埋め、不要な指示文は削除する。
4. `INDEX.md` を更新し、追加したドキュメントを表に追記する。

## TS / TC の整理方法

- テスト設計書 (`TS`) はシナリオ横断の観点整理に利用し、関連する `TC` を `tc_defines` で列挙します。
- テストケース (`TC`) では自動/手動区分、観点、関連 SR/NSR などを frontmatter で管理し、CI ジョブ名・実行コマンドを `automation` セクションに記載します。
- `docs/testing/traceability/<domain>_map.json` の更新時は `python scripts/test/validate_traceability_map.py` を忘れずに実行してください。

## 推奨ブランチフロー

1. 新しい要求が発生したら BR を作成。
2. UC/DM を追加し、影響範囲を洗い出す。
3. SR/NSR・EXT・API を順に整備し、コード実装と並行して更新。
4. TS と TC を作成し、テスト戦略と自動化の粒度を定義。
5. Traceability map を更新・検証し、Pull Request に結果を添付。

詳しい規約はプロジェクト固有のガイドラインに合わせて調整してください。
