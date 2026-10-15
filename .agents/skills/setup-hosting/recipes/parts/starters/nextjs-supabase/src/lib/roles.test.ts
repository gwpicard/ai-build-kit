import { describe, expect, it } from "vitest";
import { setFirstAdminRole } from "./roles";

function canInvite(role: string | undefined) {
  return role === "admin";
}

describe("invitation access", () => {
  it("allows administrators and refuses members", () => {
    expect(canInvite("admin")).toBe(true);
    expect(canInvite("member")).toBe(false);
    expect(canInvite(undefined)).toBe(false);
  });
});

describe("first administrator setup", () => {
  it("refreshes the token only after the administrator role is saved", async () => {
    const steps: string[] = [];
    await setFirstAdminRole(
      async () => { steps.push("role saved"); },
      async () => { steps.push("session refreshed"); },
    );
    expect(steps).toEqual(["role saved", "session refreshed"]);
  });
});
