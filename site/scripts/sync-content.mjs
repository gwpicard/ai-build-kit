import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const siteRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const repoRoot = path.resolve(siteRoot, '..');
const generatedDir = path.join(siteRoot, 'src/content/docs/generated');
const githubBase = 'https://github.com/gwpicard/ai-build-kit/blob/stable/';
const releasesUrl = 'https://github.com/gwpicard/ai-build-kit/releases';

await mkdir(generatedDir, { recursive: true });
await mkdir(path.join(siteRoot, 'public'), { recursive: true });

async function source(relativePath) {
  return readFile(path.join(repoRoot, relativePath), 'utf8');
}

function githubLinks(markdown, sourcePath) {
  return markdown.replace(/\]\(([^)]+)\)/g, (whole, target) => {
    if (/^(?:https?:|mailto:|#|\/)/i.test(target)) return whole;
    const [file, ...fragment] = target.split('#');
    const resolved = path.posix.normalize(path.posix.join(path.posix.dirname(sourcePath), file));
    if (resolved.startsWith('../')) return whole;
    const suffix = fragment.length ? `#${fragment.join('#')}` : '';
    return `](${githubBase}${resolved}${suffix})`;
  });
}

function section(markdown, heading, nextHeading) {
  const start = markdown.indexOf(heading);
  if (start < 0) return '';
  const end = nextHeading ? markdown.indexOf(nextHeading, start + heading.length) : -1;
  return markdown.slice(start + heading.length, end < 0 ? undefined : end).trim();
}

const readme = await source('README.md');
const compatibility = await source('docs/COMPATIBILITY.md');
const philosophy = await source('docs/PHILOSOPHY.md');
const sources = await source('docs/SOURCES.md');
const llms = await source('llms.txt');

const installPart = section(readme, '## Quick start', '## A sample session');
await writeFile(path.join(generatedDir, 'readme-install.md'), `---\ntitle: README installation route\ndraft: false\n---\n\n${githubLinks(installPart, 'README.md')}\n`);
await writeFile(path.join(generatedDir, 'compatibility.md'), `---\ntitle: Compatibility\ndraft: false\n---\n\n${githubLinks(compatibility, 'docs/COMPATIBILITY.md')}\n`);
await writeFile(path.join(generatedDir, 'philosophy.md'), `---\ntitle: Design and approach\ndraft: false\n---\n\n${githubLinks(philosophy.replace(/^# .*\n+/, ''), 'docs/PHILOSOPHY.md')}\n`);
const designIntro = 'AI Build Kit aims to make the work understandable without asking the person to read code. It keeps decisions with the person and uses checks where a machine can make a promise hold.';
const proof = '## How the kit is proven\n\nShell checks test boundaries and scripts. Replays run conversations and are graded on what the agent did. The mutation run breaks one promise at a time and reports which checks noticed. Release verification rebuilds a published version and compares it with the reviewed archive.';
const philosophyBody = githubLinks(philosophy.replace(/^# .*\n+/, ''), 'docs/PHILOSOPHY.md');
await writeFile(path.join(generatedDir, 'design.md'), `---\ntitle: Design and approach\nslug: design\ndraft: false\n---\n\n${designIntro}\n\n## The kit's philosophy\n\n${philosophyBody}\n\n${proof}\n`);

const sourceRows = sources.split('\n').filter((line) => line.startsWith('|'));
const tableStart = sourceRows.findIndex((line) => line.includes('| Source |'));
const sourceTable = tableStart < 0 ? '' : sourceRows.slice(tableStart).join('\n');
const sourcesIntro = "The kit's ideas come from open work on agent-led development, software testing, product design and reliable operations. The table below records each source and its contribution.";
await writeFile(path.join(generatedDir, 'sources.md'), `---\ntitle: Sources\nslug: sources\ndraft: false\n---\n\n${sourcesIntro}\n\n${sourceTable}\n`);

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
await writeFile(path.join(generatedDir, 'releases.md'), `---\ntitle: Releases\nslug: releases\ndraft: false\n---\n\nThe list below is read from GitHub when the site is built. A read failure does not stop the site build.\n\n[Open all releases on GitHub](${releasesUrl}).\n\n${releasesMarkdown}\n`);
