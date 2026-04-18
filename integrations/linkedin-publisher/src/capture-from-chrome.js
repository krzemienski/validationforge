// Bulk-import chrome-devtools MCP network-request output into the HAR corpus.
// Call pattern:
//   1. Claude invokes mcp__chrome-devtools__list_network_requests
//   2. Claude invokes mcp__chrome-devtools__get_network_request(reqid) for each
//   3. Claude writes the combined array to stdin of this script
//
// Input JSON shape (pasted via stdin):
//   { pageUrl, requests: [{ reqid, url, method, requestHeaders, responseHeaders, status, body, respBody }] }
//
// Output: updates .lp-har.json with each request appended (deduped by method+url+body).

import { appendRequest } from './capture.js';

function normalizeHeaders(headersObj) {
  if (!headersObj) return {};
  if (Array.isArray(headersObj)) {
    // CDP sometimes returns [{name, value}, ...]
    return Object.fromEntries(headersObj.map(h => [h.name.toLowerCase(), h.value]));
  }
  return Object.fromEntries(Object.entries(headersObj).map(([k, v]) => [k.toLowerCase(), v]));
}

async function bulkImport(payload, { tag: sessionTag } = {}) {
  const results = { total: payload.requests.length, added: 0, deduped: 0, errors: [] };
  for (const r of payload.requests) {
    try {
      const record = {
        source: 'chrome-devtools',
        tag: sessionTag ? `${sessionTag}:${r.reqid}` : `chrome:${r.reqid}`,
        reqid: r.reqid,
        method: (r.method || 'GET').toUpperCase(),
        url: r.url,
        headers: normalizeHeaders(r.requestHeaders),
        body: r.body || null,
        response: {
          status: r.status,
          headers: normalizeHeaders(r.responseHeaders),
          body: r.respBody || null,
        },
        page_url: payload.pageUrl || null,
        captured_at: new Date().toISOString(),
      };
      // Redact cookie/csrf on disk (capture.js has the main redactor, but this is a second line)
      if (record.headers.cookie) record.headers.cookie = '<REDACTED>';
      if (record.headers['csrf-token']) record.headers['csrf-token'] = '<REDACTED>';

      const res = await appendRequest(record);
      if (res.dedup) results.deduped++;
      else results.added++;
    } catch (err) {
      results.errors.push({ reqid: r.reqid, url: r.url, error: err.message });
    }
  }
  return results;
}

export { bulkImport };

if (import.meta.url === `file://${process.argv[1]}`) {
  const args = process.argv.slice(2);
  const tagIdx = args.indexOf('--tag');
  const tag = tagIdx >= 0 ? args[tagIdx + 1] : null;

  (async () => {
    const chunks = [];
    for await (const c of process.stdin) chunks.push(c);
    const raw = Buffer.concat(chunks).toString();
    if (!raw.trim()) {
      console.error('no stdin input');
      process.exit(2);
    }
    const payload = JSON.parse(raw);
    const result = await bulkImport(payload, { tag });
    console.log(JSON.stringify({ status: 'OK', ...result }, null, 2));
  })().catch(err => {
    console.error(err.message || String(err));
    process.exit(1);
  });
}
