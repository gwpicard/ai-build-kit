import { build } from 'esbuild';

await build({
  entryPoints: { worker: 'src/lib/jobs/worker.ts', config: 'src/lib/config.ts' },
  outdir: 'dist', outExtension: { '.js': '.mjs' },
  bundle: true, platform: 'node', target: 'node22', format: 'esm', packages: 'external',
  plugins: [{ name: 'server-only', setup(builder) {
    builder.onResolve({ filter: /^server-only$/ }, () => ({ path: 'server-only', namespace: 'marker' }));
    builder.onLoad({ filter: /.*/, namespace: 'marker' }, () => ({ contents: '' }));
  } }],
});
