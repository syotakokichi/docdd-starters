"use client";

import type { DashboardSummary } from "../../_types";
import { useMetricThreshold } from "../../_hooks";
import { DashboardPresentational } from "./presentational";

interface Props {
  summary: DashboardSummary;
}

export function DashboardClientContainer({ summary }: Props) {
  const { isHigh } = useMetricThreshold(Number(summary.metrics[0]?.value.replace(/[^0-9]/g, "")));

  return (
    <div data-segment-highlight={isHigh}>
      <DashboardPresentational summary={summary} />
    </div>
  );
}
