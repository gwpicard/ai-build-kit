import ts from 'typescript';
import { createHash } from 'node:crypto';
import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const project = fileURLToPath(new URL('../', import.meta.url));
export async function signInDigest(root = project) {
  const files = [];
  async function walk(relative) {
    for (const entry of await readdir(path.join(root, relative), { withFileTypes: true })) {
      const name = `${relative}/${entry.name}`;
      if (entry.isDirectory()) await walk(name);
      else if (entry.isFile()) files.push(name);
      else throw new Error('The sign-in review does not accept symbolic links');
    }
  }
  for (const entry of await readdir(path.join(root, 'src/lib'))) {
    if (entry.startsWith('sign-in.')) throw new Error('A sibling module can shadow the sign-in entry point');
  }
  await walk('src/lib/sign-in');
  await walk('src/app/api/auth');
  await walk('db/migrations');
  // Include alternate Next.js configurations and every inherited TypeScript config.
  for (const name of await readdir(root)) {
    if (name.startsWith('next.config.') || name === 'jsconfig.json') files.push(name);
  }
  ts.getParsedCommandLineOfConfigFile(path.join(root, 'tsconfig.json'), {}, {
    ...ts.sys,
    readFile(file) {
      const content = ts.sys.readFile(file);
      if (content !== undefined) {
        const relative = path.relative(root, file);
        if (relative.startsWith('..') || path.isAbsolute(relative)) {
          throw new Error('Module-resolution settings must be inside the reviewed project');
        }
        files.push(relative);
      }
      return content;
    },
    onUnRecoverableConfigFileDiagnostic() { throw new Error('Cannot read module-resolution settings'); },
  });
  files.push('src/lib/db/identity.ts', 'tsconfig.json', 'next.config.ts', 'package.json', 'package-lock.json',
    'scripts/database-boundary.mjs', 'scripts/sign-in-review.mjs');
  const hash = createHash('sha256');
  for (const name of [...new Set(files)].sort()) {
    const content = await readFile(path.join(root, name));
    hash.update(`${name}\0${content.length}\0`).update(content);
  }
  return hash.digest('hex');
}

export async function checkSignInReview(root = project) {
  const record = JSON.parse(await readFile(path.join(root, 'reviews/sign-in.json'), 'utf8'));
  if (record.digest !== await signInDigest(root) || record.outcome !== 'pass'
    || record.review !== 'second-opinion' || !/^\d{4}-\d{2}-\d{2}$/.test(record.date)
    || !Array.isArray(record.evidence) || record.evidence.length === 0) {
    throw new Error('Sign-in changed without a matching second-opinion record');
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    if (process.argv[2] === '--digest') console.log(await signInDigest());
    else { await checkSignInReview(); console.log('Sign-in second-opinion record matches'); }
  } catch {
    console.error('Sign-in needs a passing second opinion for its current digest; see SIGN-IN.md');
    process.exitCode = 1;
  }
}
