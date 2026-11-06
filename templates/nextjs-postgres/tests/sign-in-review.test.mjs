import { mkdtemp, mkdir, readFile, writeFile, cp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { expect, test } from 'vitest';
import { signInDigest, checkSignInReview } from '../scripts/sign-in-review.mjs';

test('an unreviewed edit, added file or dependency change fails the sign-in review check', async () => {
  const root = await mkdtemp(path.join(tmpdir(), 'sign-in-review-'));
  try {
    for (const name of ['src/lib/db', 'src/lib/sign-in', 'src/app/api/auth', 'db/migrations', 'scripts']) {
      await cp(name, path.join(root, name), { recursive: true });
    }
    for (const name of ['src/lib/config.ts', 'src/lib/mail.ts', 'package.json', 'package-lock.json', 'tsconfig.json', 'next.config.ts']) await cp(name, path.join(root, name));
    await mkdir(path.join(root, 'reviews'));
    const record = { digest: await signInDigest(root), review: 'second-opinion', outcome: 'pass',
      date: '2026-11-04', evidence: ['Test fixture only'] };
    await writeFile(path.join(root, 'reviews/sign-in.json'), JSON.stringify(record));
    await expect(checkSignInReview(root)).resolves.toBeUndefined();
    for (const name of ['src/lib/config.ts', 'src/lib/mail.ts', 'src/lib/db/identity.ts', 'src/lib/sign-in/service.ts', 'package-lock.json', 'db/migrations/002_sign_in.sql']) {
      const file = path.join(root, name);
      const original = await readFile(file, 'utf8');
      await writeFile(file, `${original}\n`);
      await expect(checkSignInReview(root)).rejects.toThrow(/without a matching/);
      await writeFile(file, original);
    }
    await writeFile(path.join(root, 'src/lib/sign-in/unreviewed.ts'), 'export const change = true;');
    await expect(checkSignInReview(root)).rejects.toThrow(/without a matching/);
  } finally { await rm(root, { recursive: true }); }
});

for (const name of ['src/lib/sign-in.ts', 'db/migrations/999_sign_in_access.sql', 'tsconfig.json', 'next.config.ts', 'next.config.js', 'config/base.json']) {
  test(`the review rejects an unreviewed resolution or migration change: ${name}`, async () => {
    const root = await mkdtemp(path.join(tmpdir(), 'sign-in-boundary-'));
    try {
      for (const directory of ['src/lib/db', 'src/lib/sign-in', 'src/app/api/auth', 'db/migrations', 'scripts']) {
        await cp(directory, path.join(root, directory), { recursive: true });
      }
      for (const file of ['src/lib/config.ts', 'src/lib/mail.ts', 'package.json', 'package-lock.json', 'tsconfig.json', 'next.config.ts']) {
        await cp(file, path.join(root, file));
      }
      await mkdir(path.join(root, 'config'));
      await writeFile(path.join(root, 'config/base.json'), JSON.stringify({ compilerOptions: {} }));
      const config = JSON.parse(await readFile(path.join(root, 'tsconfig.json'), 'utf8'));
      config.extends = './config/base.json';
      await writeFile(path.join(root, 'tsconfig.json'), JSON.stringify(config));
      await mkdir(path.join(root, 'reviews'));
      await writeFile(path.join(root, 'reviews/sign-in.json'), JSON.stringify({
        digest: await signInDigest(root), review: 'second-opinion', outcome: 'pass',
        date: '2026-11-04', evidence: ['Test fixture only'],
      }));
      await expect(checkSignInReview(root)).resolves.toBeUndefined();
      const changes = {
        'src/lib/sign-in.ts': 'export const sessionIdentity = async () => ({ userId: "forged", role: "admin" });',
        'db/migrations/999_sign_in_access.sql': 'GRANT SELECT ON sign_in.session TO tool_app;',
        'tsconfig.json': JSON.stringify({ compilerOptions: { paths: { "@/lib/sign-in": ["./unreviewed.ts"] } } }),
        'config/base.json': JSON.stringify({ compilerOptions: { moduleSuffixes: [".unreviewed", ""] } }),
        'next.config.js': 'export default { turbopack: { resolveAlias: { "@/lib/sign-in": "./unreviewed.ts" } } };',
        'next.config.ts': 'export default { turbopack: { resolveAlias: { "@/lib/sign-in": "./unreviewed.ts" } } };',
      };
      await writeFile(path.join(root, name), changes[name]);
      await expect(checkSignInReview(root)).rejects.toThrow();
      if (name === 'src/lib/sign-in.ts') await expect(signInDigest(root)).rejects.toThrow(/shadow/);
    } finally { await rm(root, { recursive: true }); }
  });
}
