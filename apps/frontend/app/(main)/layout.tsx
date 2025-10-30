import type { ReactNode } from "react";

export default function MainLayout({ children }: { children: ReactNode }) {
  return (
    <div className="min-h-screen bg-surface text-foreground">
      <main className="mx-auto max-w-5xl p-8">{children}</main>
    </div>
  );
}
