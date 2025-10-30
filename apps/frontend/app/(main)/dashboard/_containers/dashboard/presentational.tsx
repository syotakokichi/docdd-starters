"use client";

import type { DashboardSummary } from "../../_types";
import { FilterBar } from "../../_components/filter-bar";

interface Props {
  summary: DashboardSummary;
}

export function DashboardPresentational({ summary }: Props) {
  return (
    <section className="space-y-6">
      <header className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold">Dashboard</h1>
        <FilterBar filters={summary.filters} />
      </header>
      <dl className="grid gap-4 md:grid-cols-3">
        {summary.metrics.map((metric) => (
          <div key={metric.id} className="rounded-md border border-border bg-card p-4">
            <dt className="text-sm text-muted-foreground">{metric.label}</dt>
            <dd className="text-2xl font-bold">{metric.value}</dd>
          </div>
        ))}
      </dl>
    </section>
  );
}
