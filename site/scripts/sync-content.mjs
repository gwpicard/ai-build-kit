import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const siteRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const repoRoot = path.resolve(siteRoot, '..');
const generatedDir = path.join(siteRoot, 'src/content/docs/generated');
const releasesUrl = 'https://github.com/gwpicard/ai-build-kit/releases';

await mkdir(generatedDir, { recursive: true });
await mkdir(path.join(siteRoot, 'public'), { recursive: true });

async function source(relativePath) {
  return readFile(path.join(repoRoot, relativePath), 'utf8');
}

function section(markdown, heading, nextHeading) {
  const start = markdown.indexOf(heading);
  if (start < 0) return '';
  const end = nextHeading ? markdown.indexOf(nextHeading, start + heading.length) : -1;
  return markdown.slice(start + heading.length, end < 0 ? undefined : end).trim();
}

const compatibility = await source('docs/COMPATIBILITY.md');
const sources = await source('docs/SOURCES.md');
const llms = await source('llms.txt');
const promises = await source('docs/PROMISES.md');
const recipes = await source('docs/RECIPES.md');

const grades = section(compatibility, '## How much has been proved on each agent', '### Moving up a grade');
const gradeRows = grades.split('\n').filter((line) => line.startsWith('|'));
const gradeTable = gradeRows.join('\n');
const gradeContext = grades.slice(0, grades.indexOf('\n|')).trim();
function tocFrontmatter(markdown) {
  const headings = markdown.match(/^#{1,6}\s/gm) ?? [];
  return headings.length < 3 ? 'tableOfContents: false\n' : '';
}
const agentsIntro = 'The table shows each coding agent’s support grade and the evidence behind it. A grade reflects testing of the kit on that agent, not the safety of tools built with it.';
const knownLimits = section(compatibility, '## Known limits', '## GitHub access')
  .replaceAll('](#github-access-in-codex)', '](https://github.com/gwpicard/ai-build-kit/blob/stable/docs/COMPATIBILITY.md#github-access-in-codex)');
const agentsBody = `${agentsIntro}\n\n${gradeContext}\n\n${gradeTable}\n\n${knownLimits}\n\n[Read the full agent support notes](https://github.com/gwpicard/ai-build-kit/blob/stable/docs/COMPATIBILITY.md).`;
await writeFile(path.join(generatedDir, 'agents.md'), `---\ntitle: Supported agents\nslug: agents\ndraft: false\n${tocFrontmatter(agentsBody)}---\n\n${agentsBody}`);

function linkSourcePaths(markdown) {
  return markdown.replace(/`(\.agents\/[^`]+)`/g, (_, sourcePath) => `[\`${sourcePath}\`](https://github.com/gwpicard/ai-build-kit/blob/stable/${sourcePath})`);
}
const linkedPromises = linkSourcePaths(promises.replace(/^# .*\n+/, '').trim());
const recipeIntro = 'A hosting recipe pairs a software stack with a hosting service. It defines how to preview and publish changes, back up and restore data, and roll back the application. Both recipes use TypeScript, Next.js 16 and Supabase, the stack the kit’s checks are written for. They suit internal dashboards, approval workflows, trackers and portals. Both have run in real deployments, but not every procedure has been tested.';
const recipeMenu = section(recipes, '## Site menu', '## A recipe is a folder');
const recipeDetails = await source('site/data/recipes-explanation.md');
const recipesBody = `${recipeIntro}\n\n## The recipes today\n\n${recipeMenu}\n\n${recipeDetails.trim()}`;
await writeFile(path.join(generatedDir, 'recipes.md'), `---\ntitle: Hosting recipes\nslug: recipes\ndescription: Choose a hosting recipe, understand its checks, and see what remains untested.\ndraft: false\n${tocFrontmatter(recipesBody)}---\n\n${recipesBody}\n`);

const checksIntro = 'These rules apply across projects. The table names each safeguard, its enforcement or test, and known limits.';
const checksDetails = await source('site/data/what-it-checks-explanation.md');
const checksIntroSection = await source('site/data/what-it-checks-intro.md');
const checksBody = `${checksIntro}\n\n${checksIntroSection.trim()}\n\n${linkedPromises}\n\n${checksDetails.trim()}`;
await writeFile(path.join(generatedDir, 'what-it-checks.md'), `---\ntitle: Rules and checks\nslug: what-it-checks\ndescription: Rules that apply in every project and how the kit tests them.\ndraft: false\n${tocFrontmatter(checksBody)}---\n\n${checksBody}\n`);

const themesStart = sources.indexOf('\n## ');
const sourceThemes = themesStart < 0 ? '' : sources.slice(themesStart).trim();
const sourcesIntro = sources.slice(0, themesStart < 0 ? undefined : themesStart).replace(/^# .*\n+/, '').trim();
function wrapTables(markdown) {
  const lines = markdown.split('\n');
  const output = [];
  for (let index = 0; index < lines.length;) {
    if (lines[index].startsWith('|')) {
      const table = [];
      while (index < lines.length && lines[index].startsWith('|')) table.push(lines[index++]);
      output.push('<div class="comparison-table-wrap" role="region" aria-label="Sources and contributions" tabindex="0">', '', ...table, '', '</div>');
    } else output.push(lines[index++]);
  }
  return output.join('\n');
}
const sourcesBody = `${sourcesIntro}\n\n${wrapTables(sourceThemes)}`;
await writeFile(path.join(generatedDir, 'sources.md'), `---\ntitle: Sources\nslug: sources\ndraft: false\n${tocFrontmatter(sourcesBody)}---\n\n${sourcesBody}\n`);

await writeFile(path.join(siteRoot, 'public/llms.txt'), llms);

let releasesMarkdown;
try {
  const response = await fetch('https://api.github.com/repos/gwpicard/ai-build-kit/releases?per_page=100', {
    headers: { accept: 'application/vnd.github+json' },
    signal: AbortSignal.timeout(8000),
  });
  if (!response.ok) throw new Error(`GitHub API returned ${response.status}`);
  const releases = await response.json();
  const entries = releases.filter((release) => !release.draft && !release.prerelease);
  releasesMarkdown = entries.length
    ? `| Version | Published | Notes |\n|---|---|---|\n${entries.map((release) => `| [${release.tag_name}](${release.html_url}) | ${release.published_at?.slice(0, 10) ?? 'Date unavailable'} | [Read release notes](${release.html_url}) |`).join('\n')}`
    : 'GitHub returned no published releases.';
} catch {
  releasesMarkdown = `The release list could not be retrieved during this site build. [Open the releases page](${releasesUrl}).`;
}
const releasesBody = `Published releases and release notes are listed below when available.\n\n${releasesMarkdown}`;
await writeFile(path.join(generatedDir, 'releases.md'), `---\ntitle: Releases\nslug: releases\ndraft: false\n${tocFrontmatter(releasesBody)}---\n\n${releasesBody}\n`);
