# External Integrations

外部システム向けのクライアントやフェッチャーを配置します。

- REST / SOAP / GraphQL など第三者 API
- 監視・通知サービスとの連携コード
- 認証プロバイダ以外の Outbound 接続

`adapters/` と組み合わせて、モジュール側からは抽象化されたポートを通じて利用してください。
