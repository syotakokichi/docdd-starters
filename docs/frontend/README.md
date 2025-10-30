# フロントエンドスターター ガイド（準備中）

Next.js をベースにしたスターター構成とベストプラクティスをここにまとめています。  
まずは Private Folder アーキテクチャの導入ガイドを確認し、Segment ごとの責務分離と akfm-knowledge の原則に沿って実装を進めてください。

- [Private Folder 実装ガイド](PRIVATE_FOLDER_GUIDE.md)
- 実装時は `akfm-knowledge/nextjs-basic-principle/` を参照して設計方針を揃える
- 単体テストは `../testing/frontend-unit-testing.md` を参考に記述する
- コード整形／lint は `npm run lint:biome`、`npm run format` を使用
- Private Folder 構成チェックは `npm run check:segments` を利用
- 状態管理・E2E テストなど追加ガイドは順次更新予定です。
