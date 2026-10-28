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
const agentsIntro = 'The table summarises the evidence for using AI Build Kit with each coding agent. A coding agent reads and changes project files. Its support grade reflects how the kit has been tested on that agent, not whether a tool built with it is safe.';
const agentsLimits = `

Tested means maintainers have run scripted test conversations on the agent and graded its behaviour. Expected to work means the agent reads the same skill files as a tested agent, but no graded replay has been recorded. Experimental means the required files are included, but their checks establish only that the files are well formed.

## Known limits

- Claude Code: the recorded test conversations run without a person present, so they do not demonstrate how the kit behaves in an interactive session. No test rate yet describes an installable release, and the plugin route cannot be replayed in those unattended sessions.
- Codex: no graded replay run is recorded. Start a command by naming it; the kit does not provide Codex command files. A secret printed by a tool reaches the agent. The merge script requires recorded approval, but the kit does not show Codex a confirmation box. The kit does not set up a deny list or remind you of a check-up when a session opens.
- Cursor: no behavioural test run has been recorded, and command and background-skill loading remain unconfirmed. A secret printed by built-in Bash, Read or Grep reaches the agent. The kit does not set up a deny list or remind you of a check-up when a session opens.
- Gemini CLI: no behavioural test run has been recorded, and command and background-skill loading remain unconfirmed. Unless Gemini is configured to hide tool results, any secret printed by a tool reaches the agent. The kit does not set up a deny list or remind you of a check-up when a session opens.
- GitHub Copilot: no behavioural test run has been recorded, and it remains unconfirmed whether the agent follows the setup instructions. The kit does not set up a deny list or remind you of a check-up when a session opens.
- Other agents: no behavioural test runs have been recorded. Support requires evidence from each agent.

[Read the full agent support notes](https://github.com/gwpicard/ai-build-kit/blob/stable/docs/COMPATIBILITY.md).
`;
const agentsBody = `${agentsIntro}\n\n${gradeTable}\n${agentsLimits}`;
await writeFile(path.join(generatedDir, 'agents.md'), `---\ntitle: Supported agents\nslug: agents\ndraft: false\n${tocFrontmatter(agentsBody)}---\n\n${agentsBody}`);

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
