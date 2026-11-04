import "server-only";
import { createRemoteJWKSet, jwtVerify } from "jose";
import type { Directory } from "./config";

export function directoryProvider(directory: Directory) {
  let keys: ReturnType<typeof createRemoteJWKSet> | undefined;
  return {
    providerId: directory.provider,
    discoveryUrl: `${directory.issuer}/.well-known/openid-configuration`,
    clientId: directory.clientId,
    clientSecret: directory.clientSecret,
    scopes: ["openid", "email", "profile"],
    pkce: true,
    requireIdTokenVerification: true,
    disableProviderLogout: true,
    authorizationUrlParams: directory.provider === "google" ? { hd: directory.domain! } : undefined,
    async getUserInfo(tokens: { idToken?: string }) {
      try {
        if (!tokens.idToken) return null;
        if (!keys) {
          const response = await fetch(`${directory.issuer}/.well-known/openid-configuration`, {
            signal: AbortSignal.timeout(10000),
          });
          if (!response.ok) return null;
          const discovery = await response.json();
          if (discovery.issuer !== directory.issuer) return null;
          const jwks = new URL(discovery.jwks_uri);
          if (jwks.protocol !== "https:" && !(process.env.NODE_ENV === "test"
            && process.env.VITEST === "true" && jwks.hostname === "127.0.0.1")) return null;
          keys = createRemoteJWKSet(jwks);
        }
        const { payload } = await jwtVerify(tokens.idToken, keys, {
          issuer: directory.issuer, audience: directory.clientId,
          algorithms: ["RS256"], requiredClaims: ["sub", "iat", "exp", "email"],
        });
        if (directory.provider === "microsoft") {
          const companyProviders = [directory.issuer, `https://sts.windows.net/${directory.tenant}/`];
          if (payload.tid !== directory.tenant || (payload.idp !== undefined
            && (typeof payload.idp !== "string" || !companyProviders.includes(payload.idp)))) return null;
        }
        if (directory.provider === "google" && (payload.hd !== directory.domain || payload.email_verified !== true)) return null;
        if (typeof payload.email !== "string" || typeof payload.sub !== "string") return null;
        return { id: payload.sub, sub: payload.sub, email: payload.email.toLowerCase(),
          name: typeof payload.name === "string" ? payload.name : payload.email,
          emailVerified: payload.email_verified === true };
      } catch {
        // Provider responses and tokens must never reach application logs.
        return null;
      }
    },
  };
}
