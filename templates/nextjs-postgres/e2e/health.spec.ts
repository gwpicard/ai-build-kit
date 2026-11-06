import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

test("the page, protected timer route and runner health work through the production server", async ({ page, request }) => {
  for (const authorization of [undefined, "Bearer wrong"]) {
    const refused = await request.post("/api/jobs/tick", {
      headers: authorization ? { authorization } : {},
    });
    expect(refused.status()).toBe(401);
  }
  const tick = await request.post("/api/jobs/tick", {
    headers: { authorization: `Bearer ${process.env.JOBS_TIMER_TOKEN}` },
  });
  expect(tick.status()).toBe(200);
  const response = await request.get("/api/health");
  expect(response.status()).toBe(200);
  expect(await response.json()).toEqual({ status: "ok", commit: process.env.SOURCE_COMMIT || null, database: "ok", jobs: "ok" });
  await page.goto("/");
  await expect(page.getByRole("heading", { name: "Your workspace is ready" })).toBeVisible();
  expect((await new AxeBuilder({ page }).analyze()).violations).toEqual([]);
});
