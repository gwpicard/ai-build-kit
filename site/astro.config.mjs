import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  site: 'https://gwpicard.github.io',
  base: '/ai-build-kit',
  redirects: { '/concepts/': '/ai-build-kit/records/' },
  integrations: [starlight({
    title: 'AI Build Kit',
    description: 'A guide to building and running tools with AI Build Kit.',
    components: {
      PageSidebar: './src/components/PageSidebar.astro',
      PageTitle: './src/components/PageTitle.astro',
      MobileTableOfContents: './src/components/MobileTableOfContents.astro',
    },
    customCss: ['@fontsource-variable/plus-jakarta-sans/wght.css', './src/styles/palette.css', './src/styles/site.css'],
    expressiveCode: {
      themes: ['gruvbox-dark-medium', 'gruvbox-light-soft'],
      styleOverrides: { borderColor: '#373228' },
    },
    head: [
      { tag: 'meta', attrs: { property: 'og:image', content: 'https://gwpicard.github.io/ai-build-kit/og.jpg' } },
      { tag: 'meta', attrs: { name: 'twitter:card', content: 'summary_large_image' } },
      { tag: 'meta', attrs: { name: 'twitter:image', content: 'https://gwpicard.github.io/ai-build-kit/og.jpg' } },
    ],
    sidebar: [
      { label: 'Get started', items: ['index', 'install'] },
      { label: 'Design and workflow', items: ['design', { slug: 'how-it-works', label: 'Workflow' }, 'working-together', 'records', 'recipes', 'live-data', 'maintaining-your-tool', 'what-it-checks', 'how-it-differs'] },
      { label: 'Reference', items: ['agents', 'sources', 'releases'] },
    ],
    social: [{
      icon: 'github',
      label: 'GitHub',
      href: 'https://github.com/gwpicard/ai-build-kit',
    }],
  })],
});
