# FastAPI モジュラーモノリス スターター

このスターターは FastAPI でモジュラーモノリス構成を立ち上げたいときの最小セットを提供します。  
`app/modules/` 配下にバウンデッドコンテキスト単位のモジュールを追加し、`ModuleManifest` によって依存関係と公開 API を宣言します。

## ディレクトリ構成

```
app/
  contracts/   # DTO・イベントなどサービス間契約
    dto/
    errors/
    events/
  core/        # アプリ全体で共有する設定・ユーティリティ
  kernel/      # モジュール登録や DI、ルータ組み立てなどの土台
  infrastructure/ # 外部サービス接続やアダプタ
    adapters/    # HTTP/gRPC などプロトコル別実装
    auth/        # 認証プロバイダのアダプタ (Supabase 等を差し替え)
    external/    # 外部サービス固有のクライアント
  modules/     # 各コンテキストのモジュール (example はサンプル)
    <name>/
      api/          # FastAPI ルータ
      domain/       # ドメインモデル・値オブジェクト
      repositories/ # 永続化抽象と具象
      services/     # ユースケース層
      schemas/      # DTO/Pydantic モデル
  dependencies.py # FastAPI Depends 用の共通関数
  middlewares/   # アプリ共通ミドルウェア
  shared/      # 共有ライブラリ (DB、イベント、メールなど)
  tests/       # アプリ全体のテスト (モジュール局所テストは modules/<name>/tests/)
```

- モジュールは `manifest.py` を通じて kernel に登録され、`router_registry` が FastAPI アプリへ自動でマウントします。
- 外部 I/O（DB、メッセージング、認証等）は `infrastructure/` でアダプタ化し、`shared/` の共通機能やモジュールのリポジトリを経由して利用します。認証プロバイダは `infrastructure/auth/`、プロトコル別実装は `infrastructure/adapters/`、サービス固有クライアントは `infrastructure/external/` に配置することで差し替えを容易にします。
- DI・アプリ初期化は `kernel/app.py` を拡張して行います。
- DB 接続は `.env` の `DATABASE_URL` を通じて設定し、`infrastructure/database/__init__.py` の `get_session()` を介して `AsyncSession` を取得します。

## 使い方

1. `pyproject.toml` をプロジェクトの要件に合わせて編集し、`poetry` もしくは `pip` で依存関係をインストールする。
2. `app/modules/example` を参考に新しいモジュールディレクトリを作成し、`manifest.py` と `api/routes.py`、サービスレイヤなどを実装する。
3. `app/kernel/module_loader.py` の許可モジュールリストに新しいモジュール名を追加する。
4. `uvicorn app.main:app --reload` で開発サーバを起動する。
   - Docker を利用する場合は `cd docdd-starters && make up` で起動、停止は `make down`

詳細な運用ガイドは `docdd-starters/docs/backend/ARCHITECTURE.md` および 7-axis テンプレートと組み合わせて整備してください。
