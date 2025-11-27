import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const originalEnv = { ...process.env };

describe("authConfig", () => {
  beforeEach(() => {
    vi.resetModules();
    process.env.AUTH_GOOGLE_ID = "google-id";
    process.env.AUTH_GOOGLE_SECRET = "google-secret";
    process.env.AUTH_SECRET = "test-secret";
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    process.env = { ...originalEnv };
  });

  it("configures Google provider with JWT sessions", async () => {
    const { authConfig } = await import("@/lib/auth/config");

    expect(authConfig.providers?.[0]?.id).toBe("google");
    expect(authConfig.session?.strategy).toBe("jwt");
    expect(authConfig.session?.maxAge).toBeGreaterThan(0);
  });

  it("denies dashboard access when unauthenticated", async () => {
    const { authConfig } = await import("@/lib/auth/config");

    const result = await authConfig.callbacks?.authorized?.({
      auth: null,
      request: new Request("https://example.com/dashboard"),
    });

    expect(result).toBe(false);
  });

  it("refreshes access tokens when expired", async () => {
    const mockFetch = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({
        access_token: "new-access",
        refresh_token: "new-refresh",
        expires_in: 3600,
      }),
    });
    vi.stubGlobal("fetch", mockFetch);

    const { authConfig } = await import("@/lib/auth/config");
    const expiredToken = {
      accessToken: "old-access",
      refreshToken: "old-refresh",
      expiresAt: Math.floor(Date.now() / 1000) - 10,
    };

    const result = await authConfig.callbacks?.jwt?.({
      token: expiredToken as any,
    });

    expect((result as any).accessToken).toBe("new-access");
    expect((result as any).refreshToken).toBe("new-refresh");
    expect((result as any).expiresAt).toBeGreaterThan(
      Math.floor(Date.now() / 1000),
    );
    expect(mockFetch).toHaveBeenCalled();
  });
});
