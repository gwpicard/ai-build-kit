#!/usr/bin/env sh
# starter-interface.sh: prove a copied starter rejects raw controls, colours and hidden labels.

set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
WORK=$(mktemp -d)
trap 'rm -R "$WORK"' EXIT INT TERM
PROJECT="$WORK/project"
mkdir "$PROJECT"
fail() { echo "FAIL: $1" >&2; exit 1; }
sh "$ROOT/.agents/skills/setup-ai-build-kit/scripts/use-starter.sh" recipes/nextjs-supabase-on-vercel "$PROJECT" >/dev/null
cd "$PROJECT"
npm ci --no-fund > "$WORK/install.log" 2>&1 || { cat "$WORK/install.log"; fail "could not install the copied starter"; }

# Use an unused port, and wait for sign-in rather than the database health route.
PORT=$(node -e 'const s=require("node:net").createServer();s.listen(0,"127.0.0.1",()=>{console.log(s.address().port);s.close()})')
cat > playwright.interface.config.ts <<CONFIG
import config from "./playwright.config";
const interfaceConfig = {
  ...config,
  use: { ...config.use, baseURL: "http://127.0.0.1:$PORT" },
  webServer: {
    command: "npm run start -- --port $PORT",
    url: "http://127.0.0.1:$PORT/login",
    reuseExistingServer: false,
  },
};
export default interfaceConfig;
CONFIG
# Exercise the current form components without changing the starter's pages.
mkdir -p src/app/field-rehearsal
cat > src/app/field-rehearsal/page.tsx <<'TSX'
"use client";

import { useState } from "react";
import { Controller, useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { Button } from "@/components/ui/button";
import { Field, FieldError, FieldLabel } from "@/components/ui/field";
import { Input } from "@/components/ui/input";

const schema = z.object({ email: z.string().email("Enter an email address.") });

export default function FieldRehearsal() {
  const [saved, setSaved] = useState("");
  const form = useForm<z.infer<typeof schema>>({
    resolver: zodResolver(schema), defaultValues: { email: "" }, mode: "onBlur",
  });
  return (
    <main>
      <h1>Form rehearsal</h1>
      <form noValidate onSubmit={form.handleSubmit((values) => setSaved(values.email))}>
        <Controller name="email" control={form.control} render={({ field, fieldState }) => (
          <Field data-invalid={fieldState.invalid}>
            <FieldLabel htmlFor="field-email">Email address</FieldLabel>
            <Input {...field} id="field-email" type="email" aria-invalid={fieldState.invalid}
              aria-describedby={fieldState.invalid ? "field-email-error" : undefined} />
            {fieldState.invalid && <FieldError id="field-email-error" errors={[fieldState.error]} />}
          </Field>
        )} />
        <Button type="submit">Save email</Button>
      </form>
      <output>{saved}</output>
    </main>
  );
}
TSX
cat > e2e/field-rehearsal.spec.ts <<'TS'
import { expect, test } from "@playwright/test";

test("Field works with react-hook-form and zod", async ({ page }) => {
  await page.goto("/field-rehearsal");
  await page.getByLabel("Email address").fill("wrong");
  await page.getByRole("button", { name: "Save email" }).click();
  await expect(page.getByText("Enter an email address.")).toBeVisible();
  await expect(page.getByLabel("Email address")).toHaveAttribute("aria-invalid", "true");
  await page.getByLabel("Email address").fill("person@example.com");
  await page.getByLabel("Email address").press("Tab");
  await expect(page.getByText("Enter an email address.")).toHaveCount(0);
  await page.getByRole("button", { name: "Save email" }).click();
  await expect(page.locator("output")).toHaveText("person@example.com");
  await expect(page.getByText("Enter an email address.")).toHaveCount(0);
});
TS
npm run check > "$WORK/check.log" 2>&1 || { cat "$WORK/check.log"; fail "the clean copied starter failed scripts/check.sh"; }
echo "ok: the clean copied starter passes scripts/check.sh"
npx playwright install chromium > "$WORK/browser.log" 2>&1 || { cat "$WORK/browser.log"; fail "could not install Chromium"; }
sh "$ROOT/.agents/skills/setup-hosting/recipes/parts/scripts/interface.sh" --config playwright.interface.config.ts > "$WORK/interface.log" 2>&1 || { cat "$WORK/interface.log"; fail "the clean sign-in interface check failed"; }
echo "ok: the clean copied starter passes lint and the axe test"
npm run test:e2e -- e2e/field-rehearsal.spec.ts --config playwright.interface.config.ts > "$WORK/field.log" 2>&1 || { cat "$WORK/field.log"; fail "Field did not work with react-hook-form and zod"; }
echo "ok: Field shows zod errors and submits a valid value through react-hook-form"


node --input-type=module <<'JS'
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { spawnSync } from 'node:child_process';
const faults = [
  ['raw button', '<button>Save</button>', 'no-restricted-syntax', 'Use a component'],
  ['raw input', '<input />', 'no-restricted-syntax', 'Use a component'],
  ['raw select', '<select />', 'no-restricted-syntax', 'Use a component'],
  ['raw textarea', '<textarea />', 'no-restricted-syntax', 'Use a component'],
  ['palette colour', '<div className="bg-slate-900" />', 'better-tailwindcss/no-restricted-classes', 'Use a design colour'],
  ['Tailwind 4.3 mauve palette', '<div className="bg-mauve-900" />', 'better-tailwindcss/no-restricted-classes', 'Use a design colour'],
  ['Tailwind 4.3 olive palette', '<div className="bg-olive-900" />', 'better-tailwindcss/no-restricted-classes', 'Use a design colour'],
  ['Tailwind 4.3 mist palette', '<div className="bg-mist-900" />', 'better-tailwindcss/no-restricted-classes', 'Use a design colour'],
  ['Tailwind 4.3 taupe palette', '<div className="bg-taupe-900" />', 'better-tailwindcss/no-restricted-classes', 'Use a design colour'],
  ['variant palette colour', '<div className="hover:bg-slate-900/50" />', 'better-tailwindcss/no-restricted-classes', 'Use a design colour'],
  ['hex colour', '<div className="bg-[#123456]" />', 'better-tailwindcss/no-restricted-classes', 'Use a named design colour'],
  ['arbitrary property colour', '<div className="[color:red]" />', 'better-tailwindcss/no-restricted-classes', 'Use a named design colour'],
  ['arbitrary named colour', '<div className="bg-[rebeccapurple]" />', 'better-tailwindcss/no-restricted-classes', 'Use a named design colour'],
  ['arbitrary rgb colour', '<div className="text-[rgb(1,2,3)]" />', 'better-tailwindcss/no-restricted-classes', 'Use a named design colour'],
  ['inline style colour', '<div style={{ color: "red" }} />', 'no-restricted-syntax', 'Use design colour classes'],
  ['unknown class', '<div className="made-up-class" />', 'better-tailwindcss/no-unknown-classes', 'Unknown class'],
  ['conflicting classes', '<div className="p-2 p-4" />', 'better-tailwindcss/no-conflicting-classes', 'Conflicting class'],
];
const file = 'src/interface-fault.tsx';
try {
  for (const [name, jsx, rule, message] of faults) {
    fs.writeFileSync(file, `export default function Fault() { return ${jsx}; }\n`);
    const result = spawnSync('npm', ['run', 'lint', '--', '--format', 'json'], { encoding: 'utf8' });
    assert.equal(result.status, 1, `${name}: lint did not reject the fault: ${result.stdout}\n${result.stderr}`);
    const reports = JSON.parse(result.stdout.slice(result.stdout.indexOf('[{')));
    assert.ok(reports.some(report => report.filePath.endsWith('/'+file) && report.messages.some(item => item.ruleId === rule && item.message.includes(message))),
      `${name}: the intended rule did not catch the fault: ${result.stdout}`);
    console.log(`ok: planted ${name}; npm run lint caught it with ${rule}`);
    fs.unlinkSync(file);
  }
  fs.writeFileSync(file, 'export default function Sizing() { return <div className="text-[length:2rem]" style={{ width: 32 }} />; }\n');
  const sizing = spawnSync('npm', ['run', 'lint'], { encoding: 'utf8' });
  assert.equal(sizing.status, 0, `Colour rules rejected sizing: ${sizing.stdout}\n${sizing.stderr}`);
  console.log('ok: colour rules allow a length utility and an inline width');
} finally {
  if (fs.existsSync(file)) fs.unlinkSync(file);
}
JS

cp src/app/login/page.tsx "$WORK/login.before"
python3 - <<'PY'
from pathlib import Path
p = Path('src/app/login/page.tsx')
s = p.read_text()
assert '<Label htmlFor="email">' in s
p.write_text(s.replace('<Label htmlFor="email">', '<Label className="sr-only" htmlFor="email">'))
PY
npm run build > "$WORK/hidden-build.log" 2>&1 || { cat "$WORK/hidden-build.log"; fail "the hidden-label fixture did not build"; }
if npm run test:e2e -- e2e/accessibility.spec.ts --config playwright.interface.config.ts > "$WORK/hidden.log" 2>&1; then
  fail "the axe test accepted the planted hidden label"
fi
grep -qF 'The email field needs a visible label' "$WORK/hidden.log" || { cat "$WORK/hidden.log"; fail "the hidden label failed for another reason"; }
echo "ok: planted hidden sign-in label; e2e/accessibility.spec.ts caught it with the visible-label assertion beside axe"

# Prove the axe assertion itself fails too, independently of label visibility.
cp "$WORK/login.before" src/app/login/page.tsx
python3 - <<'PY'
from pathlib import Path
p = Path('src/app/login/page.tsx')
s = p.read_text()
assert '<Label htmlFor="email">Email address</Label>' in s
p.write_text(s.replace('<Label htmlFor="email">Email address</Label>', ''))
PY
npm run build > "$WORK/unlabelled-build.log" 2>&1 || { cat "$WORK/unlabelled-build.log"; fail "the unlabelled-field fixture did not build"; }
if npm run test:e2e -- e2e/accessibility.spec.ts --config playwright.interface.config.ts > "$WORK/unlabelled.log" 2>&1; then
  fail "axe accepted a field without a label"
fi
grep -qF 'Form elements must have labels' "$WORK/unlabelled.log" || { cat "$WORK/unlabelled.log"; fail "the unlabelled field failed for another reason"; }
echo "ok: planted sign-in field without a label; axe caught its label violation"
