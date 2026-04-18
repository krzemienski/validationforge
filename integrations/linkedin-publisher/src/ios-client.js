// LinkedIn iOS-voyager client.
// Uses iOS app session cookies + native-app UA + full iOS cookie jar.
// User captured these via proxy on 2026-04-18 and explicitly chose this path.

import { promises as fs } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ENV_LOCAL = path.resolve(__dirname, '..', '.env.local');
const LOG_PATH = path.resolve(__dirname, '..', '.lp-ios.log');

async function readEnvLocal() {
  const raw = await fs.readFile(ENV_LOCAL, 'utf8');
  const env = {};
  for (const line of raw.split('\n')) {
    const m = line.match(/^([A-Z_][A-Z0-9_]*)=(.*)$/);
    if (m) env[m[1]] = m[2];
  }
  return env;
}

function buildCookieJar(env) {
  // Exact iOS-app cookie order as captured
  const parts = [
    env.LI_SDSC ? `sdsc=${env.LI_SDSC}` : null,
    'liap=true',
    env.LI_LIDC ? `lidc=${env.LI_LIDC}` : null,
    env.LI_LROR ? `lror=${env.LI_LROR}` : null,
    env.LI_SDUI_VER ? `sdui_ver=${env.LI_SDUI_VER}` : null,
    env.LI_BCOOKIE ? `bcookie=${env.LI_BCOOKIE}` : null,
    env.LI_CF_BM ? `__cf_bm=${env.LI_CF_BM}` : null,
    'lang=v=2&lang=en-US',
    env.LI_AT ? `li_at=${env.LI_AT}` : null,
    env.LI_JSESSIONID ? `JSESSIONID=${env.LI_JSESSIONID.startsWith('"') ? env.LI_JSESSIONID : `"${env.LI_JSESSIONID}"`}` : null,
    env.LI_BSCOOKIE ? `bscookie=${env.LI_BSCOOKIE}` : null,
  ].filter(Boolean);
  return parts.join('; ');
}

function buildXLiTrack(env) {
  return JSON.stringify({
    mpVersion: '9.32.36.3',
    osName: 'iOS',
    clientVersion: '9.32.36.3',
    timezoneOffset: -4,
    osVersion: '26.5',
    displayHeight: 2868,
    deviceType: 'iphone',
    appId: 'com.linkedin.LinkedIn',
    locale: 'en_US',
    displayWidth: 1320,
    clientMinorVersion: '2026.0415.0033',
    displayDensity: 3,
    language: 'en-US',
    deviceId: env.LI_DEVICE_ID || 'AB37AB84-1EA1-4F7B-89A5-C2612CB38F0C',
    timezone: 'America/New_York',
    model: 'iphone17_2',
    carrier: '--',
    mpName: 'voyager-ios',
  });
}

function csrfFromJsession(jsessionid) {
  return jsessionid.replace(/^"|"$/g, '');
}

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
 * Build iOS-flavored headers. `pemMetadata` varies per endpoint — the captured
 * GET used `Voyager - Sharing - LoadSchedulePost=sharing-fetch-schedule-post-management`.
 */
function buildHeaders(env, { pemMetadata } = {}) {
  const headers = {
    'Host': 'www.linkedin.com',
    'Csrf-Token': csrfFromJsession(env.LI_JSESSIONID),
    'x-li-graphql-pegasus-client': 'true',
    'X-LI-Lang': 'en-US',
    'x-restli-symbol-table-name': 'voyager-21898',
    'Accept-Language': 'en-US,en;q=0.9',
    'X-RestLi-Protocol-Version': '2.0.0',
    'Accept': 'application/vnd.linkedin.deduped+x-protobuf+2.0+gql',
    'User-Agent': env.LI_USER_AGENT || 'LinkedIn/9.32.36.3 CFNetwork/3860.600.12 Darwin/25.5.0',
    'Connection': 'keep-alive',
    'X-li-page-instance': 'urn:li:page:p_flagship3_;niGNAAdDSi+MIaNMNmTWpQ==',
    'X-LI-Track': buildXLiTrack(env),
    'Cookie': buildCookieJar(env),
  };
  if (pemMetadata) headers['X-LI-PEM-Metadata'] = pemMetadata;
  return headers;
}

/**
 * Run a voyager GraphQL query (GET or POST).
 * Returns { status, contentType, body (protobuf/json) }.
 */
async function voyagerGraphql({ queryId, queryName, variables, method = 'GET', body = null, pemMetadata }) {
  const env = await readEnvLocal();
  // LinkedIn restli notation (count:10,...) uses literal parens/colons/commas.
  // URL-encoding breaks the parser (400). curl passes these raw — so do we.
  const url = `https://www.linkedin.com/voyager/api/graphql?queryId=${queryId}&queryName=${queryName}&variables=${variables}`;
  const headers = buildHeaders(env, { pemMetadata });

  await log(`${method} ${queryName} variables=${variables.slice(0, 80)}`);

  const init = { method, headers, redirect: 'manual' };
  if (body) {
    init.body = body;
    headers['Content-Type'] = 'application/json';
  }

  const res = await fetch(url, init);
  const contentType = res.headers.get('content-type') || '';
  const bodyText = contentType.includes('protobuf') ? '(binary protobuf)' : await res.text();

  await log(`RESP status=${res.status} content-type=${contentType} body_len=${bodyText === '(binary protobuf)' ? 'binary' : bodyText.length}`);

  return { status: res.status, contentType, body: bodyText, location: res.headers.get('location') };
}

/**
 * Exact replication of user's captured curl: list scheduled posts.
 */
async function listScheduled({ count = 10, start = 0 } = {}) {
  return voyagerGraphql({
    queryId: 'voyagerContentcreationDashSharePreviews.6f2d1d940546e6ff840467defe585af3',
    queryName: 'ContentCreationSharePreviewsByShareLifeCycleState',
    variables: `(count:${count},shareLifeCycleState:SCHEDULED,start:${start})`,
    method: 'GET',
    pemMetadata: 'Voyager - Sharing - LoadSchedulePost=sharing-fetch-schedule-post-management',
  });
}

export { voyagerGraphql, listScheduled, readEnvLocal, buildHeaders };

// CLI
if (import.meta.url === `file://${process.argv[1]}`) {
  const [, , cmd] = process.argv;
  (async () => {
    if (cmd === 'list-scheduled') {
      const result = await listScheduled();
      console.log(JSON.stringify({
        status: result.status,
        contentType: result.contentType,
        bodyLen: typeof result.body === 'string' ? result.body.length : 'binary',
        bodyPreview: typeof result.body === 'string' ? result.body.slice(0, 200) : '(binary protobuf)',
        location: result.location,
      }, null, 2));
    } else {
      console.error('usage: node ios-client.js list-scheduled');
      process.exit(2);
    }
  })().catch(err => {
    console.error(redact(err.message || String(err)));
    process.exit(1);
  });
}
