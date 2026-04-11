import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  site: 'https://validationforge.dev',
  integrations: [
    starlight({
      title: 'ValidationForge',
      description: 'Ship verified code, not just compiled code. End-to-end validation for AI-assisted development.',
      social: {
        github: 'https://github.com/validationforge/validationforge',
      },
      sidebar: [
        {
          label: 'Getting Started',
          items: [
            { label: 'Installation', slug: 'installation' },
            { label: 'Quickstart', slug: 'quickstart' },
          ],
        },
        {
          label: 'Reference',
          items: [
            { label: 'Commands', slug: 'commands' },
            { label: 'Pipeline', slug: 'pipeline' },
          ],
        },
        {
          label: 'Guides',
          items: [
            { label: 'Comparison', slug: 'comparison' },
          ],
        },
      ],
    }),
  ],
});
