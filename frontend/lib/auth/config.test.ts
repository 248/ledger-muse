import { describe, expect, it, vi } from "vitest";

vi.mock("./token", () => {
  return {
    refreshAccessToken: vi.fn(async (token: unknown) => ({
      ...(token as Record<string, unknown>),
      accessToken: "refreshed-access-token",
    })),
  };
});

import { authConfig } from "./config";
import { refreshAccessToken } from "./token";

describe("authConfig.callbacks.authorized", () => {
  it("denies access to protected routes when unauthenticated", () => {
    const authorized = authConfig.callbacks?.authorized;
    const result = authorized?.({
      auth: null,
      request: new Request("https://example.com/dashboard") as any,
    });

    expect(result).toBe(false);
  });

  it("allows access to protected routes when authenticated", () => {
    const authorized = authConfig.callbacks?.authorized;
    const result = authorized?.({
      auth: { user: { id: "user-1" }, expires: "" } as any,
      request: new Request("https://example.com/dashboard") as any,
    });

    expect(result).toBe(true);
  });

  it("allows public routes even when unauthenticated", () => {
    const authorized = authConfig.callbacks?.authorized;
    const result = authorized?.({
      auth: null,
      request: new Request("https://example.com/login") as any,
    });

    expect(result).toBe(true);
  });
});

describe("authConfig.callbacks.jwt", () => {
  it("stores access/refresh tokens when account is present", async () => {
    const jwtCallback = authConfig.callbacks?.jwt;

    const token = await jwtCallback?.({
      token: {},
      user: { id: "test-user", email: "test@example.com" } as any,
      account: {
        access_token: "access-token",
        refresh_token: "refresh-token",
        expires_at: 12345,
      } as never,
    });

    expect(token).toMatchObject({
      accessToken: "access-token",
      refreshToken: "refresh-token",
      expiresAt: 12345,
    });
  });

  it("refreshes token when about to expire", async () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2024-01-01T00:00:00Z"));
    const jwtCallback = authConfig.callbacks?.jwt;

    const token = await jwtCallback?.({
      token: {
        sub: "user-1",
        accessToken: "old-access",
        refreshToken: "existing-refresh",
        expiresAt: Math.floor(Date.now() / 1000) + 10,
      },
    } as never);

    expect(refreshAccessToken).toHaveBeenCalledOnce();
    expect(token).toMatchObject({
      accessToken: "refreshed-access-token",
      refreshToken: "existing-refresh",
    });
    vi.useRealTimers();
  });
});

describe("authConfig.callbacks.session", () => {
  it("embeds user id and access token into session object", async () => {
    const sessionCallback = authConfig.callbacks?.session;

    const session = await sessionCallback?.({
      session: {
        user: { name: "Test User", email: "user@example.com" },
        expires: "",
      } as any,
      token: { sub: "user-1", accessToken: "abc123" } as never,
    });

    expect(session?.user).toMatchObject({ id: "user-1" });
    expect((session as typeof session & { accessToken?: string })?.accessToken).toBe(
      "abc123",
    );
  });
});
