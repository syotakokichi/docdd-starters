# データフェッチパターン

> 詳細: [docs/frontend/akfm-knowledge/nextjs-basic-principle/part_1.md](../../../../docs/frontend/akfm-knowledge/nextjs-basic-principle/part_1.md)

## 基本原則

### 1. Server Components でデータフェッチ

**推奨**: データフェッチは Client Components ではなく Server Components で行う。

**メリット**:
- 高速なバックエンドアクセス（サーバー間通信）
- シンプルでセキュアな実装（3rd party ライブラリ不要）
- バンドルサイズの軽減

```tsx
// Server Component でのデータフェッチ
export async function ProductTitle({ id }: { id: string }) {
  const res = await fetch(`/api/products/${id}`);
  const product = await res.json();
  return <div>{product.title}</div>;
}
```

> 詳細: [part_1_server_components.md](../../../../docs/frontend/akfm-knowledge/nextjs-basic-principle/part_1_server_components.md)

### 2. データフェッチのコロケーション

**推奨**: データを参照するコンポーネントにデータフェッチをコロケーションする。

**従来の問題（Pages Router）**:
- `getServerSideProps` でページ最上位でデータ取得
- Props Drilling（バケツリレー）が発生

**App Router での解決**:
- 末端コンポーネントで直接データフェッチ
- Request Memoization により重複リクエストは自動排除

```tsx
// 各コンポーネントが必要なデータを自身で取得
async function ProductHeader() {
  const product = await fetchProduct(); // 自動でメモ化
  return <h1>{product.title}</h1>;
}

async function ProductDetail() {
  const product = await fetchProduct(); // 同じリクエストは再利用
  return <p>{product.description}</p>;
}
```

> 詳細: [part_1_colocation.md](../../../../docs/frontend/akfm-knowledge/nextjs-basic-principle/part_1_colocation.md)

### 3. Request Memoization

同一リクエスト内で同じ `fetch` 呼び出しは自動的にメモ化される。

**有効化条件**:
- 同じ URL + 同じオプション
- 同一リクエストライフサイクル内

**注意**: `server-only` パッケージでサーバー専用コードを明示する。

```tsx
// lib/data.ts
import "server-only";

export async function fetchProduct(id: string) {
  // 同一リクエスト内で複数回呼んでも1回しか実行されない
  const res = await fetch(`/api/products/${id}`);
  return res.json();
}
```

> 詳細: [part_1_request_memoization.md](../../../../docs/frontend/akfm-knowledge/nextjs-basic-principle/part_1_request_memoization.md)

## トレードオフ

### GraphQL との相性

RSC と GraphQL の組み合わせはメリットよりデメリットが多くなる可能性がある。RSC 自体が GraphQL の課題を解決する設計思想を持つため。

### ユーザー操作に基づくデータフェッチ

ユーザー操作に応じたデータフェッチは Server Components では困難な場合がある。

> 詳細: [part_1_interactive_fetch.md](../../../../docs/frontend/akfm-knowledge/nextjs-basic-principle/part_1_interactive_fetch.md)

## 関連ドキュメント

- [並行データフェッチ](../../../../docs/frontend/akfm-knowledge/nextjs-basic-principle/part_1_concurrent_fetch.md)
- [DataLoader パターン](../../../../docs/frontend/akfm-knowledge/nextjs-basic-principle/part_1_data_loader.md)
- [細粒度 API 設計](../../../../docs/frontend/akfm-knowledge/nextjs-basic-principle/part_1_fine_grained_api_design.md)
