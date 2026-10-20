import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  site: 'https://gwpicard.github.io',
  base: '/ai-build-kit',
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
      { label: 'Start here', items: ['index', 'how-it-differs', 'how-it-works', 'worked-example', 'install'] },
      { label: 'Understand', items: ['what-it-checks', 'concepts', 'agents'] },
      { label: 'Behind the kit', items: ['design', 'sources', 'releases'] },
    ],
    social: [{
      icon: 'github',
      label: 'GitHub',
      href: 'https://github.com/gwpicard/ai-build-kit',
    }],
  })],
});
