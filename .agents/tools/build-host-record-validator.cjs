// Compile the pinned schema into a reader that needs no project dependencies.
const { readFileSync, writeFileSync } = require('node:fs');
const { resolve } = require('node:path');
const { createRequire } = require('node:module');
const root = resolve(__dirname, '../..');
const dependencies = createRequire(resolve(process.argv[2] ?? `${root}/templates/nextjs-postgres`, 'package.json'));
const Ajv2020 = dependencies('ajv/dist/2020.js');
const standalone = dependencies('ajv/dist/standalone').default;
const { _ } = dependencies('ajv/dist/compile/codegen');
const { _Code } = dependencies('ajv/dist/compile/codegen/code');
const { buildSync } = dependencies('esbuild');
const { timestamp } = require('../skills/merge/scripts/host-record.cjs');
const folder = resolve(root, '.agents/skills/merge');
const schema = JSON.parse(readFileSync(`${folder}/contracts/ai-host-kit/host-record.schema.json`, 'utf8'));
const ajv = new Ajv2020({ strict: false, strictNumbers: true, allErrors: true, code: { source: true, formats: _`{ "date-time": ${new _Code(timestamp.toString())} }` } });
ajv.addFormat('date-time', timestamp);
const validate = ajv.compile(schema);
const output = buildSync({
  absWorkingDir: resolve(dependencies.resolve('ajv/package.json'), '..'),
  stdin: { contents: standalone(ajv, validate), resolveDir: resolve(dependencies.resolve('ajv/package.json'), '..') },
  bundle: true, platform: 'node', format: 'cjs', write: false, legalComments: 'none',
  banner: { js: '/* Rebuild with .agents/tools/build-host-record-validator.cjs.\n' + readFileSync(dependencies.resolve('ajv/LICENSE'), 'utf8') + '*/' },
}).outputFiles[0].text;
const destination = `${folder}/scripts/host-record-validator.cjs`;
if (process.argv[3] === '--check') {
  if (readFileSync(destination, 'utf8') !== output) throw new Error('The bundled host-record validator differs from its schema and build script');
  console.log('Bundled host-record validator agrees with its schema and build script');
} else writeFileSync(destination, output);
