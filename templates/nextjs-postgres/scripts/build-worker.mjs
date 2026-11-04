import { build } from 'esbuild';

await build({
  entryPoints: ['src/lib/jobs/worker.ts'], outfile: 'dist/worker.mjs',
  bundle: true, platform: 'node', target: 'node22', format: 'esm', packages: 'external',
  plugins: [{ name: 'server-only', setup(builder) {
    builder.onResolve({ filter: /^server-only$/ }, () => ({ path: 'server-only', namespace: 'marker' }));
    builder.onLoad({ filter: /.*/, namespace: 'marker' }, () => ({ contents: '' }));
  } }],
});
