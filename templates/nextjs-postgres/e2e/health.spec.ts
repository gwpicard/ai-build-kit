import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

test("the starter page and process health respond without sign-in", async ({ page, request }) => {
  const response = await request.get("/api/health");
  expect(response.status()).toBe(200);
  expect(await response.json()).toEqual({ status: "ok" });
  await page.goto("/");
  await expect(page.getByRole("heading", { name: "Your workspace is ready" })).toBeVisible();
  expect((await new AxeBuilder({ page }).analyze()).violations).toEqual([]);
});
