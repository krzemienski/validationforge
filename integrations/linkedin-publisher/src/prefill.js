// LinkedIn pre-fill share URL generator.
// Produces a URL that, when opened in a browser with an active LinkedIn session,
// pops the compose dialog pre-filled with the post body. User clicks Post manually.
//
// Zero automation surface. ToS-compliant. No API, no cookies, no detection.
// 5 seconds of human labor per post.

import { promises as fs } from 'node:fs';
import path from 'node:path';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const LOG_PATH = path.resolve(__dirname, '..', '.lp-prefill.log');

// LinkedIn share endpoint. `text` is the post body, `url` is an optional attached URL.
const SHARE_BASE = 'https://www.linkedin.com/sharing/share-offsite/';

/**
 * Strip YAML frontmatter from a markdown file.
 * Returns only the body content meant for the post.
 */
function stripFrontmatter(raw) {
  if (!raw.startsWith('---')) return raw;
  const end = raw.indexOf('\n---', 3);
  if (end < 0) return raw;
  return raw.slice(end + 4).replace(/^\s*\n/, '');
}

/**
 * Extract the post body section from campaign markdown files.
 * Campaign files use `## The Post` or similar section headers wrapping the actual
 * post content. Fall back to whole-file minus frontmatter if no marker found.
 */
function extractPostBody(raw) {
  const withoutFm = stripFrontmatter(raw);
  const markers = [
    /## The Post\s*\n+([\s\S]+?)(?=\n---\n|\n## |\n$)/i,
    /## Body\s*\n+([\s\S]+?)(?=\n---\n|\n## |\n$)/i,
    /## Post Body\s*\n+([\s\S]+?)(?=\n---\n|\n## |\n$)/i,
  ];
  for (const re of markers) {
    const m = withoutFm.match(re);
    if (m) return m[1].trim();
  }
  return withoutFm.trim();
}

/**
 * Build the pre-fill share URL.
 * `text` is URL-encoded; LinkedIn accepts long bodies but truncates in the dialog
 * at ~3000 chars. User can paste longer copy manually after opening.
 */
function buildShareUrl({ text, url }) {
  const params = new URLSearchParams();
  if (url) params.set('url', url);
  params.set('text', text);
  return `${SHARE_BASE}?${params.toString()}`;
}

async function logAction(msg) {
  const ts = new Date().toISOString();
  await fs.appendFile(LOG_PATH, `[${ts}] ${msg}\n`);
}

async function generate({ mdPath, url, open = false }) {
  const raw = await fs.readFile(mdPath, 'utf8');
  const body = extractPostBody(raw);
  const shareUrl = buildShareUrl({ text: body, url });

  await logAction(`GENERATE md=${path.basename(mdPath)} body_len=${body.length} url=${url || '(none)'}`);

  if (open) {
    spawn('open', [shareUrl], { detached: true, stdio: 'ignore' }).unref();
    await logAction(`OPEN_IN_BROWSER md=${path.basename(mdPath)}`);
  }

  return { shareUrl, body_len: body.length };
}

export { generate, buildShareUrl, extractPostBody, stripFrontmatter };

// CLI
if (import.meta.url === `file://${process.argv[1]}`) {
  const args = process.argv.slice(2);
  if (args.length === 0 || args.includes('--help')) {
    console.error('usage: node prefill.js <markdown-file> [--url <attached-url>] [--open]');
    console.error('  --url  attach a URL card (e.g. GitHub repo) to the post');
    console.error('  --open auto-open the share URL in default browser');
    process.exit(args.length === 0 ? 2 : 0);
  }

  const mdPath = args[0];
  const urlIdx = args.indexOf('--url');
  const url = urlIdx >= 0 ? args[urlIdx + 1] : null;
  const open = args.includes('--open');

  (async () => {
    const { shareUrl, body_len } = await generate({ mdPath, url, open });
    console.log(JSON.stringify({ status: 'OK', body_len, shareUrl, opened: open }));
  })().catch(err => {
    console.error(String(err.message || err));
    process.exit(1);
  });
}
