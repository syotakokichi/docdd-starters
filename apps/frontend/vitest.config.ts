import { defineConfig } from "vitest/config"

export default defineConfig({
  test: {
    include: ["../../tests/frontend/unit/**/*.test.ts", "../../tests/frontend/unit/**/*.test.tsx"],
    coverage: {
      enabled: false,
    },
  },
})
