// Starlight content collections wiring.
//
// Registers the `docs` collection required by `@astrojs/starlight` so that all
// MDX/Markdown files under `src/content/docs/` are picked up with the Starlight
// frontmatter schema (title, description, hero, template, etc.).
//
// Later phases can extend the schema with project-specific fields via the
// `extend` option on `docsSchema({ extend: z.object({ … }) })`.
import { defineCollection } from 'astro:content';
import { docsLoader } from '@astrojs/starlight/loaders';
import { docsSchema } from '@astrojs/starlight/schema';

export const collections = {
  docs: defineCollection({
    loader: docsLoader(),
    schema: docsSchema(),
  }),
};
