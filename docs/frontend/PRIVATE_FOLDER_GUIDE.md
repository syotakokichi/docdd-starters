# Private Folder 実装ガイド

このガイドは Next.js Private Folder 構成を採用する際の具体的な手順と判断基準をまとめています。akfm-knowledge のベストプラクティスを参照しながら、UI コンポーネントやスタイルを柔軟に差し替えられる状態を維持することを目的とします。

## 1. 参照ドキュメント

- Private Folder 要件（本書内で定義）
- akfm-knowledge（Next.js Basic Principle）
  - [Part 1: Colocation](akfm-knowledge/nextjs-basic-principle/part_1_colocation.md)
  - [Part 2: Container 1st Design](akfm-knowledge/nextjs-basic-principle/part_2_container_1st_design.md)
  - [Part 3: Data Mutation](akfm-knowledge/nextjs-basic-principle/part_3_data_mutation.md)
  - [Part 3: Router Cache](akfm-knowledge/nextjs-basic-principle/part_3_router_cache.md)

## 2. Segment ディレクトリの基本形

```
app/(domain)/(segment)/
├── page.tsx
├── _containers/
│   └── <segment-name>/
│       ├── index.ts
│       ├── container.tsx
│       ├── client-container.tsx (任意)
│       └── presentational.tsx
├── _components/
│   └── <shared-client-component>.tsx
├── _actions/
│   └── index.ts
├── _types/
│   └── index.ts
├── _hooks/
│   └── index.ts
└── _lib/
    └── index.ts
```

## 3. 命名とアクセス制御

| フォルダ | 役割 | Public エントリ | 備考 |
| -------- | ---- | ---------------- | ---- |
| `_containers/<name>/` | データ取得・組み立て | `index.ts` | `presentational.tsx` には `@package` コメントを付与して外部公開を防止 |
| `_components/` | Segment 内共有 UI | 直下ファイル | kebab-case ファイル名、PascalCase コンポーネント名 |
| `_actions/` | Server Actions | `index.ts` | 冪等 + revalidate, redirect 等の制御を集約 |
| `_types/` | Segment 型定義 | `index.ts` | 型の循環を避けるため、Segment 外へエクスポートしない |
| `_hooks/` | Segment 専用 Hook | `index.ts` | Client 専用ロジックを切り出し |
| `_lib/` | 純粋ロジック | `index.ts` | fetch や副作用は禁止。Server/Client 共通で使える純粋関数 |

## 4. UI コンポーネントとスタイル方針

- **UI ライブラリ選定**: shadcn/ui・Tailwind Design Tokens・Chakra UI などプロダクトの要件に応じて選択可能です。Private Folder によりセグメント外への漏れを防ぐことで、どのライブラリでも最小限の変更で差し替えられます。
- **デザインガードレール**: Segment 単位でのスタイル変化が激しい場合は `_components/theme.ts` 等を追加し、デザインシステムのブリッジを提供します。
- **柔軟性の担保**: Presentational Component では UI 表現を props に閉じ込め、チーム内でのテーマ切り替えに対応できるように `className` や `variant` を expose することを推奨します。

## 5. 共通領域（src/）の利用

Segment を跨いで利用する UI やロジックは Private Folder の外に `src/` として切り出します。

```
src/
├── components/   # デザインシステム / 共通 UI
├── hooks/        # 共通 React Hooks
├── lib/          # ユーティリティ・API クライアント
├── config/       # 認証・SWR・外部サービス設定
├── constants/    # 定数・フラグ
└── types/        # グローバル型定義
```

- import は `@/components/…`, `@/hooks/…`, `@/lib/…`, `@/config/…`, `@/constants/…`, `@/types/…` のエイリアスを使用します。
- Private Folder 内では these 共通モジュールを参照し、Segment 固有の責務は引き続き `_containers` などに閉じ込めます。
- `app/` と `src/` を同列に配置する構成は Next.js App Router で一般的です。
- `npm run check:segments` コマンドで、Segment 内の必須フォルダ／ファイル構成が守られているかを自動チェックできます。

## 6. 実装チェックリスト

1. `parts/` ディレクトリが残っていないか
2. `_containers/` 配下の `presentational.tsx` に `@package` アノテーションがあるか
3. ファイル命名が kebab-case（例: `filter-bar.tsx`）になっているか
4. Server Actions から `revalidateTag` や `redirect` などの副作用を一箇所に集約しているか
5. `_types/` の型が Segment 外にリークしていないか
6. Storybook や Visual Regression を利用する場合は `_components/` を参照するようにしているか
7. Segment を跨ぐ依存が `src/` 配下に整理されているか
8. フロントエンド単体テストは `../testing/frontend-unit-testing.md` の手順に沿っているか

## 7. Traceability

- TS: `TS-FRONTEND-003`, `TS-FRONTEND-005`
- TC: 各 Segment の `_containers` 単位で UI/E2E テストケースを作成し、`TC-<SEGMENT>-001-001` 形式の ID を紐付ける。
- テスト実装は `apps/frontend/tests` (任意) に配置し、`package.json` の script 名と TC frontmatter `automation.command` を一致させます。

## 8. スターターとの連携

- `docdd-starters/apps/frontend` にミニマルな Segment (`dashboard`) を用意しています。新規 Segment 作成時はこの構成をコピーし、必要に応じて UI ライブラリ・スタイルを差し替えてください。
- `globals.css` はプレースホルダなので、実際のプロダクトでは Design Token や CSS-in-JS の設定に置き換えて構いません。

## 9. 参考リンク

- [Next.js Private Folder Documentation](https://nextjs.org/docs/app/building-your-application/routing/private-folders)
- [Next.js Server Components Architecture](https://nextjs.org/docs/app/building-your-application/rendering/server-components)
- [akfm-knowledge / Next.js Basic Principle](akfm-knowledge/nextjs-basic-principle/)
