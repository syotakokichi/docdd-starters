import { Dashboard } from "./_containers/dashboard";

export default async function DashboardPage() {
  // Server Component: page.tsx should remain lightweight and delegate to container
  return <Dashboard />;
}
