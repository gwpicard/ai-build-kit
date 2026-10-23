import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

test("D2 sign-in has no axe violations and shows its field label", async ({ page }) => {
  await page.goto("/login");
  const results = await new AxeBuilder({ page }).analyze();
  expect(results.violations).toEqual([]);

  // Axe accepts labels hidden from sight, so check their size separately.
  const label = page.locator('label[for="email"]');
  await expect(label).toBeVisible();
  const bounds = await label.boundingBox();
  expect(bounds?.width, "The email field needs a visible label").toBeGreaterThan(1);
  expect(bounds?.height, "The email field needs a visible label").toBeGreaterThan(1);

  const email = page.getByLabel("Email address");
  const button = page.getByRole("button", { name: "Send link" });
  const restingEmailShadow = await email.evaluate((element) => getComputedStyle(element).boxShadow);
  const restingButtonShadow = await button.evaluate((element) => getComputedStyle(element).boxShadow);
  await page.keyboard.press("Tab");
  await expect(email).toBeFocused();
  await expect(email).not.toHaveCSS("box-shadow", restingEmailShadow);
  await page.keyboard.press("Tab");
  await expect(button).toBeFocused();
  await expect(button).not.toHaveCSS("box-shadow", restingButtonShadow);
});
