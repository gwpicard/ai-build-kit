export const appRoles = ["admin", "member", "viewer", "unassigned"] as const;
export type AppRole = (typeof appRoles)[number];

declare const verifiedIdentity: unique symbol;

// Only the sign-in module constructs this from a verified server session.
export type DatabaseIdentity = Readonly<{
  userId: string;
  role: AppRole;
  [verifiedIdentity]: true;
}>;
