export interface DashboardMetric {
  id: string;
  label: string;
  value: string;
}

export interface DashboardFilters {
  active: string;
  options: Array<{ id: string; label: string }>;
}

export interface DashboardSummary {
  metrics: DashboardMetric[];
  filters: DashboardFilters;
}
