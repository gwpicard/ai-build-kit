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
