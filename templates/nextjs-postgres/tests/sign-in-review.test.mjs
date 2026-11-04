import { mkdtemp, mkdir, readFile, writeFile, cp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { expect, test } from 'vitest';
import { signInDigest, checkSignInReview } from '../scripts/sign-in-review.mjs';

test('an unreviewed edit, added file or dependency change fails the sign-in review check', async () => {
  const root = await mkdtemp(path.join(tmpdir(), 'sign-in-review-'));
  try {
    for (const name of ['src/lib/sign-in', 'src/app/api/auth', 'db/migrations', 'scripts']) {
      await cp(name, path.join(root, name), { recursive: true });
    }
    for (const name of ['package.json', 'package-lock.json']) await cp(name, path.join(root, name));
    await mkdir(path.join(root, 'reviews'));
    const record = { digest: await signInDigest(root), review: 'second-opinion', outcome: 'pass',
      date: '2026-11-04', evidence: ['Test fixture only'] };
    await writeFile(path.join(root, 'reviews/sign-in.json'), JSON.stringify(record));
    await expect(checkSignInReview(root)).resolves.toBeUndefined();
    for (const name of ['src/lib/sign-in/service.ts', 'package-lock.json', 'db/migrations/002_sign_in.sql']) {
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
