import { mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import * as sharedMail from '../src/lib/mail';
import { sendSignInLink } from '../src/lib/sign-in/mail';
import { SMTPServer } from 'smtp-server';
import { expect, test, vi } from 'vitest';
import { sendMail } from '../src/lib/mail';
import { mailConfig, validateRuntime } from '../src/lib/config';

test('one mail function delivers through SMTP and logs no message or credentials', async () => {
  const messages = [];
  const server = new SMTPServer({ disabledCommands: ['AUTH', 'STARTTLS'],
    onData(stream, session, callback) {
      let message = '';
      stream.on('data', chunk => { message += chunk; });
      stream.on('end', () => { messages.push(message); callback(); });
    }, logger: false });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const output = vi.spyOn(console, 'log').mockImplementation(() => {});
  vi.stubEnv('SMTP_HOST', '127.0.0.1'); vi.stubEnv('SMTP_PORT', String(server.server.address().port));
  vi.stubEnv('SMTP_SECURE', 'false'); vi.stubEnv('SMTP_USER', ''); vi.stubEnv('SMTP_PASSWORD', '');
  vi.stubEnv('MAIL_FROM', 'tool@example.test');
  try {
    await sendMail({ to: 'person@example.test', subject: 'SMTP fixture', text: 'Private test message' });
    expect(messages).toHaveLength(1);
    expect(messages[0]).toContain('Private test message');
    expect(output.mock.calls).toEqual([[JSON.stringify({ event: 'mail.sent' })]]);
  } finally { output.mockRestore(); vi.unstubAllEnvs(); await new Promise(resolve => server.close(resolve)); }
});
test('SMTP failure is safe to report and production requires TLS and credentials', async () => {
  vi.stubEnv('NODE_ENV', 'production'); vi.stubEnv('SMTP_HOST', 'smtp.example.test');
  vi.stubEnv('SMTP_PORT', '587'); vi.stubEnv('SMTP_USER', 'fixture'); vi.stubEnv('SMTP_PASSWORD', 'fixture');
  vi.stubEnv('MAIL_FROM', 'tool@example.test');
  try {
    expect(mailConfig().requireTLS).toBe(true);
    vi.stubEnv('SMTP_PASSWORD', ''); expect(() => mailConfig()).toThrow('credentials');
    vi.stubEnv('SMTP_PORT', 'not-a-port'); expect(() => mailConfig()).toThrow('SMTP_PORT');
  } finally { vi.unstubAllEnvs(); }
});
test('migrate validates only its own environment and web refuses missing configuration', () => {
  vi.stubEnv('MIGRATION_DATABASE_URL', 'postgresql://tool_owner@127.0.0.1/tool_test');
  vi.stubEnv('DATABASE_URL', '');
  try { expect(() => validateRuntime('migrate')).not.toThrow(); expect(() => validateRuntime('web')).toThrow('DATABASE_URL'); }
  finally { vi.unstubAllEnvs(); }
});

test('sign-in uses the shared sender and retains its SMTP secret-file configuration', async () => {
  const dir = mkdtempSync(join(tmpdir(), 'sign-in-mail-'));
  const file = join(dir, 'smtp');
  writeFileSync(file, 'synthetic-smtp-password\n');
  vi.stubEnv('SMTP_HOST', 'smtp.example.test'); vi.stubEnv('SMTP_PORT', '465');
  vi.stubEnv('SMTP_FROM', 'sign-in@example.test'); vi.stubEnv('SMTP_USER', 'fixture-user');
  vi.stubEnv('SMTP_PASSWORD_FILE', file);
  vi.stubEnv('MAIL_FROM', 'ordinary@example.test'); vi.stubEnv('SMTP_PASSWORD', 'other-fixture');
  const send = vi.spyOn(sharedMail, 'sendMail').mockResolvedValue(undefined);
  try {
    await sendSignInLink('invited@example.test', 'https://tool.example.test/verify');
    expect(send).toHaveBeenCalledExactlyOnceWith({ to: 'invited@example.test', subject: 'Your sign-in link',
      text: 'Use this link to sign in. It expires in ten minutes and works once.\n\nhttps://tool.example.test/verify' },
    { from: 'sign-in@example.test', host: 'smtp.example.test', port: 465, secure: true, requireTLS: true,
      auth: { user: 'fixture-user', pass: 'synthetic-smtp-password' }, logger: false, debug: false });
    send.mockRejectedValue(new Error('synthetic private diagnostic'));
    await expect(sendSignInLink('invited@example.test', 'https://tool.example.test/verify')).rejects.toThrow('The sign-in email could not be sent');
  } finally { send.mockRestore(); vi.unstubAllEnvs(); rmSync(dir, { recursive: true }); }
});
