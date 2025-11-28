import type { NextAuthConfig } from "next-auth";
import Google from "next-auth/providers/google";
import { refreshAccessToken, type AuthToken } from "./token";

const googleProvider = Google({
  clientId: process.env.AUTH_GOOGLE_ID ?? "",
  clientSecret: process.env.AUTH_GOOGLE_SECRET ?? "",
  issuer: process.env.AUTH_GOOGLE_ISSUER,
});

export const authConfig: NextAuthConfig = {
  trustHost: true,
  secret: process.env.AUTH_SECRET,
  pages: { signIn: "/login" },
  session: {
    strategy: "jwt",
    maxAge: 60 * 60 * 24 * 7, // 7 days
  },
  providers: [googleProvider],
  callbacks: {
    authorized({ auth, request }) {
      const isAuthenticated = Boolean(auth?.user);
      const path =
        request.nextUrl?.pathname ?? new URL(request.url).pathname;
      const isProtected = path.startsWith("/dashboard");

      if (isProtected && !isAuthenticated) {
        return false;
      }

      return true;
    },
    async jwt({ token, account }) {
      const typedToken = token as AuthToken;

      if (account) {
        return {
          ...typedToken,
          accessToken: account.access_token,
          refreshToken: account.refresh_token ?? typedToken.refreshToken,
          expiresAt: account.expires_at,
          idToken: account.id_token,
        };
      }

      if (
        typedToken.expiresAt &&
        typedToken.expiresAt - 60 < Date.now() / 1000
      ) {
        return refreshAccessToken(typedToken);
      }

      return typedToken;
    },
    async session({ session, token }) {
      const typedToken = token as AuthToken;

      if (typedToken.sub) {
        session.user = {
          ...session.user,
          id: typedToken.sub,
        };
      }

      if (typedToken.accessToken) {
        (session as typeof session & { accessToken?: string }).accessToken =
          typedToken.accessToken;
      }

      if (typedToken.idToken) {
        (session as typeof session & { idToken?: string }).idToken =
          typedToken.idToken;
      }

      return session;
    },
  },
};
