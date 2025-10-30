import type { DashboardSummary } from "../../_types";

export async function fetchDashboardSummary(): Promise<DashboardSummary> {
  return {
    metrics: [
      { id: "total", label: "Total Sales", value: "$12,340" },
      { id: "supporters", label: "Active Supporters", value: "1,245" },
      { id: "stores", label: "Partner Stores", value: "87" },
    ],
    filters: {
      active: "today",
      options: [
        { id: "today", label: "Today" },
        { id: "week", label: "This Week" },
        { id: "month", label: "This Month" },
      ],
    },
  };
}
