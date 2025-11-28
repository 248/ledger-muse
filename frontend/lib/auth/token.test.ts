import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { refreshAccessToken, type AuthToken } from "./token";

describe("refreshAccessToken", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2024-01-01T00:00:00Z"));
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
    vi.clearAllMocks();
  });

  it("returns error when refresh token is missing", async () => {
    const token: AuthToken = { sub: "user-1" };

    const result = await refreshAccessToken(token);

    expect(result.error).toBe("RefreshTokenMissing");
    expect(result.accessToken).toBeUndefined();
  });

  it("returns refreshed tokens when the endpoint succeeds", async () => {
    const token: AuthToken = {
      sub: "user-1",
      accessToken: "old-access",
      refreshToken: "existing-refresh",
    };
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue(
        new Response(
          JSON.stringify({
            access_token: "new-access",
            refresh_token: "new-refresh",
            expires_in: 1800,
          }),
          { status: 200 },
        ),
      ),
    );

    const result = await refreshAccessToken(token);

    expect(result.error).toBeUndefined();
    expect(result.accessToken).toBe("new-access");
    expect(result.refreshToken).toBe("new-refresh");
    expect(result.expiresAt).toBe(Math.floor(Date.now() / 1000) + 1800);
  });

  it("propagates previous tokens and marks error when endpoint responds non-2xx", async () => {
    const token: AuthToken = {
      sub: "user-1",
      accessToken: "old-access",
      refreshToken: "existing-refresh",
    };
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue(new Response("bad request", { status: 400 })),
    );

    const result = await refreshAccessToken(token);

    expect(result.error).toBe("RefreshAccessTokenError");
    expect(result.accessToken).toBe("old-access");
    expect(result.refreshToken).toBe("existing-refresh");
  });

  it("marks error when fetch throws", async () => {
    const token: AuthToken = {
      sub: "user-1",
      accessToken: "old-access",
      refreshToken: "existing-refresh",
    };
    vi.stubGlobal(
      "fetch",
      vi.fn().mockRejectedValue(new Error("network error")),
    );

    const result = await refreshAccessToken(token);

    expect(result.error).toBe("RefreshAccessTokenError");
  });
});
