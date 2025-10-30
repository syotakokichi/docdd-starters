# ナレッジベース構造

## docs/akfm-knowledge/ ディレクトリ

このディレクトリには、React・Next.js・テストに関する包括的なベストプラクティスドキュメントが格納されています。
**注意**: このディレクトリはBiomeチェック対象外です。

## 主要ドキュメント構成

### 1. Next.js基本原理ガイド (`nextjs-basic-principle/`)
Next.js App Routerの包括的なガイド（36章構成）：

#### Part 1: データ取得 (11章)
**参照タイミング**: データ取得パターンを実装する際
- `part_1_server_components.md` - Server Components設計の基本
- `part_1_colocation.md` - データ取得の配置戦略
- `part_1_request_memoization.md` - リクエスト最適化
- `part_1_concurrent_fetch.md` - 並行データ取得
- `part_1_data_loader.md` - DataLoaderパターン
- `part_1_fine_grained_api_design.md` - API設計戦略
- `part_1_interactive_fetch.md` - インタラクティブなデータ取得

#### Part 2: コンポーネント設計 (5章)
**参照タイミング**: コンポーネント設計・リファクタリング時
- `part_2_client_components_usecase.md` - Client Components使用指針
- `part_2_composition_pattern.md` - コンポジションパターン
- `part_2_container_presentational_pattern.md` - Container/Presentational分離
- `part_2_container_1st_design.md` - Container優先設計

#### Part 3: キャッシュ戦略 (6章)
**参照タイミング**: パフォーマンス最適化・キャッシュ制御時
- `part_3_static_rendering_full_route_cache.md` - 静的レンダリング最適化
- `part_3_dynamic_rendering_data_cache.md` - 動的レンダリング制御
- `part_3_router_cache.md` - クライアントサイドキャッシュ
- `part_3_data_mutation.md` - データ変更とキャッシュ無効化
- `part_3_dynamicio.md` - 実験的キャッシュ改善

#### Part 4: レンダリング戦略 (4章)
**参照タイミング**: レンダリング最適化・Streaming実装時
- `part_4_pure_server_components.md` - Server Component純粋性
- `part_4_suspense_and_streaming.md` - プログレッシブローディング
- `part_4_partial_pre_rendering.md` - 部分的事前レンダリング

#### Part 5: その他の実践 (4章)
**参照タイミング**: 認証・エラーハンドリング実装時
- `part_5_request_ref.md` - リクエスト・レスポンス参照
- `part_5_auth.md` - 認証・認可パターン
- `part_5_error_handling.md` - エラーハンドリング戦略

### 2. 単体記事 (`articles/`)
#### フロントエンド単体テスト (`articles/frontend-unit-testing.md`)
**参照タイミング**: テスト戦略策定・テスト実装時
- Classical vs London school テスト手法
- AAA（Arrange, Act, Assert）パターン
- Storybookとの統合（`composeStories`）
- テスト命名規則・共通セットアップパターン

## 参照ガイドライン

### 参照タイミング
実装時には関連するドキュメントを必ず参照し、参照後は「📖{ドキュメント名}を読み込みました」と出力すること。

### 機能実装時の参照優先順位
1. **データ取得実装** → Part 1のドキュメント群を参照
2. **コンポーネント設計** → Part 2のパターンを適用
3. **パフォーマンス最適化** → Part 3のキャッシュ戦略を活用
4. **レンダリング最適化** → Part 4のStreaming・PPR戦略を参照
5. **認証・エラーハンドリング** → Part 5の実践パターンを適用
6. **テスト実装** → `articles/frontend-unit-testing.md`を参照
