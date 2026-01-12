# 認証・エラーハンドリング

> 詳細: [docs/frontend/akfm-knowledge/nextjs-basic-principle/part_5.md](../../../../docs/frontend/akfm-knowledge/nextjs-basic-principle/part_5.md)

## Request/Response 参照

App Router では `req`/`res` オブジェクトに直接アクセスできない。代わりに:

```tsx
import { cookies, headers } from "next/headers";

export default async function Page() {
  const cookieStore = await cookies();
  const headersList = await headers();

  const token = cookieStore.get("token");
  const userAgent = headersList.get("user-agent");
  // ...
}
```

> 詳細: [part_5_request_ref.md](../../../../docs/frontend/akfm-knowledge/nextjs-basic-principle/part_5_request_ref.md)

## 認証パターン

### Session 管理

**推奨**: Cookie + JWT（セッション ID を JWT 化）

```tsx
// lib/auth.ts
import "server-only";
import { cookies } from "next/headers";
import { jwtVerify } from "jose";

export async function getSession() {
  const cookieStore = await cookies();
  const token = cookieStore.get("session")?.value;
  if (!token) return null;

  try {
    const { payload } = await jwtVerify(token, SECRET_KEY);
    return payload;
  } catch {
    return null;
  }
}
```

### 認可チェック

**注意**: URL 認可には制約がある（並行レンダリング問題）

```tsx
// app/admin/page.tsx
import { redirect } from "next/navigation";
import { getSession } from "@/lib/auth";

export default async function AdminPage() {
  const session = await getSession();

  if (!session) {
    redirect("/login");
  }

  if (session.role !== "admin") {
    redirect("/unauthorized");
  }

  return <AdminDashboard />;
}
```

### Middleware での認証

```tsx
// middleware.ts
import NextAuth from "next-auth";
import { authConfig } from "@/lib/config/auth.config";

const { auth } = NextAuth(authConfig);

export const middleware = auth;

export const config = {
  matcher: ["/admin/:path*"],
};
```

```tsx
// auth.config.ts - Edge 互換設定
import type { NextAuthConfig } from "next-auth";

export const authConfig: NextAuthConfig = {
  pages: { signIn: "/login" },
  callbacks: {
    authorized({ auth, request }) {
      const isLoggedIn = !!auth?.user;
      const isAdminRoute = request.nextUrl.pathname.startsWith("/admin");
      if (isAdminRoute && !isLoggedIn) return false;
      return true;
    },
  },
  providers: [],
};
```

> 詳細: [part_5_auth.md](../../../../docs/frontend/akfm-knowledge/nextjs-basic-principle/part_5_auth.md)

## エラーハンドリング

### error.tsx

ルートセグメントでのエラーをキャッチ。

```tsx
// app/products/error.tsx
"use client";

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div>
      <h2>エラーが発生しました</h2>
      <p>{error.message}</p>
      <button onClick={reset}>再試行</button>
    </div>
  );
}
```

### not-found.tsx

404 エラー用のカスタム UI。

```tsx
// app/products/[id]/not-found.tsx
export default function NotFound() {
  return (
    <div>
      <h2>商品が見つかりません</h2>
      <p>指定された商品は存在しないか、削除された可能性があります。</p>
    </div>
  );
}
```

**使用方法**:

```tsx
import { notFound } from "next/navigation";

export default async function ProductPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const product = await fetchProduct(id);

  if (!product) {
    notFound();
  }

  return <ProductDetails product={product} />;
}
```

> 詳細: [part_5_error_handling.md](../../../../docs/frontend/akfm-knowledge/nextjs-basic-principle/part_5_error_handling.md)

## 関連ドキュメント

- [Next.js Authentication](https://nextjs.org/docs/app/building-your-application/authentication)
- [Next.js Error Handling](https://nextjs.org/docs/app/building-your-application/routing/error-handling)
