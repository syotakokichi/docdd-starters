# テストケース（軸7）

`../_templates/TC-template.yaml` をベースに、テストタイプや実行方法に応じてカスタマイズしてください。  
テスト設計書を併用する場合は `../_templates/TS-template.md` をコピーし、`tc_defines` で TC を束ねます。

## 作成チェックリスト
- ID は `TC-{DOMAIN}-{###}` の命名規則に従う。
- 対象範囲、前提条件、手順、期待結果、検証方法を明記する。
- `traces_to` で参照する要件（SR/NSR）や API 契約、監視結果にリンクする。
- 自動テストや監視ジョブが存在する場合は `automation.command` などに実行コマンドを残し、`traces_from` に結果参照を書き残す。
