// Sanitise complete output before taking its tail, including split credentials.
export function redact(output, secrets = []) {
  const sensitive = /password|passwd|pwd|secret|token|key|credential|authorization|connection|database_url|dsn/i;
  function fields(value) {
    if (Array.isArray(value)) return value.map(fields);
    if (value && typeof value === 'object') return Object.fromEntries(Object.entries(value)
      .map(([key, entry]) => [key, sensitive.test(key) ? '[redacted]' : fields(entry)]));
    return value;
  }
  let text = String(output ?? '').split('\n').map(line => {
    try { return JSON.stringify(fields(JSON.parse(line))); } catch { return line; }
  }).join('\n');
  text = text
    .replace(/\x1b\[[0-?]*[ -/]*[@-~]/g, '')
    .replace(/\\\//g, '/')
    .replace(/-----BEGIN [^-]*PRIVATE KEY-----[\s\S]*?(?:-----END [^-]*PRIVATE KEY-----|$)/g, '[redacted]')
    .replace(/[a-z][a-z\d+.-]*:\/\/[^\s"'<>]+/gi, '[redacted]')
    .replace(/\b(?:host|hostaddr|dbname|user|user id|data source|server)\s*=[^\r\n]+/gi, '[redacted]')
    .replace(/\b(?:Bearer|Basic)\s+[^\s"',}]+/gi, '[redacted]')
    .replace(/(["']?[\w.-]*(?:password|passwd|pwd|secret|token|key|credential|authorization|connection(?:_?string|_?url)?|database_url|dsn)[\w.-]*["']?\s*[:=]\s*)(?:"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|[^\r\n,;}]+)/gi, '$1[redacted]')
    .replace(/\b(?:AKIA|ASIA)[A-Z0-9]{16}\b/g, '[redacted]')
    .replace(/\b(?:sk|pk|gh[pousr]|github_pat)[_-][\w-]{16,}\b/g, '[redacted]')
    .replace(/\beyJ[\w-]+\.[\w-]+\.[\w-]+\b/g, '[redacted]');
  for (const secret of [...new Set(secrets)].filter(Boolean).sort((a, b) => b.length - a.length)) {
    for (const value of new Set([secret, encodeURIComponent(secret), Buffer.from(secret).toString('base64')])) {
      text = text.split(value).join('[redacted]');
    }
  }
  return text;
}

export function tail(output, secrets) {
  const clean = redact(output, secrets).trim();
  return clean ? clean.split(/\r?\n/).slice(-40).join('\n') : '(no output captured)';
}

export function labelledDockerfile(source, run, scope) {
  const label = `LABEL ai-build-kit.run=${JSON.stringify(run)} ai-build-kit.scope=${JSON.stringify(scope)}`;
  return source.replace(/^(FROM .+)$/gm, `$1\n${label}`);
}
