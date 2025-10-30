"use client";

import { useMemo, useState } from "react";

export function useMetricThreshold(initialThreshold = 0) {
  const [threshold, setThreshold] = useState(initialThreshold);
  const isHigh = useMemo(() => threshold > 50, [threshold]);

  return { threshold, setThreshold, isHigh };
}
