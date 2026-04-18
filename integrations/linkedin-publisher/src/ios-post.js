// LinkedIn iOS-session POST to /voyager/api/contentcreation/normShares.
// Uses iOS cookies + iOS UA. POST endpoint is web-origin but auth layer accepts
// iOS session cookies.
//
// Safety ladder: dry > draft > scheduled > publish.

import { promises as fs } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { readEnvLocal, buildHeaders } from './ios-client.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const LOG_PATH = path.resolve(__dirname, '..', '.lp-ios.log');

const NORM_SHARES_URL = 'https://www.linkedin.com/voyager/api/contentcreation/normShares';

function redact(s) {
  return String(s)
    .replace(/li_at=[^;\s]*/g, 'li_at=REDACTED')
    .replace(/JSESSIONID=[^;\s]*/g, 'JSESSIONID=REDACTED')
    .replace(/bcookie=[^;\s]*/g, 'bcookie=REDACTED')
    .replace(/bscookie=[^;\s]*/g, 'bscookie=REDACTED');
}

async function log(msg) {
  const ts = new Date().toISOString();
  await fs.appendFile(LOG_PATH, `[${ts}] ${redact(msg)}\n`);
}

function stripFrontmatter(raw) {
  if (!raw.startsWith('---')) return raw;
  const end = raw.indexOf('\n---', 3);
  return end < 0 ? raw : raw.slice(end + 4).replace(/^\s*\n/, '');
}

function extractPostBody(raw) {
  const withoutFm = stripFrontmatter(raw);
  const markers = [
    /## The Post\s*\n+([\s\S]+?)(?=\n---\n|\n## |\n$)/i,
    /## Body\s*\n+([\s\S]+?)(?=\n---\n|\n## |\n$)/i,
  ];
  for (const re of markers) {
    const m = withoutFm.match(re);
    if (m) return m[1].trim();
  }
  return withoutFm.trim();
}

/**
 * Build payload for normShares POST.
 * postState options:
 *   - "DRAFT"     — saved as draft, not visible
 *   - "PUBLISHED" — live immediately
 *   - "SCHEDULED" — requires scheduledAt timestamp (ms since epoch)
 */
function buildPayload({ body, postState = 'DRAFT', scheduledAt = null, visibleToConnectionsOnly = false }) {
  const payload = {
    visibleToConnectionsOnly,
    externalAudienceProviders: [],
    commentaryV2: {
      text: body,
      attributes: [],
    },
    origin: 'FEED_DETAIL',
    allowedCommentersScope: 'ALL',
    postState,
    media: [],
  };
  if (postState === 'SCHEDULED' && scheduledAt) {
    payload.scheduledAt = scheduledAt;
  }
  return payload;
}

async function postShare({ body, postState, scheduledAt, visibleToConnectionsOnly, dryRun = false }) {
  if (process.env.LP_KILL === '1') throw new Error('LP_KILL=1 — posting disabled');

  const env = await readEnvLocal();
  const payload = buildPayload({ body, postState, scheduledAt, visibleToConnectionsOnly });

  if (dryRun) {
    await log(`DRY_RUN postState=${postState} body_len=${body.length}`);
    return { dryRun: true, url: NORM_SHARES_URL, payload, authed: Boolean(env.LI_AT) };
  }

  const headers = {
    ...buildHeaders(env),
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/vnd.linkedin.normalized+json+2.1',
    'Origin': 'https://www.linkedin.com',
  };

  await log(`POST normShares postState=${postState} body_len=${body.length} scheduled=${scheduledAt || 'n/a'}`);

  const res = await fetch(NORM_SHARES_URL, {
    method: 'POST',
    headers,
    body: JSON.stringify(payload),
    redirect: 'manual',
  });

  const ct = res.headers.get('content-type') || '';
  const respBody = await res.text();
  await log(`RESP status=${res.status} ct=${ct} body_preview=${respBody.slice(0, 200).replace(/[\r\n]/g, ' ')}`);

  return { status: res.status, contentType: ct, body: respBody };
}

export { postShare, buildPayload, extractPostBody };

// CLI
if (import.meta.url === `file://${process.argv[1]}`) {
  const args = process.argv.slice(2);
  const cmd = args[0];
  const mdPath = args[1];
  const atFlag = args.indexOf('--at');
  const scheduledAtIso = atFlag >= 0 ? args[atFlag + 1] : null;

  (async () => {
    if (!cmd || !mdPath) {
      console.error('usage: node ios-post.js <dry|draft|scheduled|publish> <md-file> [--at ISO-DATETIME]');
      process.exit(2);
    }
    const md = await fs.readFile(mdPath, 'utf8');
    const body = extractPostBody(md);

    if (cmd === 'dry') {
      const result = await postShare({ body, postState: 'DRAFT', dryRun: true });
      console.log(JSON.stringify({ status: 'DRY_OK', body_len: body.length, result_payload_keys: Object.keys(result.payload), body_preview: body.slice(0, 100) + '...' }, null, 2));
    } else if (cmd === 'draft') {
      console.error('Creating DRAFT (not public) in 3s — Ctrl-C to abort');
      await new Promise(r => setTimeout(r, 3000));
      const r = await postShare({ body, postState: 'DRAFT' });
      console.log(JSON.stringify({ cmd: 'draft', http: r.status, contentType: r.contentType, body_preview: r.body.slice(0, 300) }));
    } else if (cmd === 'scheduled') {
      if (!scheduledAtIso) {
        console.error('--at <ISO-DATETIME> required for scheduled posts');
        process.exit(2);
      }
      const scheduledAt = new Date(scheduledAtIso).getTime();
      console.error(`Scheduling for ${new Date(scheduledAt).toISOString()} in 3s — Ctrl-C to abort`);
      await new Promise(r => setTimeout(r, 3000));
      const r = await postShare({ body, postState: 'SCHEDULED', scheduledAt });
      console.log(JSON.stringify({ cmd: 'scheduled', scheduledAt: new Date(scheduledAt).toISOString(), http: r.status, body_preview: r.body.slice(0, 300) }));
    } else if (cmd === 'publish') {
      console.error('PUBLIC POST in 5s — Ctrl-C to abort');
      await new Promise(r => setTimeout(r, 5000));
      const r = await postShare({ body, postState: 'PUBLISHED' });
      console.log(JSON.stringify({ cmd: 'publish', http: r.status, body_preview: r.body.slice(0, 300) }));
    } else {
      console.error(`unknown cmd: ${cmd}`);
      process.exit(2);
    }
  })().catch(err => {
    console.error(redact(err.message || String(err)));
    process.exit(1);
  });
}
