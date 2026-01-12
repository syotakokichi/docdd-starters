# コンポーネント設計パターン

> 詳細: [docs/frontend/akfm-knowledge/nextjs-basic-principle/part_2.md](../../../../docs/frontend/akfm-knowledge/nextjs-basic-principle/part_2.md)

## 基本原則

RSC アーキテクチャでは Server Components と Client Components をうまく統合する設計が必要。

### 1. Client Components の使用指針

**推奨**: インタラクティブ機能にのみ Client Components を使用。

**Client Components が必要なケース**:
- `useState`, `useEffect` などの React Hooks 使用時
- ブラウザ API（`window`, `document`）へのアクセス
- イベントハンドラ（`onClick`, `onChange` 等）
- サードパーティライブラリ（クライアント専用）

```tsx
// "use client" は必要な箇所でのみ使用
"use client";

import { useState } from "react";

export function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(c => c + 1)}>{count}</button>;
}
```

> 詳細: [part_2_client_components_usecase.md](../../../../docs/frontend/akfm-knowledge/nextjs-basic-principle/part_2_client_components_usecase.md)

### 2. Composition パターン

**推奨**: children props を使って Server/Client Components を柔軟に組み合わせる。

```tsx
// Server Component（親）
export default function ProductPage() {
  return (
    <InteractiveWrapper>
      {/* Server Component を children として渡す */}
      <ProductDetails />
    </InteractiveWrapper>
  );
}

// Client Component（ラッパー）
"use client";
export function InteractiveWrapper({ children }: { children: React.ReactNode }) {
  return <div className="interactive">{children}</div>;
}

// Server Component（子）
async function ProductDetails() {
  const product = await fetchProduct();
  return <div>{product.name}</div>;
}
```

> 詳細: [part_2_composition_pattern.md](../../../../docs/frontend/akfm-knowledge/nextjs-basic-principle/part_2_composition_pattern.md)

### 3. Container/Presentational 分離

**Private Folder パターン** で Container/Presentational を分離。

```
app/<segment>/
├── page.tsx                     # 薄いラッパー（~5行）
├── _containers/<Name>/
│   ├── index.ts                 # Container export のみ
│   ├── container.tsx            # ビジネスロジック
│   └── presentational.tsx       # @package UI 描画のみ
├── _types/index.ts              # Segment 専用型定義
└── _hooks/index.ts              # Segment 専用 Hook
```

**運用ルール**:

| ルール | 説明 |
|--------|------|
| page.tsx は薄く | Container のみ import（~5行） |
| @package コメント | presentational.tsx に付与 |
| export しない | index.ts から presentational.tsx を export しない |
| Suspense 必須 | `useSearchParams()` 使用時は page.tsx に Suspense ラッパー |

> 詳細: [part_2_container_presentational_pattern.md](../../../../docs/frontend/akfm-knowledge/nextjs-basic-principle/part_2_container_presentational_pattern.md)

### 4. Container 1st な設計

**推奨**: 実装順序として Container（ツリー構造）を先に設計する。

1. ページ全体のコンポーネントツリーを設計
2. データフェッチ境界を決定
3. Composition パターンを早期に適用
4. Presentational は後から実装

> 詳細: [part_2_container_1st_design.md](../../../../docs/frontend/akfm-knowledge/nextjs-basic-principle/part_2_container_1st_design.md)

## 関連ドキュメント

- [PRIVATE_FOLDER_GUIDE.md](../../../../docs/frontend/PRIVATE_FOLDER_GUIDE.md) - Private Folder ガイド
