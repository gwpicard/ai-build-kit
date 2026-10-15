import { describe, expect, it } from "vitest";

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
