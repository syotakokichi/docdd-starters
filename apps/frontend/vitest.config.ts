import path from "node:path"
import { fileURLToPath } from "node:url"

import { defineConfig } from "vitest/config"

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

export default defineConfig({
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "src"),
    },
  },
  test: {
    include: ["../../tests/frontend/unit/**/*.test.ts", "../../tests/frontend/unit/**/*.test.tsx"],
    coverage: {
      enabled: false,
    },
  },
})
