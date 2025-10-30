"use client";

import { useTransition } from "react";
import type { DashboardFilters } from "../../_types";
import { applyFilter } from "../../_actions";

interface Props {
  filters: DashboardFilters;
}

export function FilterBar({ filters }: Props) {
  const [isPending, startTransition] = useTransition();

  return (
    <div className="flex gap-2">
      {filters.options.map((option) => (
        <button
          key={option.id}
          type="button"
          onClick={() => {
            startTransition(async () => {
              await applyFilter(option.id);
            });
          }}
          className="rounded-md border border-border px-3 py-1 text-sm"
          disabled={isPending && option.id === filters.active}
        >
          {option.label}
        </button>
      ))}
    </div>
  );
}
