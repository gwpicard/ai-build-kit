// Run the copied starter's browser configuration while another server holds 3000.
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import http from 'node:http';

const listen = (server, port) => new Promise((resolve, reject) => {
  server.once('error', reject);
  server.listen(port, '127.0.0.1', resolve);
});
const close = server => new Promise(resolve => server.close(resolve));
const occupied = http.createServer((request, response) => {
  response.end('Another programme owns this port.');
});
try {
  await listen(occupied, 3000);
} catch (error) {
  if (error.code !== 'EADDRINUSE') throw error;
  console.log('Port 3000 already belongs to another programme; leaving it running.');
}

const spec = 'e2e/browser-port.spec.ts';
fs.writeFileSync(spec, `import { expect, test } from '@playwright/test';
test('browser reaches the starter on its selected port', async ({ page, baseURL }) => {
  const port = new URL(baseURL!).port;
  expect(port).not.toBe('3000');
  if (process.env.EXPECTED_BROWSER_PORT) expect(port).toBe(process.env.EXPECTED_BROWSER_PORT);
  await page.goto('/login');
  expect(new URL(page.url()).port).toBe(port);
  await expect(page.getByLabel('Email address')).toBeVisible();
});
`);

async function run(port, list = false) {
  const vars = { ...process.env };
  delete vars.PORT;
  delete vars.EXPECTED_BROWSER_PORT;
  if (port !== undefined) vars.PORT = vars.EXPECTED_BROWSER_PORT = String(port);
  const child = spawn('npx', ['--no-install', 'playwright', 'test', spec,
    '--config', 'playwright.interface.config.ts', ...(list ? ['--list'] : [])],
  { env: vars, stdio: ['ignore', 'pipe', 'pipe'] });
  let output = '';
  child.stdout.on('data', data => { output += data; });
  child.stderr.on('data', data => { output += data; });
  const code = await new Promise((resolve, reject) => {
    child.once('error', reject);
    child.once('exit', resolve);
  });
  return { code, output };
}

try {
  let result = await run();
  assert.equal(result.code, 0, result.output);
  console.log('ok: the browser passes with port 3000 occupied');
  const free = http.createServer();
  await listen(free, 0);
  const port = free.address().port;
  await close(free);
  result = await run(port);
  assert.equal(result.code, 0, result.output);
  console.log('ok: the browser honours PORT');
  for (const invalid of ['', '0', '65536', 'not-a-port', '4000; exit 0']) {
    result = await run(invalid, true);
    assert.notEqual(result.code, 0, 'an invalid PORT was accepted');
    assert.match(result.output, /PORT must be a whole number/);
  }
  console.log('ok: invalid ports are rejected before starting a server');
  result = await run(3000);
  assert.notEqual(result.code, 0, 'the browser reused another programme');
  assert.match(result.output, /already used|EADDRINUSE/);
  console.log('ok: an occupied explicit port is refused without reusing its server');
} finally {
  fs.unlinkSync(spec);
  if (occupied.listening) await close(occupied);
}
