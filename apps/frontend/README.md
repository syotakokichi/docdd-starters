# Next.js Private Folder スターター

このスターターは Next.js App Router (v15) を前提に、Private Folder アーキテクチャを最小構成で再現したものです。

```
app/
  layout.tsx
  page.tsx
  globals.css
  (main)/
    layout.tsx
    dashboard/
      page.tsx
      _containers/
        dashboard/
          index.ts
          container.tsx
          client-container.tsx
          presentational.tsx
      _components/
        filter-bar.tsx
      _actions/
        index.ts
      _types/
        index.ts
      _hooks/
        index.ts
      _lib/
        index.ts
src/
  components/
  hooks/
  lib/
  config/
  constants/
  types/
tsconfig.json
package.json
next.config.js
```

- `page.tsx` は責務を Container に委譲し、Segment 内の Private Folder に実装を閉じ込めます。
- Container/Presentational パターンを採用し、`presentational.tsx` には Client Component のみを記述します。
- `filter-bar.tsx` のような Segment 内共有 UI は `_components/` に集約し、UI フレームワークはプロジェクト都合で差し替えてください。
- Server Actions (`_actions/`) は Segment 内に閉じ込め、再利用する型は `_types/` に定義します。
- Segment を跨いで利用するコンポーネントやロジックは `src/components`, `src/hooks`, `src/lib`, `src/config`, `src/constants`, `src/types` に配置し、`@/...` エイリアスで参照します。
- `app/` と `src/` を同列に置く構成は Next.js でも一般的です。`app/` はルーティング、`src/` は共通資産の集約という役割で使い分けます。
- `npm run lint:biome` や `npm run format` で Biome による整形と lint を実行できます。
- `npm run check:segments` で Private Folder の必須ファイル構成を検証できます（pre-commit / CI からも利用）。

## 使い方

1. `pnpm create next-app` 等で土台を作成した後、本ディレクトリの構成をコピーして Private Folder 化を進めます。
2. Segment ごとに `_containers/`・`_components/` 以下を複製し、このスターターで示した責務分離の原則に沿って命名と責務を整理します。
3. UI コンポーネントのスタイルは `globals.css` を差し替えるか、shadcn/ui や Tailwind Design Token など任意の手法で置き換えて問題ありません。
4. 7-axis ドキュメントの `TS` / `TC` と紐付ける際は、テストコマンドを `README` か `package.json` の scripts に明記してください。

詳細ガイドラインは `docdd-starters/docs/frontend` を参照してください。
