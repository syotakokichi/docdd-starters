# キャッシュ戦略

> 詳細: [docs/frontend/akfm-knowledge/nextjs-basic-principle/part_3.md](../../../../docs/frontend/akfm-knowledge/nextjs-basic-principle/part_3.md)

## App Router の4層キャッシュ

| Mechanism | What | Where | Purpose | Duration |
|-----------|------|-------|---------|----------|
| **Request Memoization** | API レスポンス等 | Server | Component tree でのデータ再利用 | リクエストごと |
| **Data Cache** | API レスポンス等 | Server | ユーザー/デプロイをまたぐ再利用 | 永続的 (revalidate 可) |
| **Full Route Cache** | HTML/RSC payload | Server | レンダリングコスト最適化 | 永続的 (revalidate 可) |
| **Router Cache** | RSC Payload | Client | ナビゲーションごとのリクエスト削減 | セッション/時間 |

## Static vs Dynamic Rendering

### Static Rendering（デフォルト）

ビルド時にレンダリングされ、Full Route Cache に保存される。

**Static Rendering になる条件**:
- Dynamic APIs を使用しない
- `cache: "no-store"` や `next.revalidate: 0` を使わない

### Dynamic Rendering

リクエストごとにレンダリングされる。

**Dynamic APIs（使用すると Dynamic Rendering になる）**:
- `cookies()`, `headers()`
- `searchParams` prop
- `connection()`

```tsx
// Dynamic Rendering になる例
import { cookies } from "next/headers";

export default async function Page() {
  const cookieStore = await cookies();
  // ...
}
```

> 詳細: [part_3_static_rendering_full_route_cache.md](../../../../docs/frontend/akfm-knowledge/nextjs-basic-principle/part_3_static_rendering_full_route_cache.md)

## Revalidate 戦略

### オンデマンド revalidate

データ変更時に明示的にキャッシュを無効化。

```tsx
// Server Action 内で
import { revalidatePath, revalidateTag } from "next/cache";

export async function updateProduct(id: string) {
  await db.product.update({ where: { id }, data: { ... } });

  // パスベース
  revalidatePath("/products");

  // タグベース
  revalidateTag("products");
}
```

### 時間ベース revalidate

Route Segment Config で指定。

```tsx
// app/products/page.tsx
export const revalidate = 3600; // 1時間ごとに再検証
```

> 詳細: [part_3_data_mutation.md](../../../../docs/frontend/akfm-knowledge/nextjs-basic-principle/part_3_data_mutation.md)

## Dynamic Rendering での Data Cache

Dynamic Rendering でもデータキャッシュは活用可能。

```tsx
// fetch オプションでキャッシュ制御
const data = await fetch(url, {
  next: {
    revalidate: 3600,    // 時間ベース
    tags: ["products"],  // タグベース
  },
});

// DB アクセスのキャッシング
import { unstable_cache } from "next/cache";

const getCachedProducts = unstable_cache(
  async () => db.product.findMany(),
  ["products"],
  { revalidate: 3600, tags: ["products"] }
);
```

> 詳細: [part_3_dynamic_rendering_data_cache.md](../../../../docs/frontend/akfm-knowledge/nextjs-basic-principle/part_3_dynamic_rendering_data_cache.md)

## 関連ドキュメント

- [Router Cache](../../../../docs/frontend/akfm-knowledge/nextjs-basic-principle/part_3_router_cache.md)
- [Dynamic IO](../../../../docs/frontend/akfm-knowledge/nextjs-basic-principle/part_3_dynamicio.md)
