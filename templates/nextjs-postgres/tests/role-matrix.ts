import type { AppRole } from "../src/lib/db/identity";

export type Scope = "self" | "other";
export const tables = ["records", "withheld", "audit.events"] as const;
export type Table = (typeof tables)[number];
type Permissions = { read: Scope[]; insert: Scope[]; update: Scope[]; delete: Scope[] };
const none: Permissions = { read: [], insert: [], update: [], delete: [] };
const all: Permissions = {
  read: ["self", "other"], insert: ["self", "other"],
  update: ["self", "other"], delete: ["self", "other"],
};

// Expectations are independent of the SQL policies. Every role covers every table.
export const roleMatrix: Record<AppRole, Record<Table, Permissions>> = {
  admin: { records: all, withheld: none, "audit.events": { ...none, read: ["self", "other"] } },
  member: { records: { read: ["self"], insert: ["self"], update: ["self"], delete: ["self"] },
    withheld: none, "audit.events": none },
  viewer: { records: { ...none, read: ["self"] }, withheld: none, "audit.events": none },
  system: { records: none, withheld: none, "audit.events": none },
  unassigned: { records: none, withheld: none, "audit.events": none },
};
