# モジュラーモノリス構成ガイド

このドキュメントはスタータープロジェクトで採用しているモジュラーモノリス構成の考え方をまとめたものです。

## レイヤ構造

- **core**: 設定やロギングなど、アプリケーション全体で共有する基盤コード
- **kernel**: モジュール検出、DI、ルータ組み立てなどの土台。モジュラーモノリスの中核となる
- **modules**: バウンデッドコンテキスト単位で機能をまとめる。`manifest.py` を必ず用意
- **shared**: DB クライアントやメッセージングなど、どのモジュールからも利用される共有ライブラリ
- **tests**: アプリケーション全体のテストや共通フィクスチャ

## ディレクトリ構成

```
apps/backend/
├── README.md
├── pyproject.toml
├── pytest.ini
└── app/
    ├── main.py              # FastAPI アプリのエントリーポイント
    ├── contracts/           # DTO・イベントなどの共有契約
    │   ├── dto/
    │   ├── errors/
    │   └── events/
    ├── core/                # 設定・ロギングなどの共通基盤
    │   ├── config.py
    │   └── logging.py
    ├── kernel/              # モジュールローダー、ルータ組み立て、DI
    │   ├── app.py
    │   ├── module_loader.py
    │   └── router.py
    ├── infrastructure/      # 外部システム接続（HTTPクライアント、キュー、ストレージなど）
    │   ├── README.md
    │   ├── adapters/
    │   │   └── README.md
    │   ├── auth/
    │   │   └── README.md
    │   ├── database/
    │   │   └── __init__.py
    │   └── external/
    │       └── README.md
    ├── modules/             # バウンデッドコンテキストごとの機能モジュール
    │   └── example/
    │       ├── manifest.py
    │       ├── api/
    │       ├── domain/      # ドメインモデル・値オブジェクト
    │       ├── repositories/
    │       ├── schemas/     # API/DTO 用 Pydantic モデル
    │       ├── services/    # アプリケーション/ユースケースサービス
    │       └── tests/
    ├── dependencies.py      # FastAPI の Depends 用共通関数
    ├── shared/              # 横断的な共通機能（再輸出など）
    ├── middlewares/         # ロギングやトレーシングのミドルウェア
    │   └── README.md
    └── tests/               # アプリ全体向けのテスト
        └── test_app_bootstrap.py
```

### ディレクトリ補足

- `contracts/`: サービス間で共有する DTO やイベント、エラー定義を配置。`dto/`、`events/`、`errors/` に分け、外部公開やメッセージングの契約を管理する。
- `infrastructure/`: 外部 API やメッセージングなどのアダプタ層。`auth/` に認証プロバイダ、`database/` には SQLAlchemy セッション管理、`adapters/` にプロトコル別実装、`external/` に第三者サービス固有のクライアントを配置し、各モジュールから直接呼ばずリポジトリ経由で利用する。
- `modules/<name>/domain/`: ドメインモデル・値オブジェクト・ドメインサービスを配置。ビジネスルールはここで完結させる。
- `modules/<name>/repositories/`: 永続化の抽象を定義。具象実装は `infrastructure/` かモジュール内に作成し、DI で差し替え可能にする。
- `modules/<name>/services/`: ユースケースやアプリケーションサービス。ドメインとインフラの橋渡しを行い、FastAPI からはここを呼び出す。
- `shared/`: 複数モジュールで共有するクロスカッティング機能。設定やトレーサビリティ、インフラ層の再輸出など。
- `dependencies.py`: FastAPI の `Depends` で利用する共通依存を定義。DB セッションや認証情報の解決などを一元管理。
- `middlewares/`: ロギング・トレーシング・監査など、アプリ全体に掛けるミドルウェアを配置する。

## データベース設定

- 接続先は `app/core/config.py` の `AppSettings.database_url` で管理し、`.env` (`.env.example` を参照) から `DATABASE_URL` を設定する。
- 非同期 SQLAlchemy エンジンとセッションは `app/infrastructure/database/__init__.py` に定義。FastAPI の `Depends` で `get_session()` を利用し、SQLAlchemy `AsyncSession` を取得する。
- モジュール側ではリポジトリを通じてセッションを受け取り、直接 `create_async_engine` を呼ばないようにする。
- マイグレーションを導入する場合は `alembic/` を追加し、`DATABASE_URL` と同じ設定を利用して管理する。

## モジュール作成フロー

1. `app/modules/<module_name>/` を作成し、`__init__.py` と `manifest.py` を配置する。
2. API レイヤ (`api/routes.py`)、ドメイン (`domain/`)、リポジトリ (`repositories/`)、サービス (`services/`)、スキーマ (`schemas/`) を作成し、`manifest.py` から必要な router を公開する。
3. `ModuleLoader.allowed_modules` にモジュール名を追加し、テストはリポジトリ直下の `tests/backend` に配置する。
4. 7-axis ドキュメント（UC, SR, API, TC など）と `traces_to` / `traces_from` を更新し、ビジネス要求との整合を確認する。
5. 外部サービス接続が必要な場合は `app/infrastructure/` にアダプタを実装し、モジュールのリポジトリ経由で利用する。

## テストとトレーサビリティ

- 7-axis の `TC` / `TS` にはテストコマンドやジョブ名を記載し、コード側では `tests/` 配下でレイヤに応じたテスト（unit / integration / e2e など）を管理する。
- `tests/` ディレクトリ内に README を追加してレイヤ分けの方針や実行コマンドを書いておくと、7-axis との紐付けや CI 実行がスムーズになる。
- Traceability map を更新する際は `python scripts/test/validate_traceability_map.py` を実行し、7-axis ドキュメントとテスト実装の整合性を確認する。

## 依存ガバナンス

- モジュール間の依存は `manifest.py` の `dependencies` 配列に宣言する。
- 共有ロジックが必要な場合は `shared/` にインターフェースを置き、モジュール側では抽象化されたリポジトリ経由でアクセスする。
- イベント駆動に切り替える場合は `kernel/` にシンプルなメッセージバスを追加し、`modules/<name>/event_handlers/` を作成する形式を想定。

## 今後の拡張例

- `kernel/di.py` を追加して手軽な依存注入を行えるようにする
- `alembic/` ディレクトリを追加して各モジュールのマイグレーションを管理する
- 監視やエラートラッキングの設定を `core/` に取り込む
- `infrastructure/monitoring/` や `core/feature_flags/` などを追加し、プロジェクトの成長に合わせて拡張する

このスターターを基に、プロジェクト要件に合わせて柔軟にカスタマイズしてください。
