import { fetchDashboardSummary } from "../../_lib";
import { DashboardPresentational } from "./presentational";

export async function DashboardContainer() {
  const summary = await fetchDashboardSummary();

  return <DashboardPresentational summary={summary} />;
}
