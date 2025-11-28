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
      AUTH_SECRET: process.env.AUTH_SECRET ?? "test-auth-secret",
      AUTH_GOOGLE_ID: process.env.AUTH_GOOGLE_ID ?? "test-google-id",
      AUTH_GOOGLE_SECRET:
        process.env.AUTH_GOOGLE_SECRET ?? "test-google-secret",
      AUTH_GOOGLE_ISSUER:
        process.env.AUTH_GOOGLE_ISSUER ?? "https://accounts.google.com",
      NEXTAUTH_URL: baseURL,
    },
  },
};

export default config;
