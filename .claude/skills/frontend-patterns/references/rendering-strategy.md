# レンダリング戦略

> 詳細: [docs/frontend/akfm-knowledge/nextjs-basic-principle/part_4.md](../../../../docs/frontend/akfm-knowledge/nextjs-basic-principle/part_4.md)

## レンダリングモデル

App Router がサポートするレンダリングモデル:

| モデル | 説明 | 特徴 |
|--------|------|------|
| SSR | Server-Side Rendering | リクエストごとにサーバーでレンダリング |
| SSG | Static Site Generation | ビルド時にレンダリング |
| ISR | Incremental Static Regeneration | 静的 + 時間ベース再検証 |
| **Streaming SSR** | ストリーミング SSR | 段階的にレスポンスを送信 |
| **PPR** | Partial Pre-Rendering | 静的/動的の境界を Suspense で定義 |

## Server Components の純粋性

**推奨**: Server Components は副作用を持たない純粋な関数として実装する。

**理由**:
- 並行実行性の前提（React が並行にレンダリングする可能性）
- Request Memoization の有効化

```tsx
// 純粋な Server Component
async function ProductList() {
  const products = await fetchProducts(); // 副作用なし
  return products.map(p => <ProductCard key={p.id} product={p} />);
}
```

> 詳細: [part_4_pure_server_components.md](../../../../docs/frontend/akfm-knowledge/nextjs-basic-principle/part_4_pure_server_components.md)

## Suspense と Streaming

### Streaming SSR

従来の SSR は全体のレンダリング完了を待つが、Streaming SSR は段階的にレスポンスを送信。

**メリット**:
- TTFB（Time To First Byte）の改善
- 即時レスポンスによる UX 向上

### Suspense による段階的ローディング

```tsx
import { Suspense } from "react";

export default function ProductPage() {
  return (
    <div>
      <h1>商品ページ</h1>

      {/* 遅いデータフェッチを Suspense で分離 */}
      <Suspense fallback={<ProductSkeleton />}>
        <ProductDetails />
      </Suspense>

      {/* 関連商品は別の Suspense 境界 */}
      <Suspense fallback={<RelatedSkeleton />}>
        <RelatedProducts />
      </Suspense>
    </div>
  );
}
```

**注意点**:
- fallback には Layout Shift を防ぐスケルトンを使用
- SEO への影響を考慮（重要なコンテンツは早めにレンダリング）

> 詳細: [part_4_suspense_and_streaming.md](../../../../docs/frontend/akfm-knowledge/nextjs-basic-principle/part_4_suspense_and_streaming.md)

## Partial Pre-Rendering (PPR)

静的部分と動的部分を `<Suspense>` 境界で分離し、静的部分は事前レンダリング、動的部分はリクエスト時にストリーミング。

```tsx
// 静的シェル（事前レンダリング）
export default function Page() {
  return (
    <div>
      <Header />  {/* 静的 */}

      {/* 動的部分（リクエスト時にストリーミング） */}
      <Suspense fallback={<CartSkeleton />}>
        <Cart />  {/* Dynamic API 使用 */}
      </Suspense>

      <Footer />  {/* 静的 */}
    </div>
  );
}
```

**有効化**（next.config.js）:

```js
module.exports = {
  experimental: {
    ppr: true,
  },
};
```

> 詳細: [part_4_partial_pre_rendering.md](../../../../docs/frontend/akfm-knowledge/nextjs-basic-principle/part_4_partial_pre_rendering.md)

## 関連ドキュメント

- [Next.js Rendering](https://nextjs.org/docs/app/building-your-application/rendering)
