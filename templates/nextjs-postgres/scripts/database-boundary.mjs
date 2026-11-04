import path from 'node:path';
import { fileURLToPath } from 'node:url';

const helperPath = fileURLToPath(new URL('../src/lib/db/with-database.ts', import.meta.url));

const databaseBoundary = {
  meta: { type: 'problem', schema: [], messages: {
    connection: 'Open app database connections only in src/lib/db/with-database.ts.',
    identity: 'Test support and database administration scripts cannot be imported by app code.',
    dynamic: 'Use a literal module path so the database boundary can check it.',
  } },
  create(context) {
    const file = context.filename.replaceAll('\\', '/');
    const helper = path.resolve(context.filename) === helperPath;
    function check(node, source, specifiers) {
      if (typeof source !== 'string') {
        context.report({ node, messageId: 'dynamic' });
        return;
      }
      const resolved = path.resolve(path.dirname(file), source).replaceAll('\\', '/');
      if (/(?:^|\/)(?:tests|scripts)(?:\/|$)/.test(source) || /\/(?:tests|scripts)\//.test(resolved)) {
        context.report({ node, messageId: 'identity' });
      }
      if (helper) return;
      const rawDriver = /^(?:pg(?:-pool|-native)?(?:\/|$)|postgres(?:\/|$))/.test(source);
      const rawModule = /(?:^|\/)db\/(?:pool|client|raw)(?:\.|\/|$)/.test(source);
      const rawBuilder = source === 'kysely' && node.importKind !== 'type'
        && node.exportKind !== 'type' && (!specifiers || specifiers.some((item) =>
        item.importKind !== 'type' && item.type !== 'ImportSpecifier'
        || item.importKind !== 'type' && item.imported?.name !== 'sql'));
      if (rawDriver || rawModule || rawBuilder) context.report({ node, messageId: 'connection' });
    }
    return {
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
