export const appRoles = ["admin", "member", "viewer", "unassigned"] as const;
export type AppRole = (typeof appRoles)[number];

declare const verifiedIdentity: unique symbol;

// A later sign-in module must create this from a verified server session.
export type DatabaseIdentity = Readonly<{
  userId: string;
  role: AppRole;
  [verifiedIdentity]: true;
}>;
