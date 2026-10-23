#!/usr/bin/env node
// screen-result.mjs: read the new screen with the project's TypeScript parser.
import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";

const [project, policy] = process.argv.slice(2);
const require = createRequire(path.join(project, "package.json"));
const ts = require("typescript");
const root = path.join(project, "src");
const ui = path.join(root, "components", "ui") + path.sep;
const seen = new Set();
const faults = [];
let hasForm = false;
let usesUi = false;

// Read the colour patterns from the harness's starter. The older kit in a
// comparison may have no colour rules, so its lint alone cannot settle this.
const patterns = [];
const policyAst = ts.createSourceFile(policy, fs.readFileSync(policy, "utf8"), ts.ScriptTarget.Latest);
function colourPatterns(node) {
  if (ts.isPropertyAssignment(node) && node.name.getText(policyAst) === "pattern"
      && ts.isStringLiteral(node.initializer)) patterns.push(new RegExp(node.initializer.text));
  ts.forEachChild(node, colourPatterns);
}
colourPatterns(policyAst);
if (!patterns.length) throw new Error("the harness starter has no colour policy to read");

const configPath = path.join(project, "tsconfig.json");
const config = ts.readConfigFile(configPath, ts.sys.readFile);
if (config.error) throw new Error("the result has no readable tsconfig.json");
const options = ts.parseJsonConfigFileContent(config.config, ts.sys, project).options;

function scan(file) {
  file = path.resolve(file);
  if (seen.has(file) || file.startsWith(ui)) return;
  seen.add(file);
  const text = fs.readFileSync(file, "utf8");
  const ast = ts.createSourceFile(file, text, ts.ScriptTarget.Latest, true, ts.ScriptKind.TSX);
  const bindings = new Set();
  for (const statement of ast.statements) {
    if (!(ts.isImportDeclaration(statement) || ts.isExportDeclaration(statement))
        || !statement.moduleSpecifier || !ts.isStringLiteral(statement.moduleSpecifier)) continue;
    const target = ts.resolveModuleName(statement.moduleSpecifier.text, file, options, ts.sys).resolvedModule;
    if (!target) continue;
    const resolved = path.resolve(target.resolvedFileName);
    if (resolved.startsWith(ui)) {
      const clause = statement.importClause;
      if (clause && !clause.isTypeOnly) {
        if (clause.name) bindings.add(clause.name.text);
        const named = clause.namedBindings;
        if (named && ts.isNamespaceImport(named)) bindings.add(named.name.text);
        else if (named) for (const element of named.elements) {
          if (!element.isTypeOnly) bindings.add(element.name.text);
        }
      }
    } else if (resolved.startsWith(root + path.sep) && /\.[jt]sx?$/.test(resolved)) scan(resolved);
  }
  function visit(node) {
    if (ts.isJsxOpeningElement(node) || ts.isJsxSelfClosingElement(node)) {
      const tag = node.tagName.getText(ast);
      if (tag === "form") hasForm = true;
      if (/^(button|input|select|textarea)$/.test(tag)) faults.push(`${path.relative(project, file)}: raw ${tag}`);
      if (bindings.has(tag.split(".")[0])) usesUi = true;
    }
    if (ts.isStringLiteralLike(node) || ts.isTemplateHead(node) || ts.isTemplateMiddle(node)
        || ts.isTemplateTail(node)) {
      for (const token of node.text.split(/\s+/)) {
        if (patterns.some((pattern) => pattern.test(token))) {
          faults.push(`${path.relative(project, file)}: literal colour ${token}`);
        }
      }
    }
    if (ts.isJsxAttribute(node) && node.name.getText(ast) === "style") {
      function style(part) {
        if ((ts.isPropertyAssignment(part) || ts.isShorthandPropertyAssignment(part))
            && /^(color|background.*|border.*|outline.*|fill|stroke|caretColor|accentColor|boxShadow|textShadow|textDecorationColor|columnRuleColor|--.*)$/.test(
              part.name.getText(ast).replace(/^["']|["']$/g, ""))) {
          faults.push(`${path.relative(project, file)}: inline colour`);
        }
        ts.forEachChild(part, style);
      }
      ts.forEachChild(node, style);
    }
    ts.forEachChild(node, visit);
  }
  visit(ast);
}
scan(path.join(root, "app", "request-leave", "page.tsx"));
console.log(JSON.stringify({
  "screen-components": {
    verdict: hasForm && usesUi ? "hit" : "miss",
    note: hasForm && usesUi ? "the new form renders components from src/components/ui/"
      : "the new page has no form rendering a component from src/components/ui/",
  },
  "screen-controls-and-colours": {
    verdict: faults.length ? "miss" : "hit",
    note: faults.length ? faults.slice(0, 5).join("; ")
      : "the page and its local imports contain no raw controls or literal colours",
  },
}));
