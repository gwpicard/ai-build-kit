import "server-only";
import type { DatabaseIdentity } from "../db/identity";

// Fixed server identity. Payloads cannot choose a user or role.
export const jobIdentity = Object.freeze({
  userId: "00000000-0000-4000-8000-000000000001",
  role: "system",
}) as DatabaseIdentity;
