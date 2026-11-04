import { randomBytes, randomUUID } from "node:crypto";
import { sql } from "kysely";
import { afterAll, beforeAll, describe, expect, test, vi } from "vitest";
import { createSignIn } from "../src/lib/sign-in/service";
import { validateConfig } from "../src/lib/sign-in/config";
import { withDatabase } from "../src/lib/db/with-database";
import { inspect } from "./support/database";
import { testIdentity } from "./support/identity";
import { stubProvider } from "./support/oidc";

const tenant = "11111111-1111-4111-8111-111111111111";
const domain = "example.test";
const baseURL = "https://tool.example.test";
const emails = new Map<string, string>();
let stub: Awaited<ReturnType<typeof stubProvider>>;
const services: ReturnType<typeof createSignIn>[] = [];
const configuration = () => ({ baseURL, secret: randomBytes(32).toString("hex"),
  databaseURL: process.env.AUTH_DATABASE_URL! });
function service(provider?: "microsoft" | "google") {
  const instance = createSignIn({ ...configuration(), ...(provider ? { directory: {
    provider, issuer: stub.issuer, tenant, domain, clientId: "stub-client", clientSecret: randomUUID(),
  } } : {}) }, async (email, url) => { emails.set(email, url); });
  services.push(instance);
  return instance;
}
type Service = ReturnType<typeof service>;
function cookies(response: Response) {
  return response.headers.getSetCookie().map((cookie) => cookie.split(";")[0]).join("; ");
}
function request(auth: Service, path: string, body?: unknown, cookie = "") {
  return auth.handler(new Request(new URL(`/api/auth${path}`, baseURL), {
    method: body ? "POST" : "GET", headers: { "Content-Type": "application/json", Origin: baseURL, Cookie: cookie },
    ...(body ? { body: JSON.stringify(body) } : {}),
  }));
}
async function login(auth: Service, provider: "microsoft" | "google") {
  const start = await request(auth, "/sign-in/social", { provider, callbackURL: "/" });
  expect(start.status).toBe(200);
  const { url } = await start.json();
  const authorisation = new URL(url);
  expect(authorisation.searchParams.get("nonce")).toBeTruthy();
  expect(authorisation.searchParams.get("code_challenge_method")).toBe("S256");
  if (provider === "google") expect(authorisation.searchParams.get("hd")).toBe(domain);
  const redirect = await fetch(url, { redirect: "manual" });
  return auth.handler(new Request(redirect.headers.get("location")!, { headers: { Cookie: cookies(start) } }));
}
async function invite(email: string, expires = new Date(Date.now() + 86400000)) {
  await withDatabase(testIdentity(randomUUID(), "admin"), (db) =>
    sql`insert into sign_in.invitations (email, "expiresAt") values (${email}, ${expires})`.execute(db));
}
async function link(auth: Service, email: string) {
  const response = await request(auth, "/sign-in/magic-link", { email });
  expect(response.status).toBe(200);
  return emails.get(email)!;
}
function sessionCookie(response: Response) {
  return response.headers.getSetCookie().find((cookie) => cookie.startsWith("__Secure-better-auth.session_token="));
}

beforeAll(async () => { stub = await stubProvider(); });
afterAll(async () => { await Promise.all(services.map((auth) => auth.close())); await stub.close(); });

for (const provider of ["microsoft", "google"] as const) {
  describe(provider, () => {
    test("staff sign in, receive their database role, and sign out on the server", async () => {
      const auth = service(provider);
      const email = `${randomUUID()}@example.test`;
      const claims = { tid: tenant, hd: domain, email, sub: randomUUID(),
        email_verified: provider === "google" ? true : undefined };
      stub.setClaims(claims);
      const response = await login(auth, provider);
      expect(response.status).toBe(302);
      expect(new URL(response.headers.get("location")!, baseURL).searchParams.has("error")).toBe(false);
      expect(sessionCookie(response)).toMatch(/Secure/);
      expect(sessionCookie(response)).toMatch(/HttpOnly/);
      expect(sessionCookie(response)).toMatch(/SameSite=Lax/i);
      expect(sessionCookie(response)).toMatch(/Max-Age=28800/);
      const headers = new Headers({ Cookie: cookies(response) });
      const identity = await auth.identity(headers);
      expect(identity?.role).toBe("member");
      const settings = await withDatabase(identity!, (db) => sql`select
        current_setting('app.user_id') as id, current_setting('app.role') as role`.execute(db));
      expect(settings.rows).toEqual([{ id: identity!.userId, role: "member" }]);
      // A returning account is checked against fresh claims, even with a known subject.
      stub.setClaims({ ...claims, ...(provider === "microsoft" ? { tid: randomUUID() } : { hd: "outsider.test" }) });
      expect(sessionCookie(await login(auth, provider))).toBeUndefined();
      await request(auth, "/sign-out", {}, cookies(response));
      expect(await auth.identity(headers)).toBeNull();
    });
    for (const failure of ["outside", "missing", "issuer", "audience", "signature", "expired", "nonce", "personal",
      ...(provider === "microsoft" ? ["foreign-home", "personal-sts", "personal-sts-variant"] : [])]) {
      test(`the server refuses ${failure} claims`, async () => {
        const auth = service(provider);
        const claims: Record<string, unknown> = { tid: tenant, hd: domain, email: `${randomUUID()}@example.test`, sub: randomUUID() };
        const key = provider === "microsoft" ? "tid" : "hd";
        if (failure === "outside") claims[key] = "other-company.test";
        if (failure === "missing") delete claims[key];
        if (failure === "issuer") claims.iss = "https://other-issuer.test";
        if (failure === "audience") claims.aud = "other-client";
        if (failure === "expired") claims.exp = 1;
        if (failure === "nonce") claims.nonce = "wrong-nonce";
        if (failure === "foreign-home") claims.idp = `https://sts.windows.net/${randomUUID()}/`;
        if (failure === "personal-sts") claims.idp = "https://sts.windows.net/9188040d-6c67-4c5b-b112-36a304b66dad/";
        if (failure === "personal-sts-variant") claims.idp = "https://sts.windows.net/9188040d-6c67-4c5b-b112-36a304b66dad/v2.0";
        if (failure === "personal") {
          if (provider === "microsoft") claims.idp = "live.com";
          else delete claims.hd;
        }
        stub.setClaims(claims, failure === "signature");
        const response = await login(auth, provider);
        expect(sessionCookie(response)).toBeUndefined();
        expect(await auth.identity(new Headers({ Cookie: cookies(response) }))).toBeNull();
        const rows = await inspect((db) => db.query('SELECT id FROM sign_in."user" WHERE email=$1', [claims.email]));
        expect(rows.rowCount).toBe(0);
      });
    }
  });
}

for (const form of ["issuer", "sts"]) {
  test(`Microsoft accepts its own ${form} identity provider`, async () => {
    const auth = service("microsoft");
    stub.setClaims({ tid: tenant, email: `${randomUUID()}@example.test`, sub: randomUUID(),
      email_verified: undefined, idp: form === "issuer" ? stub.issuer : `https://sts.windows.net/${tenant}/` });
    const response = await login(auth, "microsoft");
    expect(sessionCookie(response)).toBeDefined();
    expect((await auth.identity(new Headers({ Cookie: cookies(response) })))?.role).toBe("member");
  });
}

test("only invited outsiders receive a link; it grants viewer access once", async () => {
  const auth = service();
  const email = `${randomUUID()}@outside.test`;
  const uninvited = `${randomUUID()}@outside.test`;
  expect((await request(auth, "/sign-in/magic-link", { email: uninvited })).status).toBe(403);
  expect(emails.has(uninvited)).toBe(false);
  await invite(email);
  const url = await link(auth, email);
  const responses = await Promise.all([auth.handler(new Request(url)), auth.handler(new Request(url))]);
  expect(responses.filter(sessionCookie)).toHaveLength(1);
  const response = responses.find(sessionCookie)!;
  const identity = await auth.identity(new Headers({ Cookie: cookies(response) }));
  expect(identity?.role).toBe("viewer");
  const settings = await withDatabase(identity!, (db) => sql`select current_setting('app.role') as role`.execute(db));
  expect(settings.rows).toEqual([{ role: "viewer" }]);
  expect(sessionCookie(await auth.handler(new Request(url)))).toBeUndefined();
});

test("expired links and revoked invitations cannot establish a session", async () => {
  const auth = service();
  for (const failure of ["expired-link", "revoked", "expired-invitation"]) {
    const email = `${randomUUID()}@outside.test`;
    await invite(email);
    const url = await link(auth, email);
    await inspect(async (db) => {
      if (failure === "expired-link") await db.query(`UPDATE sign_in.verification SET "expiresAt"=now()-interval '1 second'
        WHERE value::jsonb->>'email'=$1`, [email]);
      else await db.query(`UPDATE sign_in.invitations SET revoked=$2, "expiresAt"=$3 WHERE email=$1`,
        [email, failure === "revoked", new Date(0)]);
    });
    expect(sessionCookie(await auth.handler(new Request(url)))).toBeUndefined();
  }
});

test("session expiry and invitation revocation deny existing cookies", async () => {
  const auth = service();
  for (const revoke of [false, true]) {
    const email = `${randomUUID()}@outside.test`;
    await invite(email);
    const response = await auth.handler(new Request(await link(auth, email)));
    const headers = new Headers({ Cookie: cookies(response) });
    const identity = await auth.identity(headers);
    expect(identity).not.toBeNull();
    await inspect((db) => revoke
      ? db.query('UPDATE sign_in.invitations SET revoked=true WHERE email=$1', [email])
      : db.query('UPDATE sign_in.session SET "expiresAt"=now() WHERE "userId"=$1', [identity!.userId]));
    expect(await auth.identity(headers)).toBeNull();
  }
});

test("public registration, account linking and role updates have no route", async () => {
  const auth = service();
  for (const path of ["/sign-up/email", "/update-user", "/link-social", "/sign-in/email"]) {
    expect((await request(auth, path, { email: "public@example.test", password: randomUUID(), role: "admin" })).status).toBe(404);
  }
});

test("production cannot use the stub issuer or a personal Microsoft tenant", () => {
  const config = { ...configuration(), directory: { provider: "microsoft" as const, issuer: stub.issuer,
    tenant: "9188040d-6c67-4c5b-b112-36a304b66dad", clientId: "stub-client", clientSecret: randomUUID() } };
  expect(() => validateConfig(config)).toThrow(/company tenant/);
  vi.stubEnv("NODE_ENV", "production");
  try {
    expect(() => validateConfig({ ...config, directory: { ...config.directory, tenant } })).toThrow(/issuer/);
  } finally { vi.unstubAllEnvs(); }
  expect(() => validateConfig({ ...configuration(), baseURL: "http://localhost:3001" })).toThrow(/HTTPS/);
});
