// LinkedIn OAuth 2.0 authorization-code flow + token refresh.
// Scaffold; requires LINKEDIN_CLIENT_ID/SECRET in .env before use.

import http from 'node:http';
import { URL } from 'node:url';
import { promises as fs } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import open from 'open';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ENV_PATH = path.resolve(__dirname, '..', '.env');

const AUTH_URL = 'https://www.linkedin.com/oauth/v2/authorization';
const TOKEN_URL = 'https://www.linkedin.com/oauth/v2/accessToken';
const USERINFO_URL = 'https://api.linkedin.com/v2/userinfo';
const SCOPES = ['openid', 'profile', 'email', 'w_member_social'];

function randomState() {
  return Math.random().toString(36).slice(2) + Date.now().toString(36);
}

async function readEnv() {
  try {
    const raw = await fs.readFile(ENV_PATH, 'utf8');
    const map = {};
    for (const line of raw.split('\n')) {
      const m = line.match(/^([A-Z_][A-Z0-9_]*)=(.*)$/);
      if (m) map[m[1]] = m[2];
    }
    return map;
  } catch {
    return {};
  }
}

async function writeEnv(env) {
  const lines = Object.entries(env).map(([k, v]) => `${k}=${v ?? ''}`);
  await fs.writeFile(ENV_PATH, lines.join('\n') + '\n', 'utf8');
}

async function patchEnv(updates) {
  const env = await readEnv();
  Object.assign(env, updates);
  await writeEnv(env);
}

export async function runAuthFlow() {
  const env = await readEnv();
  const clientId = env.LINKEDIN_CLIENT_ID;
  const clientSecret = env.LINKEDIN_CLIENT_SECRET;
  const redirectUri = env.LINKEDIN_REDIRECT_URI || 'http://localhost:3000/callback';
  const redirectParsed = new URL(redirectUri);
  const callbackPort = Number(redirectParsed.port) || (redirectParsed.protocol === 'https:' ? 443 : 80);
  const callbackOrigin = `${redirectParsed.protocol}//${redirectParsed.hostname}:${callbackPort}`;

  if (!clientId || !clientSecret) {
    throw new Error('LINKEDIN_CLIENT_ID and LINKEDIN_CLIENT_SECRET must be set in .env');
  }

  const state = randomState();
  const authParams = new URLSearchParams({
    response_type: 'code',
    client_id: clientId,
    redirect_uri: redirectUri,
    scope: SCOPES.join(' '),
    state,
  });
  const authorizeUrl = `${AUTH_URL}?${authParams.toString()}`;

  console.log('Opening browser for LinkedIn consent...');
  console.log('If browser does not open, visit:\n', authorizeUrl);

  const code = await new Promise((resolve, reject) => {
    const server = http.createServer(async (req, res) => {
      try {
        const url = new URL(req.url, callbackOrigin);
        if (url.pathname !== '/callback') {
          res.writeHead(404).end('Not found');
          return;
        }
        const returnedState = url.searchParams.get('state');
        const returnedCode = url.searchParams.get('code');
        const error = url.searchParams.get('error');
        if (error) {
          res.writeHead(400).end(`OAuth error: ${error}`);
          server.close();
          reject(new Error(error));
          return;
        }
        if (returnedState !== state) {
          res.writeHead(400).end('State mismatch — aborting.');
          server.close();
          reject(new Error('state mismatch'));
          return;
        }
        res.writeHead(200, { 'content-type': 'text/html' });
        res.end('<h1>OK — return to terminal.</h1>');
        server.close();
        resolve(returnedCode);
      } catch (e) {
        reject(e);
      }
    });
    server.listen(callbackPort, () => {
      console.log(`Callback server listening on ${callbackOrigin}`);
      open(authorizeUrl).catch(() => { /* user can copy URL */ });
    });
  });

  // Exchange code for tokens
  const tokenRes = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'authorization_code',
      code,
      redirect_uri: redirectUri,
      client_id: clientId,
      client_secret: clientSecret,
    }),
  });

  if (!tokenRes.ok) {
    throw new Error(`token exchange failed: ${tokenRes.status} ${await tokenRes.text()}`);
  }

  const tokens = await tokenRes.json();
  const expiresAt = Date.now() + (tokens.expires_in * 1000);

  // Capture member URN via /v2/userinfo
  const meRes = await fetch(USERINFO_URL, {
    headers: { authorization: `Bearer ${tokens.access_token}` },
  });
  if (!meRes.ok) {
    throw new Error(`userinfo failed: ${meRes.status} ${await meRes.text()}`);
  }
  const me = await meRes.json();
  const personUrn = `urn:li:person:${me.sub}`;

  await patchEnv({
    LINKEDIN_ACCESS_TOKEN: tokens.access_token,
    LINKEDIN_REFRESH_TOKEN: tokens.refresh_token || '',
    LINKEDIN_ACCESS_TOKEN_EXPIRES_AT: String(expiresAt),
    LINKEDIN_PERSON_URN: personUrn,
  });

  console.log('OAuth complete. Tokens written to .env');
  console.log('Person URN:', personUrn);
  return { accessToken: tokens.access_token, personUrn };
}

export async function refreshAccessToken() {
  const env = await readEnv();
  const refresh = env.LINKEDIN_REFRESH_TOKEN;
  if (!refresh) throw new Error('No refresh token. Run `lp auth` first.');

  const res = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'refresh_token',
      refresh_token: refresh,
      client_id: env.LINKEDIN_CLIENT_ID,
      client_secret: env.LINKEDIN_CLIENT_SECRET,
    }),
  });

  if (!res.ok) {
    throw new Error(`refresh failed: ${res.status} ${await res.text()}`);
  }
  const tokens = await res.json();
  const expiresAt = Date.now() + (tokens.expires_in * 1000);
  await patchEnv({
    LINKEDIN_ACCESS_TOKEN: tokens.access_token,
    LINKEDIN_ACCESS_TOKEN_EXPIRES_AT: String(expiresAt),
    ...(tokens.refresh_token ? { LINKEDIN_REFRESH_TOKEN: tokens.refresh_token } : {}),
  });
  return tokens.access_token;
}

export async function getValidAccessToken() {
  const env = await readEnv();
  const token = env.LINKEDIN_ACCESS_TOKEN;
  const expiresAt = parseInt(env.LINKEDIN_ACCESS_TOKEN_EXPIRES_AT || '0', 10);
  // Refresh if expired or within 1 day
  if (!token || Date.now() > (expiresAt - 86400000)) {
    return refreshAccessToken();
  }
  return token;
}

// CLI entrypoint: `node src/auth.js` → runs 3-legged OAuth flow
if (import.meta.url === `file://${process.argv[1]}`) {
  runAuthFlow()
    .then(({ personUrn }) => {
      console.log(`\n✓ Authenticated. Person URN: ${personUrn}`);
      console.log('Tokens written to .env. You can now run: node src/publish.js <md-file>');
      process.exit(0);
    })
    .catch((err) => {
      console.error('Auth failed:', err.message || String(err));
      process.exit(1);
    });
}
