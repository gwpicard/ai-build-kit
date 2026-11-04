import { validateRuntime } from '../dist/config.mjs';

// Framework diagnostics can contain request data. Keep only their severity.
for (const level of ['log', 'info', 'warn', 'error', 'debug']) {
  console[level] = (message) => {
    let event = 'web.diagnostic';
    try {
      const parsed = JSON.parse(message);
      if (typeof parsed.event === 'string' && /^[a-z_]+\.[a-z_]+$/.test(parsed.event)) event = parsed.event;
    } catch { /* Framework text is deliberately omitted. */ }
    process.stdout.write(JSON.stringify({ event, level }) + '\n');
  };
}
try { validateRuntime('web'); }
catch { process.stdout.write('{"event":"configuration.invalid","role":"web"}\n'); process.exit(1); }
