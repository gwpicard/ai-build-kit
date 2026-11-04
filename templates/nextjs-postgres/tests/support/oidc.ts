import { createServer } from "node:http";
import { createHash, randomUUID } from "node:crypto";
import { exportJWK, generateKeyPair, SignJWT, type JWTPayload } from "jose";

export async function stubProvider() {
  const keys = await generateKeyPair("RS256");
  const wrongKeys = await generateKeyPair("RS256");
  const jwk = { ...await exportJWK(keys.publicKey), kid: "stub", alg: "RS256", use: "sig" };
  const pending = new Map<string, { nonce: string; challenge: string; redirect: string; claims: JWTPayload }>();
  let claims: JWTPayload = {};
  let badSignature = false;
  let issuer = "";
  const server = createServer(async (request, response) => {
    const url = new URL(request.url!, issuer);
    response.setHeader("Content-Type", "application/json");
    if (url.pathname.endsWith("/.well-known/openid-configuration")) {
      response.end(JSON.stringify({ issuer, authorization_endpoint: `${issuer}/authorize`,
        token_endpoint: `${issuer}/token`, jwks_uri: `${issuer}/jwks`,
        response_types_supported: ["code"], subject_types_supported: ["public"],
        id_token_signing_alg_values_supported: ["RS256"],
        code_challenge_methods_supported: ["S256"] }));
    } else if (url.pathname.endsWith("/jwks")) response.end(JSON.stringify({ keys: [jwk] }));
    else if (url.pathname.endsWith("/authorize")) {
      const code = randomUUID();
      pending.set(code, { nonce: url.searchParams.get("nonce")!, challenge: url.searchParams.get("code_challenge")!,
        redirect: url.searchParams.get("redirect_uri")!, claims: { ...claims } });
      const redirect = new URL(url.searchParams.get("redirect_uri")!);
      redirect.searchParams.set("code", code);
      redirect.searchParams.set("state", url.searchParams.get("state")!);
      response.writeHead(302, { Location: redirect.href }).end();
    } else if (url.pathname.endsWith("/token")) {
      let body = "";
      for await (const part of request) body += part;
      const params = new URLSearchParams(body);
      const code = params.get("code")!;
      const entry = pending.get(code);
      pending.delete(code);
      if (!entry || !entry.nonce || !entry.challenge || params.get("redirect_uri") !== entry.redirect
        || createHash("sha256").update(params.get("code_verifier") ?? "").digest("base64url") !== entry.challenge) {
        response.writeHead(400).end(JSON.stringify({ error: "invalid_grant" }));
        return;
      }
      const token = await new SignJWT({ email: "staff@example.test", email_verified: true,
        name: "Staff", nonce: entry.nonce, ...entry.claims })
        .setProtectedHeader({ alg: "RS256", kid: "stub" })
        .setIssuer(String(entry.claims.iss ?? issuer)).setAudience(String(entry.claims.aud ?? "stub-client"))
        .setSubject(String(entry.claims.sub ?? "staff-subject")).setIssuedAt()
        .setExpirationTime(entry.claims.exp ?? "5m").sign(badSignature ? wrongKeys.privateKey : keys.privateKey);
      response.end(JSON.stringify({ access_token: randomUUID(), token_type: "Bearer", expires_in: 300, id_token: token }));
    } else response.writeHead(404).end();
  });
  await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
  const address = server.address();
  if (!address || typeof address === "string") throw new Error("The stub needs a TCP port");
  issuer = `http://127.0.0.1:${address.port}`;
  return { issuer, setClaims(next: JWTPayload, invalidSignature = false) { claims = next; badSignature = invalidSignature; },
    close: () => new Promise<void>((resolve, reject) => server.close((error) => error ? reject(error) : resolve())) };
}
