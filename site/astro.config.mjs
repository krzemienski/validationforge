// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import sitemap from '@astrojs/sitemap';
import mdx from '@astrojs/mdx';

// https://astro.build/config
export default defineConfig({
  // Site URL is used for canonical URLs, sitemap.xml, and OpenGraph meta tags.
  // Must match the production domain so SEO tags resolve correctly.
  site: 'https://validationforge.dev',

  integrations: [
    starlight({
      title: 'ValidationForge',
      description:
        "No-mock functional validation for Claude Code and OpenCode. Ship verified code, not 'it compiled' code.",
      social: [
        {
          icon: 'github',
          label: 'GitHub',
          href: 'https://github.com/krzemienski/validationforge',
        },
      ],
      // Placeholder sidebar. Groups are scaffolded empty here so later
      // phases can fill them in without having to rewrite the top-level
      // structure. Later phases may flip any group to
      // `autogenerate: { directory: '<name>' }` once the content dir
      // exists under src/content/docs/.
      sidebar: [
        {
          label: 'Getting Started',
          items: [],
        },
        {
          label: 'Commands',
          autogenerate: { directory: 'commands' },
        },
        {
          label: 'Skills',
          items: [],
        },
        {
          label: 'Configuration',
          items: [],
        },
        {
          label: 'Integrations',
          items: [],
        },
      ],
      head: [
        // Twitter card fallback — OpenGraph tags are emitted by Starlight
        // automatically from the site URL + page frontmatter.
        {
          tag: 'meta',
          attrs: { name: 'twitter:card', content: 'summary_large_image' },
        },
      ],
      lastUpdated: true,
    }),
    // @astrojs/sitemap auto-generates sitemap.xml from the site URL above.
    sitemap(),
    // MDX support for the Starlight content collection (enables JSX
    // components like <Tabs>, <CardGrid>, etc. in .mdx pages).
    mdx(),
  ],
});
