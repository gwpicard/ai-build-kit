import path from "node:path";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("../", import.meta.url));
const facade = path.join(root, "src/lib/files/index.ts");
const adapters = ["s3.ts", "azure-blob.ts"].map((file) => path.join(root, "src/lib/files/adapters", file));

const storageBoundary = {
  meta: { type: "problem", schema: [], messages: {
    sdk: "Import storage SDKs only inside the storage adapters.",
    adapter: "Use the permission-checked file port in src/lib/files/index.ts.",
    dynamic: "Use a literal module path so the storage boundary can check it.",
  } },
  create(context) {
    const file = path.resolve(context.filename);
    function check(node, source) {
      if (typeof source !== "string") {
        context.report({ node, messageId: "dynamic" });
        return;
      }
      if (/^(?:@aws-sdk(?:\/|$)|@azure\/storage[^/]*(?:\/|$)|aws-sdk(?:\/|$))/.test(source)
        && !adapters.includes(file)) context.report({ node, messageId: "sdk" });
      const target = source.startsWith("@/") ? path.resolve(root, "src", source.slice(2))
        : path.resolve(path.dirname(file), source);
      if (target.startsWith(path.join(root, "src/lib/files/adapters") + path.sep)
        && file !== facade && !adapters.includes(file)) context.report({ node, messageId: "adapter" });
    }
    return {
      ImportDeclaration(node) { check(node, node.source.value); },
      ExportNamedDeclaration(node) { if (node.source) check(node, node.source.value); },
      ExportAllDeclaration(node) { check(node, node.source.value); },
      ImportExpression(node) { check(node, node.source.value); },
      TSImportEqualsDeclaration(node) {
        if (node.moduleReference.type === "TSExternalModuleReference") check(node, node.moduleReference.expression.value);
      },
      CallExpression(node) {
        if (node.callee.name === "require" || node.callee.property?.name === "require") check(node, node.arguments[0]?.value);
      },
    };
  },
};

export default storageBoundary;
