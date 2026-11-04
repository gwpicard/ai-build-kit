import "server-only";
import { betterAuth } from "better-auth";
import { APIError, createAuthMiddleware } from "better-auth/api";
import { genericOAuth, magicLink } from "better-auth/plugins";
import { appRoles, type DatabaseIdentity } from "../db/identity";
import { type SignInConfig, validateConfig } from "./config";
import { directoryProvider } from "./directory";
import { signInStorage } from "./storage";

export function createSignIn(config: SignInConfig, sendLink: (email: string, url: string) => Promise<void>) {
  validateConfig(config);
  const storage = signInStorage(config.databaseURL);
  const auth = betterAuth({
    baseURL: config.baseURL, secret: config.secret, database: storage.pool,
    trustedOrigins: [config.baseURL],
    logger: { disabled: true },
    emailAndPassword: { enabled: false, disableSignUp: true },
    account: { accountLinking: { enabled: false }, storeAccountCookie: false, encryptOAuthTokens: true },
    session: { expiresIn: 60 * 60 * 8, disableSessionRefresh: true, cookieCache: { enabled: false } },
    advanced: { useSecureCookies: true, database: { generateId: "uuid" },
      defaultCookieAttributes: { secure: true, httpOnly: true, sameSite: "lax", path: "/" } },
    user: { additionalFields: {
      role: { type: "string", required: true, defaultValue: "member", input: false },
      kind: { type: "string", required: true, defaultValue: "staff", input: false },
    } },
    hooks: { before: createAuthMiddleware(async (ctx) => {
      if (ctx.path === "/sign-in/magic-link") {
        const email = typeof ctx.body?.email === "string" ? ctx.body.email.trim().toLowerCase() : "";
        if (!email || !await storage.prepareOutsider(email)) {
          throw new APIError("FORBIDDEN", { message: "Email sign-in requires a current invitation" });
        }
        ctx.body.email = email;
      }
    }) },
    databaseHooks: { session: { create: { before: async (session) => {
      if (!await storage.allowedUser(session.userId)) return false;
      return { data: session };
    } } } },
    plugins: [
      genericOAuth({ config: config.directory ? [directoryProvider(config.directory)] : [] }),
      magicLink({ disableSignUp: true, expiresIn: 600, storeToken: "hashed",
        sendMagicLink: async ({ email, url }) => {
          if (!await storage.invited(email)) throw new APIError("FORBIDDEN");
          await sendLink(email, url);
        } }),
    ],
  });
  async function identity(headers: Headers): Promise<DatabaseIdentity | null> {
    const session = await auth.api.getSession({ headers });
    if (!session || !appRoles.includes(session.user.role as DatabaseIdentity["role"])
      || !await storage.allowedUser(session.user.id)) return null;
    return Object.freeze({ userId: session.user.id, role: session.user.role }) as DatabaseIdentity;
  }
  async function handler(request: Request): Promise<Response> {
    const path = new URL(request.url).pathname.replace(/^\/api\/auth/, "");
    const allowed = request.method === "POST"
      ? ["/sign-in/social", "/sign-in/magic-link", "/sign-out"].includes(path)
      : request.method === "GET" && (["/get-session", "/magic-link/verify"].includes(path)
        || /^\/callback\/(microsoft|google)$/.test(path));
    if (!allowed) return new Response(null, { status: 404 });
    return auth.handler(request);
  }
  return { handler, identity, close: () => storage.pool.end() };
}
