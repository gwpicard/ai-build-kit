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
    customCss: ['./src/styles/site.css'],
    sidebar: [
      { label: 'Get started', items: ['index', 'worked-example', 'install'] },
      { label: 'How it is designed', items: ['design', 'how-it-works', 'records', 'what-it-checks', 'how-it-differs'] },
      { label: 'Reference', items: ['agents', 'sources', 'releases'] },
    ],
    social: [{
      icon: 'github',
      label: 'GitHub',
      href: 'https://github.com/gwpicard/ai-build-kit',
    }],
  })],
});
