import { spawnSync } from 'node:child_process';
import { mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { expect, test } from 'vitest';

for (const provider of ['none', 'microsoft', 'google']) test(`web startup validates ${provider} sign-in before running the server`, () => {
  const dir = mkdtempSync(join(tmpdir(), 'web-startup-'));
  const secret = join(dir, 'secret');
  writeFileSync(secret, 'synthetic-startup-fixture-'.repeat(2));
  const env = {
    PATH: process.env.PATH, NODE_ENV: 'production',
    DATABASE_URL: 'postgresql://tool_app@database.test/tool', JOBS_MODE: 'worker',
    FILES_S3_BUCKET: 'private-files', FILES_S3_REGION: 'local',
    SMTP_HOST: 'smtp.example.test', SMTP_PORT: '587', SMTP_USER: 'fixture', SMTP_PASSWORD: 'fixture',
    MAIL_FROM: 'tool@example.test', SMTP_FROM: 'sign-in@example.test', SMTP_PASSWORD_FILE: secret,
    AUTH_BASE_URL: 'https://tool.example.test', AUTH_SECRET_FILE: secret,
    AUTH_DATABASE_URL: 'postgresql://tool_auth@database.test/tool', STAFF_PROVIDER: provider,
    STAFF_CLIENT_SECRET_FILE: secret, STAFF_CLIENT_ID: 'fixture-client',
    MICROSOFT_TENANT_ID: '11111111-1111-1111-1111-111111111111',
    STAFF_ISSUER: provider === 'google' ? 'https://accounts.google.com' : 'https://login.microsoftonline.com/11111111-1111-1111-1111-111111111111/v2.0',
    GOOGLE_WORKSPACE_DOMAIN: 'example.test',
  };
  const start = settings => spawnSync(process.execPath, ['--import', './scripts/startup.mjs', '--input-type=module', '-e', 'process.stdout.write("server-started\\n")'], { env: settings, encoding: 'utf8' });
  try {
    const valid = start(env);
    expect(valid.status, valid.stderr).toBe(0);
    expect(valid.stdout).toContain('server-started');
    for (const name of ['AUTH_SECRET_FILE', 'SMTP_PASSWORD_FILE', ...(provider === 'none' ? [] : ['STAFF_CLIENT_SECRET_FILE'])]) {
      for (const value of ['', join(dir, 'absent')]) {
        const invalid = start({ ...env, [name]: value });
        expect(invalid.status).toBe(1);
        expect(invalid.stdout).toBe('{"event":"configuration.invalid","role":"web"}\n');
        expect(invalid.stderr).toBe('');
      }
    }
    for (const name of ['AUTH_BASE_URL', 'AUTH_DATABASE_URL', 'SMTP_FROM', ...(provider === 'none' ? [] : ['STAFF_ISSUER', 'STAFF_CLIENT_ID'])]) {
      expect(start({ ...env, [name]: '' }).status, name).toBe(1);
    }
  } finally { rmSync(dir, { recursive: true }); }
});
