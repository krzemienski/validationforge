// LinkedIn request capture + normalization.
// Ingests: (a) curl commands pasted by user, (b) chrome-devtools MCP list_network_requests output.
// Output: .lp-har.json — a replayable corpus of {method,url,headers,body,response} records.
//
// Philosophy: record once, replay forever. The iOS app + web app make dozens of calls per
// user action. Most are unimportant; a handful are the load-bearing POST/PUT that actually
// create content. We capture everything, then filter at replay time.

import { promises as fs } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const HAR_PATH = path.resolve(__dirname, '..', '.lp-har.json');

// Cookies we must redact on disk. Keep the NAMES so replay can re-inject from env.
const REDACT_COOKIES = ['li_at', 'JSESSIONID', 'bcookie', 'bscookie', 'lidc', 'sdsc', '__cf_bm'];
const REDACT_HEADERS = ['cookie', 'csrf-token', 'x-li-page-instance'];

function redactHeaders(headers) {
  const out = {};
  for (const [k, v] of Object.entries(headers || {})) {
    out[k] = REDACT_HEADERS.includes(k.toLowerCase()) ? '<REDACTED>' : v;
  }
  return out;
}

/**
 * Parse a curl command string into a normalized request record.
 * Supports: -X METHOD, -H 'Header: Value', --data/-d, -b 'cookies', URL.
 * The input format is the actual clipboard content users paste from DevTools or Proxyman.
 */
function parseCurl(curlStr) {
  const lines = curlStr.replace(/\\\n/g, ' ').split(/\s+(?=-[bHXd]|--data|'https?:)/);
  const rec = { method: 'GET', url: null, headers: {}, body: null };

  for (let i = 0; i < lines.length; i++) {
    const part = lines[i].trim();
    if (/^https?:/.test(part) || /^'https?:/.test(part)) {
      rec.url = part.replace(/^'|'$/g, '');
    } else if (/^-X\b/.test(part)) {
      rec.method = part.replace(/^-X\s+'?|'?$/g, '').trim();
    } else if (/^-H\b/.test(part)) {
      const hv = part.replace(/^-H\s+'?|'?$/g, '').trim();
      const idx = hv.indexOf(':');
      if (idx > 0) rec.headers[hv.slice(0, idx).trim().toLowerCase()] = hv.slice(idx + 1).trim();
    } else if (/^(--data|-d)\b/.test(part)) {
      rec.body = part.replace(/^(--data(-raw|-binary)?|-d)\s+'?|'?$/g, '').trim();
    } else if (/^-b\b/.test(part)) {
      rec.headers.cookie = part.replace(/^-b\s+'?|'?$/g, '').trim();
    }
  }

  if (!rec.url) throw new Error('parseCurl: no URL found in curl command');
  return rec;
}

/**
 * Normalize a chrome-devtools MCP network request object into our HAR format.
 * Chrome DevTools returns { reqid, url, method, requestHeaders, responseHeaders, status }.
 * Body must be fetched via get_network_request(reqid) — caller passes { body, respBody }.
 */
function normalizeChromeRequest({ reqid, url, method, requestHeaders, responseHeaders, status, body, respBody }) {
  return {
    source: 'chrome-devtools',
    reqid,
    method: method || 'GET',
    url,
    headers: redactHeaders(requestHeaders),
    body: body || null,
    response: { status, headers: redactHeaders(responseHeaders), body: respBody || null },
    captured_at: new Date().toISOString(),
  };
}

async function loadHar() {
  try {
    const raw = await fs.readFile(HAR_PATH, 'utf8');
    return JSON.parse(raw);
  } catch {
    return { version: 1, captured_at: new Date().toISOString(), requests: [] };
  }
}

async function saveHar(har) {
  har.updated_at = new Date().toISOString();
  await fs.writeFile(HAR_PATH, JSON.stringify(har, null, 2));
}

/**
 * Append a new request record to the corpus. Dedupes by method+url+body-hash.
 */
async function appendRequest(record) {
  const har = await loadHar();
  const dupKey = `${record.method} ${record.url} ${record.body || ''}`;
  const existingIdx = har.requests.findIndex(r => `${r.method} ${r.url} ${r.body || ''}` === dupKey);
  if (existingIdx >= 0) {
    har.requests[existingIdx] = { ...har.requests[existingIdx], ...record };
  } else {
    har.requests.push(record);
  }
  await saveHar(har);
  return { total: har.requests.length, dedup: existingIdx >= 0 };
}

async function captureFromCurl(curlStr, { tag } = {}) {
  const parsed = parseCurl(curlStr);
  parsed.source = 'curl';
  parsed.tag = tag || null;
  parsed.headers = redactHeaders(parsed.headers);
  parsed.captured_at = new Date().toISOString();
  return appendRequest(parsed);
}

async function listRequests({ filterUrl } = {}) {
  const har = await loadHar();
  const filtered = filterUrl
    ? har.requests.filter(r => r.url.includes(filterUrl))
    : har.requests;
  return filtered.map(r => ({
    method: r.method,
    url: r.url,
    tag: r.tag,
    has_body: Boolean(r.body),
    source: r.source,
    captured_at: r.captured_at,
  }));
}

export { parseCurl, normalizeChromeRequest, captureFromCurl, appendRequest, listRequests, loadHar, HAR_PATH };

if (import.meta.url === `file://${process.argv[1]}`) {
  const cmd = process.argv[2];
  (async () => {
    if (cmd === 'list') {
      const url = process.argv[3] || null;
      const rows = await listRequests({ filterUrl: url });
      console.log(JSON.stringify({ count: rows.length, requests: rows }, null, 2));
    } else if (cmd === 'add-curl') {
      // Read curl from stdin
      const chunks = [];
      for await (const c of process.stdin) chunks.push(c);
      const curlStr = Buffer.concat(chunks).toString();
      const tag = process.argv[3] || null;
      const result = await captureFromCurl(curlStr, { tag });
      console.log(JSON.stringify({ status: 'OK', ...result }));
    } else {
      console.error('usage: node capture.js <list [url-substr]|add-curl <tag>>');
      process.exit(2);
    }
  })().catch(err => {
    console.error(err.message || String(err));
    process.exit(1);
  });
}
