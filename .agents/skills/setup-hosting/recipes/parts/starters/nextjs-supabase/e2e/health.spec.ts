import { expect, test } from "@playwright/test";

test("D1 health reports the local database", async ({ request }) => {
  const response = await request.get("/api/health");
  expect(response.status()).toBe(200);
  const health = await response.json();
  expect(health).toMatchObject({ status: "ok", database: "reachable" });
});
