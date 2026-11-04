import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { schemaFor, validateRecord, renderMasterplan } from './handover.mjs';

export const questions = [
  { name: 'sign_in', question: 'How will people sign in?', choices: ['Company Microsoft', 'Company Google', 'Email link'], values: ['entra', 'google', 'email-link'] },
  { name: 'residency', question: 'Must the data stay in a particular region?', choices: ['United Kingdom', 'European Union', 'No region requirement'], values: ['uk', 'eu', 'any'] },
  { name: 'max_data_loss_hours', question: 'How much recent work could you afford to lose? Give the longest period in hours.' },
  { name: 'max_restore_hours', question: 'How long could you manage without the tool while it is restored? Give the longest period in hours.' },
];
export function found(root, answers) {
  const path = resolve(root, 'hosting/handover.json');
  if (!existsSync(path) || !existsSync(resolve(root, 'src/lib/config.ts'))) throw new Error('This path is only for the plain Postgres template');
  if (!['entra', 'google', 'email-link'].includes(answers.sign_in)) throw new Error('sign_in: choose a listed method');
  const handover = JSON.parse(readFileSync(path, 'utf8'));
  handover.sign_in = { staff: null, outsiders: 'email-link' };
  if (answers.sign_in !== 'email-link') {
    const test = answers.outside_refused_test;
    if (typeof test !== 'string' || !/^(?!.*\.\.)[a-zA-Z0-9_./-]+$/.test(test) || !existsSync(resolve(root, test))) throw new Error('sign_in: name the existing outside-account test before recording company sign-in');
    handover.sign_in = { staff: { provider: answers.sign_in, directory: answers.sign_in === 'entra' ? 'single-tenant' : 'workspace-domain', outside_refused_test: test }, outsiders: 'none' };
  }
  handover.residency = answers.residency;
  handover.recovery = { max_data_loss_hours: answers.max_data_loss_hours, max_restore_hours: answers.max_restore_hours };
  if (answers.owner !== undefined) handover.tool.owner = answers.owner;
  if (answers.name !== undefined) handover.tool.name = answers.name;
  validateRecord(handover, schemaFor(root));
  const masterplanPath = resolve(root, 'masterplan.md');
  const masterplan = renderMasterplan(readFileSync(masterplanPath, 'utf8'), handover);
  writeFileSync(path, JSON.stringify(handover, null, 2) + '\n');
  writeFileSync(masterplanPath, masterplan);
}
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    if (process.argv[2] === '--questions') console.log(JSON.stringify(questions, null, 2));
    else {
      if (process.argv[2] !== '--answers' || !process.argv[3]) throw new Error('Use --questions or --answers <local answer file> [project]');
      found(resolve(process.argv[4] ?? '.'), JSON.parse(readFileSync(process.argv[3], 'utf8')));
      console.log('Founding answers saved in the handover and hosting section');
    }
  } catch (error) { console.error(error instanceof SyntaxError ? 'handover: JSON could not be read' : error.message); process.exitCode = 1; }
}
