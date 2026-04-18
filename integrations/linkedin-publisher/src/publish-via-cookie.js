// LinkedIn cookie-based publisher — UNOFFICIAL PATH.
// Uses `li_at` + `JSESSIONID` against voyager/api endpoints. ToS §8 violation.
// User (Nick) accepted this risk on 2026-04-18 with full awareness of ban ladder.
//
// NEVER logs raw cookies. NEVER commits .env.local. Jitter applied to posting
// time to reduce automation signature. Kill-switch via LP_KILL=1 env var.

import { promises as fs } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ENV_LOCAL = path.resolve(__dirname, '..', '.env.local');
const COOKIE_LOG = path.resolve(__dirname, '..', '.lp-cookie.log');

const VOYAGER_POSTS_URL = 'https://www.linkedin.com/voyager/api/contentcreation/normShares';
const USERINFO_URL = 'https://www.linkedin.com/voyager/api/me';

async function readEnvLocal() {
  try {
    const raw = await fs.readFile(ENV_LOCAL, 'utf8');
    const env = {};
    for (const line of raw.split('\n')) {
      const m = line.match(/^([A-Z_][A-Z0-9_]*)=(.*)$/);
      if (m) env[m[1]] = m[2].replace(/^"|"$/g, '');
    }
    return env;
  } catch {
    throw new Error(`.env.local not found at ${ENV_LOCAL}. Copy .env.local.example and fill cookies.`);
  }
}

function deriveCsrfToken(jsessionid) {
  // JSESSIONID format: "ajax:XXXXXXXXX" (with quotes or without)
  return jsessionid.replace(/^"|"$/g, '');
}

function buildCookieHeader(env) {
  const parts = [
    env.LI_AT ? `li_at=${env.LI_AT}` : null,
    env.LI_JSESSIONID ? `JSESSIONID=${env.LI_JSESSIONID.startsWith('"') ? env.LI_JSESSIONID : `"${env.LI_JSESSIONID}"`}` : null,
    env.LI_BCOOKIE ? `bcookie=${env.LI_BCOOKIE}` : null,
    env.LI_BSCOOKIE ? `bscookie=${env.LI_BSCOOKIE}` : null,
    env.LI_LIDC ? `lidc=${env.LI_LIDC}` : null,
    env.LI_CF_BM ? `__cf_bm=${env.LI_CF_BM}` : null,
    'liap=true',
    'lang=v=2&lang=en-US',
    'timezone=America/New_York',
    'li_theme=light',
    'li_theme_set=app',
  ].filter(Boolean);
  return parts.join('; ');
}

function buildHeaders(env) {
  return {
    'accept': 'application/vnd.linkedin.normalized+json+2.1',
    'accept-language': 'en-US,en;q=0.9',
    'content-type': 'application/json; charset=UTF-8',
    'csrf-token': deriveCsrfToken(env.LI_JSESSIONID),
    'cookie': buildCookieHeader(env),
    'user-agent': env.LI_USER_AGENT || 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
    'x-li-lang': 'en_US',
    'x-li-page-instance': 'urn:li:page:d_flagship3_feed',
    'x-li-track': '{"clientVersion":"1.13.20000","mpVersion":"1.13.20000","osName":"web","timezoneOffset":-4,"timezone":"America/New_York","deviceFormFactor":"DESKTOP","mpName":"voyager-web"}',
    'x-restli-protocol-version': '2.0.0',
  };
}

function redactedError(err) {
  // Strip any cookie string accidentally landed in an error message
  return String(err).replace(/li_at=[^;\s]*/g, 'li_at=REDACTED')
                     .replace(/JSESSIONID=[^;\s]*/g, 'JSESSIONID=REDACTED');
}

async function appendLog(msg) {
  const ts = new Date().toISOString();
  // Safety: never let raw cookies into log
  const safe = msg.replace(/li_at=[^;\s]*/g, 'li_at=REDACTED')
                  .replace(/JSESSIONID=[^;\s]*/g, 'JSESSIONID=REDACTED');
  await fs.appendFile(COOKIE_LOG, `[${ts}] ${safe}\n`);
}

async function fetchMe(env) {
  const res = await fetch(USERINFO_URL, { headers: buildHeaders(env) });
  if (!res.ok) throw new Error(`me fetch failed: ${res.status}`);
  return res.json();
}

function jitterDelay() {
  // ±3min jitter around scheduled time to reduce automation signature
  const minMs = 0;
  const maxMs = 3 * 60 * 1000;
  return Math.floor(Math.random() * maxMs) + minMs;
}

async function postText({ body, personUrn, dryRun = false }) {
  if (process.env.LP_KILL === '1') {
    throw new Error('LP_KILL=1 — posting disabled via kill switch');
  }

  const env = await readEnvLocal();
  if (!env.LI_AT || !env.LI_JSESSIONID) {
    throw new Error('LI_AT and LI_JSESSIONID must be set in .env.local');
  }

  const payload = {
    visibleToConnectionsOnly: false,
    externalAudienceProviders: [],
    commentaryV2: {
      text: body,
      attributes: [],
    },
    origin: 'FEED_DETAIL',
    allowedCommentersScope: 'ALL',
    postState: 'PUBLISHED',
    media: [],
  };

  if (dryRun) {
    await appendLog(`DRY_RUN author=${personUrn || 'me'} body_len=${body.length}`);
    return { dryRun: true, payload, cookie_header_set: Boolean(env.LI_AT) };
  }

  const delay = jitterDelay();
  await appendLog(`JITTER_DELAY ms=${delay}`);
  await new Promise(r => setTimeout(r, delay));

  const headers = buildHeaders(env);
  let res;
  try {
    res = await fetch(VOYAGER_POSTS_URL, {
      method: 'POST',
      headers,
      body: JSON.stringify(payload),
    });
  } catch (err) {
    await appendLog(`FETCH_FAIL ${redactedError(err)}`);
    throw err;
  }

  const responseBody = await res.text();
  await appendLog(`STATUS ${res.status} body_preview=${responseBody.slice(0, 120).replace(/[\r\n]/g, ' ')}`);

  if (!res.ok) {
    const err = new Error(`publish failed: ${res.status}`);
    err.responseBody = responseBody;
    throw err;
  }

  return { status: res.status, response: responseBody };
}

export { postText, fetchMe, readEnvLocal };

// CLI entry when invoked directly
if (import.meta.url === `file://${process.argv[1]}`) {
  const [, , cmd, arg] = process.argv;
  (async () => {
    if (cmd === 'me') {
      const env = await readEnvLocal();
      try {
        const me = await fetchMe(env);
        // Try multiple known response shapes (LinkedIn changes these periodically)
        const name =
          me?.miniProfile?.firstName ||
          me?.firstName?.localized?.en_US ||
          me?.firstName ||
          me?.included?.[0]?.firstName ||
          me?.data?.miniProfile?.firstName ||
          '(unknown)';
        const urn =
          me?.miniProfile?.entityUrn ||
          me?.plainId ||
          me?.data?.miniProfile?.entityUrn ||
          '(unknown)';
        console.log(JSON.stringify({ status: 'OK', name, urn, top_keys: Object.keys(me).slice(0, 10) }));
      } catch (err) {
        console.error(redactedError(err.message || err));
        process.exit(1);
      }
    } else if (cmd === 'dry') {
      const md = await fs.readFile(arg, 'utf8');
      const result = await postText({ body: md, dryRun: true });
      console.log(JSON.stringify({ status: 'DRY_OK', body_len: md.length, result }));
    } else if (cmd === 'post') {
      const md = await fs.readFile(arg, 'utf8');
      console.error('LIVE POST in 3s — Ctrl-C to abort');
      await new Promise(r => setTimeout(r, 3000));
      const result = await postText({ body: md, dryRun: false });
      console.log(JSON.stringify({ status: 'LIVE_OK', http: result.status }));
    } else {
      console.error('usage: node publish-via-cookie.js {me|dry <md>|post <md>}');
      process.exit(2);
    }
  })().catch(err => {
    console.error(redactedError(err.message || err));
    process.exit(1);
  });
}
