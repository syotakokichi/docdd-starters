import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import type { DashboardFilters } from "@/app/(main)/dashboard/_types";
import { FilterBar } from "@/app/(main)/dashboard/_components/filter-bar";

vi.mock("@/app/(main)/dashboard/_actions", () => ({
  applyFilter: vi.fn(),
}));

const { applyFilter } = await import("@/app/(main)/dashboard/_actions");

const filters: DashboardFilters = {
  active: "today",
  options: [
    { id: "today", label: "Today" },
    { id: "week", label: "This Week" },
  ],
};

describe("FilterBar", () => {
  it("calls applyFilter with the selected option", () => {
    render(<FilterBar filters={filters} />);

    const target = screen.getByRole("button", { name: "This Week" });
    fireEvent.click(target);

    expect(applyFilter).toHaveBeenCalledWith("week");
  });

  it("disables button while pending", () => {
    render(<FilterBar filters={filters} />);

    const todayButton = screen.getByRole("button", { name: "Today" });
    fireEvent.click(todayButton);

    expect(todayButton).toBeDisabled();
  });
});
