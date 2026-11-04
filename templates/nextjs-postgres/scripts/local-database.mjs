export function localDatabaseUrls() {
  if (process.env.NODE_ENV === "production") throw new Error("Local database tools refuse production");
  const urls = ["ADMIN_DATABASE_URL", "MIGRATION_DATABASE_URL", "DATABASE_URL"].map((name) => {
    if (!process.env[name]) throw new Error(`${name} is required`);
    const url = new URL(process.env[name]);
    if (!['127.0.0.1', 'localhost', '[::1]'].includes(url.hostname)
      || !['/tool_test', '/tool_dev'].includes(url.pathname)
      || !['postgres:', 'postgresql:'].includes(url.protocol)) {
      throw new Error("Local database tools require a loopback tool_test or tool_dev database");
    }
    return url;
  });
  const [admin, owner, app] = urls;
  if (urls.some((url) => url.host !== admin.host || url.pathname !== admin.pathname)
    || owner.username !== 'tool_owner' || app.username !== 'tool_app') {
    throw new Error("Local database URLs must name the same database and the separate owner and app roles");
  }
  return { admin: admin.href, owner: owner.href, app: app.href };
}

// Driver errors can contain connection details. Scripts print only a status code.
export function reportFailure(error) {
  console.error(`Database check failed (${error.code ?? 'configuration or assertion error'})`);
  process.exitCode = 1;
}
