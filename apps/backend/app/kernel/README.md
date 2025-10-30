# Kernel パッケージ

モジュラーモノリスの土台となるパッケージです。

- `app.py`: FastAPI アプリを構築し、モジュールローダーを実行。
- `module_loader.py`: `app/modules` を探索して `ModuleManifest` を収集。
- `router.py`: 取得したマニフェストのルータを FastAPI アプリに登録。

必要に応じて DI コンテナやイベントバス、メッセージバスなどを追加し、
モジュール間の連携を強化してください。
