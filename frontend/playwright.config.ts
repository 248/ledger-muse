import type { PlaywrightTestConfig } from "@playwright/test";

const port = process.env.PORT ?? "3000";
const host = process.env.HOST ?? "127.0.0.1";
const baseURL = `http://${host}:${port}`;

const config: PlaywrightTestConfig = {
  testDir: "./tests/e2e",
  use: {
    baseURL,
    headless: true,
    trace: "on-first-retry",
  },
  webServer: {
    command: `PORT=${port} npm run dev -- --hostname ${host} --port ${port}`,
    url: baseURL,
    reuseExistingServer: true,
    timeout: 60_000,
    env: {
      NEXT_PUBLIC_BACKEND_API_BASE:
        process.env.NEXT_PUBLIC_BACKEND_API_BASE ??
        "http://localhost:8080",
    },
  },
};

export default config;
