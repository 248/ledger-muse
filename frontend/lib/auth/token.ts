import type { JWT } from "next-auth/jwt";

export type AuthToken = JWT & {
  accessToken?: string;
  refreshToken?: string;
  expiresAt?: number;
  error?: string;
};

const defaultTokenEndpoint =
  "https://oauth2.googleapis.com/token";

export async function refreshAccessToken(
  token: AuthToken,
): Promise<AuthToken> {
  if (!token.refreshToken) {
    return { ...token, error: "RefreshTokenMissing" };
  }

  const endpoint =
    process.env.AUTH_TOKEN_ENDPOINT ?? defaultTokenEndpoint;

  try {
    const response = await fetch(endpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        client_id: process.env.AUTH_GOOGLE_ID ?? "",
        client_secret: process.env.AUTH_GOOGLE_SECRET ?? "",
        grant_type: "refresh_token",
        refresh_token: token.refreshToken,
      }),
    });

    if (!response.ok) {
      return { ...token, error: "RefreshAccessTokenError" };
    }

    const refreshed = (await response.json()) as {
      access_token?: string;
      refresh_token?: string;
      expires_in?: number;
    };

    return {
      ...token,
      accessToken: refreshed.access_token ?? token.accessToken,
      refreshToken: refreshed.refresh_token ?? token.refreshToken,
      expiresAt:
        Math.floor(Date.now() / 1000) +
        (refreshed.expires_in ?? 60 * 60),
      error: undefined,
    };
  } catch {
    return { ...token, error: "RefreshAccessTokenError" };
  }
}
