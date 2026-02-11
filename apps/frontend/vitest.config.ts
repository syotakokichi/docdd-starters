import path from "node:path"
import { defineConfig } from "vitest/config"

const monorepoRoot = path.resolve(__dirname, "../..")
const nodeModules = path.resolve(__dirname, "node_modules")

export default defineConfig({
  esbuild: {
    jsx: "automatic",
  },
  resolve: {
    alias: [
      { find: "@/app", replacement: path.resolve(__dirname, "app") },
      { find: /^@\//, replacement: `${path.resolve(__dirname, "src")}/` },
      { find: /^react$/, replacement: `${nodeModules}/react` },
      { find: /^react\//, replacement: `${nodeModules}/react/` },
      { find: /^react-dom$/, replacement: `${nodeModules}/react-dom` },
      { find: /^react-dom\//, replacement: `${nodeModules}/react-dom/` },
      { find: /^@testing-library\/(.*)$/, replacement: `${nodeModules}/@testing-library/$1` },
    ],
  },
  server: {
    fs: {
      allow: [monorepoRoot],
    },
  },
  test: {
    include: [
      "../../tests/frontend/unit/**/*.test.ts",
      "../../tests/frontend/unit/**/*.test.tsx",
    ],
    environment: "jsdom",
    setupFiles: ["./vitest.setup.ts"],
    server: {
      deps: {
        inline: ["@testing-library/react"],
      },
    },
    coverage: {
      enabled: false,
    },
  },
})
