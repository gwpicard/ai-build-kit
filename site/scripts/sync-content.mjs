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

const grades = section(compatibility, '## How much has been proved on each agent', '### Moving up a grade');
const gradeRows = grades.split('\n').filter((line) => line.startsWith('|'));
const gradeTable = gradeRows.join('\n');
function tocFrontmatter(markdown) {
  const headings = markdown.match(/^#{1,6}\s/gm) ?? [];
  return headings.length < 3 ? 'tableOfContents: false\n' : '';
}
const agentsIntro = 'The table shows how much evidence exists for each coding agent. A grade describes the evidence for the agent, not whether a tool built with the kit is safe.';
const agentsLimits = `

Tested means recorded conversations have run on the agent. Expected to work means it reads the same skill files as a tested agent, but nobody has recorded a run. Experimental means the needed files are included, but their use has not been confirmed.

## Known limits

- Claude Code: recorded conversations run without a person present. They do not show what happens in a session with a person.
- Codex: nobody has recorded a full run. Start a command by naming it; the kit has no Codex command files.
- Cursor: nobody has recorded a run. Its command and background skill loading have not been confirmed.
- Gemini CLI: nobody has recorded a run. Its command and background skill loading have not been confirmed. Unless Gemini is set up to hide tool results, a secret printed by a tool reaches the agent.
- GitHub Copilot: nobody has recorded a run. The agent's use of the setup instructions has not been confirmed.
- Other agents: each agent needs its own evidence. The kit has not recorded a run on them.

[Read the full agent support notes](https://github.com/gwpicard/ai-build-kit/blob/stable/docs/COMPATIBILITY.md).
`;
const agentsBody = `${agentsIntro}\n\n${gradeTable}\n${agentsLimits}`;
await writeFile(path.join(generatedDir, 'agents.md'), `---\ntitle: Supported agents\nslug: agents\ndraft: false\n${tocFrontmatter(agentsBody)}---\n\n${agentsBody}`);

const themesStart = sources.indexOf('\n## ');
const sourceThemes = themesStart < 0 ? '' : sources.slice(themesStart).trim();
const sourcesIntro = sources.slice(0, themesStart < 0 ? undefined : themesStart).replace(/^# .*\n+/, '').trim();
const sourcesBody = `${sourcesIntro}\n\n${sourceThemes}`;
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
    ? `| Version | Published | Notes |\n|---|---|---|\n${entries.map((release) => `| [${release.tag_name}](${release.html_url}) | ${release.published_at?.slice(0, 10) ?? 'Date unavailable'} | [Read notes](${release.html_url}) |`).join('\n')}`
    : 'No published releases were returned by GitHub.';
} catch {
  releasesMarkdown = `GitHub could not provide the release list during this build. [Open the releases page](${releasesUrl}).`;
}
const releasesBody = `The table lists published versions and their notes.\n\n${releasesMarkdown}`;
await writeFile(path.join(generatedDir, 'releases.md'), `---\ntitle: Releases\nslug: releases\ndraft: false\n${tocFrontmatter(releasesBody)}---\n\n${releasesBody}\n`);
