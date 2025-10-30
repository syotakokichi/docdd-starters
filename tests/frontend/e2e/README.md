# Frontend E2E Tests

Playwright や Cypress など E2E ツール用のテストを配置します。
- Playwright: `pnpm create playwright@latest`
- CI では `pnpm test:e2e` などコマンドを統一
- 7-axis `TC` の `automation.command` で該当コマンドを指すようにしてください
