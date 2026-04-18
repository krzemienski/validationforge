// LinkedIn request replay.
// Reads .lp-har.json, finds a captured request matching a tag/url/method predicate,
// substitutes cookies + CSRF + body variables from env, re-fires via node fetch.
//
// This is the "JavaScript can do this" path the user asked for:
// once a flow is captured (compose → draft → schedule), replay it endlessly
// by swapping the post body + scheduledAt without driving a browser.

import { promises as fs } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { readEnvLocal, buildHeaders } from './ios-client.js';
import { loadHar } from './capture.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const LOG_PATH = path.resolve(__dirname, '..', '.lp-replay.log');

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

/**
 * Find a captured request by predicate (tag, url-substring, or method).
 * Returns the first match; use listRequests() to discover available tags.
 */
async function findRequest({ tag, urlIncludes, method }) {
  const har = await loadHar();
  const matches = har.requests.filter(r => {
    if (tag && r.tag !== tag) return false;
    if (urlIncludes && !r.url.includes(urlIncludes)) return false;
    if (method && r.method.toUpperCase() !== method.toUpperCase()) return false;
    return true;
  });
  return matches[0] || null;
}

/**
 * Substitute `{{VARNAME}}` placeholders in the captured body with live values.
 * Variables available:
 *   {{POST_BODY}}    — the markdown post content
 *   {{SCHEDULED_AT}} — ms epoch timestamp
 *   {{POST_STATE}}   — DRAFT | SCHEDULED | PUBLISHED
 */
function substituteBody(bodyTemplate, vars) {
  if (!bodyTemplate) return null;
  let out = bodyTemplate;
  for (const [k, v] of Object.entries(vars)) {
    const re = new RegExp(`\\{\\{${k}\\}\\}`, 'g');
    // JSON-escape string values so quotes/newlines don't break the payload
    const safe = typeof v === 'string' ? JSON.stringify(v).slice(1, -1) : v;
    out = out.replace(re, safe);
  }
  return out;
}

/**
 * Replay a captured request with live auth + variable substitution.
 * Returns { status, contentType, body }.
 */
async function replayRequest({ tag, urlIncludes, method, vars = {}, dryRun = false }) {
  if (process.env.LP_KILL === '1') throw new Error('LP_KILL=1 — replay disabled');

  const rec = await findRequest({ tag, urlIncludes, method });
  if (!rec) throw new Error(`no captured request matching tag=${tag} url=${urlIncludes} method=${method}`);

  const env = await readEnvLocal();
  // Build live headers (injects cookies + CSRF + X-LI-Track from .env.local)
  const liveHeaders = buildHeaders(env);
  // Merge any captured headers that weren't REDACTED (e.g. Content-Type, Accept)
  for (const [k, v] of Object.entries(rec.headers || {})) {
    if (v !== '<REDACTED>' && !liveHeaders[k] && !liveHeaders[k.toLowerCase()]) {
      liveHeaders[k] = v;
    }
  }

  const body = substituteBody(rec.body, vars);

  await log(`REPLAY tag=${rec.tag || '-'} ${rec.method} ${rec.url.slice(0, 120)} body_len=${body ? body.length : 0}`);

  if (dryRun) {
    return {
      dryRun: true,
      tag: rec.tag,
      method: rec.method,
      url: rec.url,
      body_len: body ? body.length : 0,
      body_preview: body ? body.slice(0, 200) : null,
      headers_count: Object.keys(liveHeaders).length,
    };
  }

  const init = { method: rec.method, headers: liveHeaders, redirect: 'manual' };
  if (body && rec.method !== 'GET') init.body = body;

  const res = await fetch(rec.url, init);
  const contentType = res.headers.get('content-type') || '';
  const respBody = contentType.includes('protobuf') ? '(binary protobuf)' : await res.text();

  await log(`RESP status=${res.status} ct=${contentType} body_len=${respBody === '(binary protobuf)' ? 'binary' : respBody.length}`);

  return { status: res.status, contentType, body: respBody, location: res.headers.get('location') };
}

export { findRequest, replayRequest, substituteBody };

if (import.meta.url === `file://${process.argv[1]}`) {
  const args = process.argv.slice(2);
  const tagIdx = args.indexOf('--tag');
  const urlIdx = args.indexOf('--url');
  const methodIdx = args.indexOf('--method');
  const dry = args.includes('--dry');

  const tag = tagIdx >= 0 ? args[tagIdx + 1] : null;
  const urlIncludes = urlIdx >= 0 ? args[urlIdx + 1] : null;
  const method = methodIdx >= 0 ? args[methodIdx + 1] : null;

  if (!tag && !urlIncludes) {
    console.error('usage: node replay.js --tag <tag> | --url <substr> [--method GET|POST] [--dry]');
    process.exit(2);
  }

  (async () => {
    const result = await replayRequest({ tag, urlIncludes, method, dryRun: dry });
    console.log(JSON.stringify({ status: 'OK', ...result, body: undefined, body_preview: (result.body || '').slice(0, 200) }, null, 2));
  })().catch(err => {
    console.error(redact(err.message || String(err)));
    process.exit(1);
  });
}
