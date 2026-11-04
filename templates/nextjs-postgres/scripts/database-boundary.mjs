import path from 'node:path';
import { fileURLToPath } from 'node:url';

const helperPath = fileURLToPath(new URL('../src/lib/db/with-database.ts', import.meta.url));
const projectRoot = fileURLToPath(new URL('../', import.meta.url));

const databaseBoundary = {
  meta: { type: 'problem', schema: [], messages: {
    connection: 'Open app database connections only in src/lib/db/with-database.ts.',
    identity: 'Test support and database administration scripts cannot be imported by app code.',
    dynamic: 'Use a literal module path so the database boundary can check it.',
    loader: 'Alternative module loaders are available only in the database helper.',
  } },
  create(context) {
    const file = context.filename.replaceAll('\\', '/');
    const helper = path.resolve(context.filename) === helperPath;
    function check(node, source, specifiers) {
      if (typeof source !== 'string') {
        context.report({ node, messageId: 'dynamic' });
        return;
      }
      const resolved = source.startsWith('file:') ? fileURLToPath(source)
        : source.startsWith('@/') ? path.resolve(projectRoot, 'src', source.slice(2))
        : path.resolve(path.dirname(file), source);
      const relative = path.relative(projectRoot, resolved).replaceAll('\\', '/');
      if (/^(?:tests|scripts)(?:\/|$)/.test(relative) || /^(?:tests|scripts)(?:\/|$)/.test(source)) {
        context.report({ node, messageId: 'identity' });
      }
      if (helper) return;
      if (source === 'module' || source === 'node:module') {
        context.report({ node, messageId: 'loader' });
      }
      const driver = '(?:pg(?:-pool|-native)?|postgres)(?:/|$)';
      const rawDriver = new RegExp(`^${driver}`).test(source)
        || new RegExp(`(?:^|/)node_modules/${driver}`).test(resolved.replaceAll('\\', '/'));
      const rawModule = /(?:^|\/)db\/(?:pool|client|raw)(?:\.|\/|$)/.test(source);
      const rawBuilder = source === 'kysely' && node.importKind !== 'type'
        && node.exportKind !== 'type' && (!specifiers || specifiers.some((item) =>
        item.importKind !== 'type' && item.type !== 'ImportSpecifier'
        || item.importKind !== 'type' && item.imported?.name !== 'sql'));
      if (rawDriver || rawModule || rawBuilder) context.report({ node, messageId: 'connection' });
    }
    function checkLoaderProperty(node, key, computed) {
      const name = computed ? key.value : key.name ?? key.value;
      if (!helper && ['require', 'createRequire', 'mainModule'].includes(name)) {
        context.report({ node, messageId: 'loader' });
      }
    }
    return {
      MemberExpression(node) { checkLoaderProperty(node, node.property, node.computed); },
      Property(node) { checkLoaderProperty(node, node.key, node.computed); },
      Identifier(node) {
        if (helper || node.name !== 'require') return;
        const parent = node.parent;
        if (parent.type === 'CallExpression' && parent.callee === node) return;
        if (parent.type === 'MemberExpression' && parent.property === node && !parent.computed) return;
        if (parent.type === 'Property' && parent.key === node && !parent.computed) return;
        context.report({ node, messageId: 'loader' });
      },
      ImportDeclaration(node) {
        check(node, node.source.value, node.specifiers);
      },
      ExportNamedDeclaration(node) {
        if (node.source) check(node, node.source.value);
      },
      ExportAllDeclaration(node) { check(node, node.source.value); },
      ImportExpression(node) { check(node, node.source.value); },
      TSImportEqualsDeclaration(node) {
        if (node.moduleReference.type === 'TSExternalModuleReference') {
          check(node, node.moduleReference.expression.value);
        }
      },
      CallExpression(node) {
        if (node.callee.name === 'require' || node.callee.property?.name === 'require') {
          check(node, node.arguments[0]?.value);
        }
      },
    };
  },
};

export default databaseBoundary;
