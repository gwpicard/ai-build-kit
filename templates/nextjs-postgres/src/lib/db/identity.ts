export const userRoles = ["admin", "member", "viewer", "unassigned"] as const;
export type UserRole = (typeof userRoles)[number];
export const appRoles = [...userRoles, "system"] as const;
export type AppRole = (typeof appRoles)[number];

declare const verifiedIdentity: unique symbol;

// Sign-in constructs user identities; jobs use their fixed server identity.
export type DatabaseIdentity = Readonly<{
  userId: string;
  role: AppRole;
  [verifiedIdentity]: true;
}>;
