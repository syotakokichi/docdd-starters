---
name: frontend-patterns
description: |
  Next.js App Router のフロントエンド実装パターン。
  データフェッチ（Server Components / Colocation）、Container/Presentational、
  キャッシュ・レンダリング戦略、Private Folder、認証・エラーハンドリングを提供。
  フロントエンド実装時（`/develop` 等）に参照される。
---

# Frontend Patterns - Next.js App Router

## 概要

Next.js App Router と Private Folder パターンを用いたフロントエンド実装のパターンを定義します。

**対象範囲**:
- データフェッチパターン（Server Components, Colocation）
- コンポーネント設計（Container/Presentational, Composition）
- キャッシュ戦略（Static/Dynamic Rendering, Revalidate）
- レンダリング戦略（Streaming, Suspense, PPR）
- 認証・エラーハンドリング

## 参照インデックス

| ドキュメント | 内容 | 優先度 |
|-------------|------|:------:|
| [data-fetching.md](references/data-fetching.md) | Server Components、Colocation、Request Memoization | 高 |
| [component-design.md](references/component-design.md) | Container/Presentational、Composition パターン | 高 |
| [cache-strategy.md](references/cache-strategy.md) | Static/Dynamic Rendering、Revalidate | 高 |
| [rendering-strategy.md](references/rendering-strategy.md) | Streaming、Suspense、PPR | 中 |
| [auth-error-handling.md](references/auth-error-handling.md) | 認証、エラーハンドリング | 中 |

## ディレクトリ構造

```
apps/frontend/
├── app/                     # App Router
│   ├── (auth)/              # Route Group（URLに含まれない）
│   │   ├── login/
│   │   │   └── page.tsx
│   │   └── layout.tsx
│   ├── dashboard/
│   │   ├── _components/     # Private Folder（ルーティング対象外）
│   │   │   └── DashboardChart.tsx
│   │   ├── _hooks/
│   │   │   └── useDashboardData.ts
│   │   └── page.tsx
│   ├── layout.tsx
│   └── page.tsx
├── src/
│   ├── components/          # 共通コンポーネント
│   │   └── ui/
│   │       ├── Button.tsx
│   │       └── Input.tsx
│   ├── lib/                 # ユーティリティ
│   │   └── api-client.ts
│   └── types/               # 型定義
│       └── index.ts
├── next.config.js
├── package.json
└── tsconfig.json
```

## Private Folder パターン

### 命名規則

- `_components/`: ページ固有のコンポーネント
- `_hooks/`: ページ固有のフック
- `_lib/`: ページ固有のユーティリティ
- `_types/`: ページ固有の型定義

### 使用例

```
app/dashboard/
├── _components/
│   ├── DashboardChart.tsx    # ダッシュボード専用
│   └── StatsCard.tsx
├── _hooks/
│   └── useDashboardData.ts   # ダッシュボード専用
├── page.tsx
└── layout.tsx
```

## コンポーネント実装

### Server Component（デフォルト）

```tsx
// app/dashboard/page.tsx
import { DashboardChart } from './_components/DashboardChart';

async function getData() {
  const res = await fetch('https://api.example.com/data', {
    next: { revalidate: 60 }  // ISR: 60秒
  });
  return res.json();
}

export default async function DashboardPage() {
  const data = await getData();

  return (
    <div>
      <h1>Dashboard</h1>
      <DashboardChart data={data} />
    </div>
  );
}
```

### Client Component

```tsx
// app/dashboard/_components/DashboardChart.tsx
'use client';

import { useState, useEffect } from 'react';

interface Props {
  data: ChartData[];
}

export function DashboardChart({ data }: Props) {
  const [selectedRange, setSelectedRange] = useState<string>('week');

  return (
    <div>
      <select
        value={selectedRange}
        onChange={(e) => setSelectedRange(e.target.value)}
      >
        <option value="week">This Week</option>
        <option value="month">This Month</option>
      </select>
      {/* チャート描画 */}
    </div>
  );
}
```

## カスタムフック

```tsx
// app/dashboard/_hooks/useDashboardData.ts
'use client';

import { useState, useEffect } from 'react';

export function useDashboardData(range: string) {
  const [data, setData] = useState<DashboardData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    async function fetchData() {
      try {
        setLoading(true);
        const res = await fetch(`/api/dashboard?range=${range}`);
        if (!res.ok) throw new Error('Failed to fetch');
        setData(await res.json());
      } catch (e) {
        setError(e as Error);
      } finally {
        setLoading(false);
      }
    }
    fetchData();
  }, [range]);

  return { data, loading, error };
}
```

## Route Groups

URLに影響しないグルーピング:

```
app/
├── (marketing)/      # マーケティングページ
│   ├── about/
│   └── pricing/
├── (app)/            # アプリケーションページ
│   ├── dashboard/
│   └── settings/
└── (auth)/           # 認証ページ
    ├── login/
    └── register/
```

各グループに別々のレイアウトを適用可能:

```tsx
// app/(auth)/layout.tsx
export default function AuthLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <div className="auth-container">
      {children}
    </div>
  );
}
```

## アンチパターン

### NG: 全てを Client Component に

```tsx
// page.tsx
'use client';  // NG: 不要な場合はつけない

export default function Page() {
  return <div>Static content</div>;  // Server Component で十分
}
```

### NG: Private Folder を使わない

```
app/dashboard/
├── DashboardChart.tsx  # NG: _components/ に入れる
├── useDashboardData.ts # NG: _hooks/ に入れる
└── page.tsx
```

### OK: 適切な分離

```
app/dashboard/
├── _components/
│   └── DashboardChart.tsx
├── _hooks/
│   └── useDashboardData.ts
└── page.tsx
```

## Private Folder チェック

```bash
# 構成チェックスクリプト
npm run check:segments

# scripts/frontend/check-private-folders.mjs を実行
```

## 参考資料

- [Next.js App Router Docs](https://nextjs.org/docs/app)
- [Frontend README](../../../apps/frontend/README.md)
- [PRIVATE_FOLDER_GUIDE.md](../../../docs/frontend/PRIVATE_FOLDER_GUIDE.md)
- [akfm-knowledge](../../../docs/frontend/akfm-knowledge/) - Next.js 包括的知識ベース
- [Testing Guide](../../../docs/testing/frontend-unit-testing.md)
