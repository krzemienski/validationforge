// One-shot: initializeUpload → PUT PDF → post with document content
// Logs each HTTP step for traceability. No retries. Fails loudly.

import { promises as fs } from 'node:fs';
import path from 'node:path';

const ROOT = '/Users/nick/Desktop/validationforge';
const ENV_PATH = path.join(ROOT, 'integrations/linkedin-publisher/.env');
const PDF_PATH = path.join(ROOT, 'plans/260419-1817-vf-linkedin-launch-today/hero-vf-launch.pdf');
const COMMENTARY_PATH = path.join(ROOT, 'plans/260419-1817-vf-linkedin-launch-today/commentary.txt');
const LOG_PATH = path.join(ROOT, 'plans/260419-1817-vf-linkedin-launch-today/fire-pdf-post.log');
const API_VERSION = '202604';
const DOC_TITLE = 'What 23,479 AI Coding Sessions Taught Me About Shipping Real Software';

async function loadEnv() {
  const txt = await fs.readFile(ENV_PATH, 'utf8');
  const env = {};
  for (const line of txt.split('\n')) {
    const m = line.match(/^([A-Z_][A-Z0-9_]*)=(.*)$/);
    if (m) env[m[1]] = m[2].replace(/^"|"$/g, '');
  }
  return env;
}

async function log(msg) {
  const ts = new Date().toISOString();
  const line = `[${ts}] ${msg}\n`;
  console.log(line.trimEnd());
  await fs.appendFile(LOG_PATH, line);
}

async function initializeUpload(token, personUrn) {
  const url = `https://api.linkedin.com/rest/documents?action=initializeUpload`;
  const body = { initializeUploadRequest: { owner: personUrn } };
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
      'LinkedIn-Version': API_VERSION,
      'X-Restli-Protocol-Version': '2.0.0',
    },
    body: JSON.stringify(body),
  });
  const text = await res.text();
  await log(`initializeUpload → HTTP ${res.status}`);
  await log(`initializeUpload body: ${text.slice(0, 800)}`);
  if (!res.ok) throw new Error(`initializeUpload failed: ${res.status} ${text}`);
  const data = JSON.parse(text);
  const uploadUrl = data?.value?.uploadUrl;
  const docUrn = data?.value?.document;
  if (!uploadUrl || !docUrn) throw new Error('no uploadUrl or document in response');
  return { uploadUrl, docUrn };
}

async function uploadPdfBinary(uploadUrl, pdfBytes, token) {
  const res = await fetch(uploadUrl, {
    method: 'PUT',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/pdf',
    },
    body: pdfBytes,
  });
  const text = await res.text();
  await log(`PUT upload → HTTP ${res.status} bytes=${pdfBytes.length}`);
  await log(`PUT body preview: ${text.slice(0, 400)}`);
  if (!res.ok && res.status !== 201) throw new Error(`PUT upload failed: ${res.status} ${text}`);
  return { status: res.status, etag: res.headers.get('etag') };
}

async function waitForDocReady(docUrn, token, maxAttempts = 20) {
  const encoded = encodeURIComponent(docUrn);
  const url = `https://api.linkedin.com/rest/documents/${encoded}`;
  for (let i = 0; i < maxAttempts; i += 1) {
    const res = await fetch(url, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'LinkedIn-Version': API_VERSION,
        'X-Restli-Protocol-Version': '2.0.0',
      },
    });
    const text = await res.text();
    await log(`poll doc attempt ${i+1}: HTTP ${res.status} body=${text.slice(0, 200)}`);
    if (res.ok) {
      const data = JSON.parse(text);
      const status = data?.status || data?.lifecycleStatus || data?.value?.status;
      if (status === 'AVAILABLE' || status === 'PROCESSED' || status === 'PUBLISHED') return data;
      if (status === 'FAILED' || status === 'PROCESSING_FAILED') throw new Error(`doc processing FAILED: ${text}`);
    }
    await new Promise(r => setTimeout(r, 2000));
  }
  await log('poll timed out — proceeding anyway (doc may be ready)');
  return null;
}

async function createPost({ token, personUrn, commentary, docUrn, title }) {
  const body = {
    author: personUrn,
    commentary,
    visibility: 'PUBLIC',
    distribution: {
      feedDistribution: 'MAIN_FEED',
      targetEntities: [],
      thirdPartyDistributionChannels: [],
    },
    content: {
      media: {
        title,
        id: docUrn,
      },
    },
    lifecycleState: 'PUBLISHED',
    isReshareDisabledByAuthor: false,
  };
  const res = await fetch('https://api.linkedin.com/rest/posts', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
      'LinkedIn-Version': API_VERSION,
      'X-Restli-Protocol-Version': '2.0.0',
    },
    body: JSON.stringify(body),
  });
  const text = await res.text();
  const postUrn = res.headers.get('x-restli-id') || res.headers.get('X-RestLi-Id');
  await log(`POST /rest/posts → HTTP ${res.status} postUrn=${postUrn}`);
  await log(`POST body preview: ${text.slice(0, 600)}`);
  if (!res.ok) throw new Error(`createPost failed: ${res.status} ${text}`);
  return { status: res.status, postUrn };
}

async function main() {
  await log('=== fire-pdf-post.mjs START ===');
  const env = await loadEnv();
  const token = env.LINKEDIN_ACCESS_TOKEN;
  const personUrn = env.LINKEDIN_PERSON_URN;
  if (!token || !personUrn) throw new Error('missing LINKEDIN_ACCESS_TOKEN or LINKEDIN_PERSON_URN');

  const pdf = await fs.readFile(PDF_PATH);
  const commentary = (await fs.readFile(COMMENTARY_PATH, 'utf8')).trim();
  await log(`inputs: pdf_bytes=${pdf.length} commentary_chars=${commentary.length} author=${personUrn}`);

  const { uploadUrl, docUrn } = await initializeUpload(token, personUrn);
  await log(`docUrn=${docUrn}`);

  await uploadPdfBinary(uploadUrl, pdf, token);

  await waitForDocReady(docUrn, token);

  const postResult = await createPost({ token, personUrn, commentary, docUrn, title: DOC_TITLE });
  await log(`=== DONE postUrn=${postResult.postUrn} ===`);
  console.log(JSON.stringify({ status: 'OK', postUrn: postResult.postUrn, docUrn }));
}

main().catch(async (err) => {
  await log(`FATAL: ${err.message}`);
  console.error('FATAL:', err.message);
  process.exit(1);
});
