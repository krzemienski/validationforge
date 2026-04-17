# ValidationForge Documentation Site

The source for [validationforge.dev](https://validationforge.dev). Built with
[Astro](https://astro.build) + [Starlight](https://starlight.astro.build).

This site is the public-facing home for ValidationForge documentation:
installation, the `/validate` pipeline, the command reference, the top skill
reference, configuration profiles, and integration guides. It is a static site
with zero JavaScript by default. Search is powered by
[Pagefind](https://pagefind.app), which is built into Starlight.

## Commands

All commands are run from inside this `site/` directory.

| Command           | Action                                               |
| :---------------- | :--------------------------------------------------- |
| `npm install`     | Install dependencies                                 |
| `npm run dev`     | Start local dev server at `http://localhost:4321/`   |
| `npm run build`   | Build the production site to `./dist/`               |
| `npm run preview` | Preview the production build locally                 |
| `npm run check`   | Run `astro check` (type-check MDX + frontmatter)     |
| `npm run astro …` | Run Astro CLI commands (e.g. `astro add`, `astro …`) |

## Project Structure

```
site/
├── astro.config.mjs       # Astro + Starlight + Sitemap + MDX config
├── package.json
├── tsconfig.json
├── public/                # Static assets served verbatim (favicon, robots.txt, CNAME, OG images)
└── src/
    ├── content.config.ts  # Starlight docs collection wiring
    ├── content/docs/      # All documentation content (MDX)
    │   ├── index.mdx
    │   ├── getting-started.mdx
    │   ├── configuration.mdx
    │   ├── commands/      # One MDX page per command (15 total)
    │   ├── skills/        # MDX pages for the 10 highlighted skills
    │   └── integrations/  # claude-code, opencode, ci
    └── styles/            # Brand overrides (custom.css)
```

## Content Sources

Page content is authored from existing markdown in the plugin root. The site
does not duplicate content by rewriting it; it imports the same prose into
Starlight-friendly MDX with adjusted cross-links.

| Site page                   | Source of truth                                           |
| :-------------------------- | :-------------------------------------------------------- |
| `/`                         | `README.md`, `CLAUDE.md` (Iron Rule, Philosophy)          |
| `/getting-started`          | `README.md#Installation`, `commands/vf-setup.md`          |
| `/configuration`            | `config/strict.json`, `config/standard.json`, `config/permissive.json`, `README.md#Configuration` |
| `/commands/*`               | `commands/*.md` (one-to-one)                              |
| `/skills/*`                 | `skills/<name>/SKILL.md` (10 skills)                      |
| `/integrations/claude-code` | `README.md`, `ARCHITECTURE.md`, `docs/PORTABILITY.md`     |
| `/integrations/opencode`    | `docs/PORTABILITY.md`, `.opencode/`                       |
| `/integrations/ci`          | `commands/validate-ci.md`, `README.md`                    |

## Iron Rule 2 (No Test Files)

This site adheres to the same no-mock discipline as the plugin. There are no
unit-test files in this directory. Verification is:

1. `npm run build` must succeed and produce `dist/index.html`.
2. Evidence-based browser validation of `npm run dev` (screenshots per route).
3. `scripts/check-seo.mjs` audits frontmatter title + description per page.
4. `sitemap.xml` is present in `dist/` after build.

## Deployment

The site is a plain static build (`dist/`). Primary deploy target is GitHub
Pages with a `CNAME` record pointing at `validationforge.dev`. See
`.github/workflows/deploy.yml` and `site/public/CNAME` (added in phase 7).

The `dist/` output is framework-agnostic; Cloudflare Pages, Vercel, Netlify,
or any static host will also work without modification.

## Learn More

- [Astro docs](https://docs.astro.build)
- [Starlight docs](https://starlight.astro.build)
- [ValidationForge repository](https://github.com/krzemienski/validationforge)
