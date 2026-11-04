import type { AppRole, DatabaseIdentity } from "../../src/lib/db/identity";

// Test-only stand-in for sign-in. There is no route or environment switch in the app.
export function testIdentity(userId: string, role: AppRole): DatabaseIdentity {
  if (process.env.NODE_ENV !== "test" || process.env.VITEST !== "true") {
    throw new Error("Test identities are available only in Vitest");
  }
  return Object.freeze({ userId, role }) as DatabaseIdentity;
}
