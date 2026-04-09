#!/usr/bin/env node
// Generate a self-contained HTML evidence dashboard from e2e-evidence/.
// All images are base64-encoded inline. No external dependencies.
// Usage: node scripts/generate-report.js [evidence-dir] [output-file]

'use strict';

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const evidenceDir = process.argv[2] || 'e2e-evidence';
const outputFile = process.argv[3] || path.join(evidenceDir, 'dashboard.html');

// Validate paths don't escape project
function validatePath(p) {
  if (path.isAbsolute(p)) {
    process.stderr.write(`[generate-report] ERROR: Path must be relative. Got: ${p}\n`);
    process.exit(1);
  }
  if (p.includes('..')) {
    process.stderr.write(`[generate-report] ERROR: Path must not contain traversal. Got: ${p}\n`);
    process.exit(1);
  }
}

validatePath(evidenceDir);

if (!fs.existsSync(evidenceDir)) {
  process.stderr.write(`[generate-report] ERROR: Evidence directory not found: ${evidenceDir}\n`);
  process.exit(1);
}

console.log(`[generate-report] Reading evidence from: ${evidenceDir}`);

// Discover journey directories (subdirs that are not hidden)
const journeyDirs = fs.readdirSync(evidenceDir, { withFileTypes: true })
  .filter(d => d.isDirectory() && !d.name.startsWith('.'))
  .map(d => d.name);

console.log(`[generate-report] Found ${journeyDirs.length} journey(s): ${journeyDirs.join(', ')}`);

// Read overall report.md if it exists
let reportMd = '';
const reportMdPath = path.join(evidenceDir, 'report.md');
if (fs.existsSync(reportMdPath)) {
  reportMd = fs.readFileSync(reportMdPath, 'utf8');
}

// Extract overall verdict from report.md or a journey's VERDICT.md
function extractVerdict(text) {
  if (!text) return null;
  const m = text.match(/Overall Verdict[:\s]+\**(PASS|FAIL)\**/i)
    || text.match(/\*\*PASS\*\*/i)
    || text.match(/\*\*FAIL\*\*/i);
  if (!m) return null;
  const upper = m[0].toUpperCase();
  if (upper.includes('PASS')) return 'PASS';
  if (upper.includes('FAIL')) return 'FAIL';
  return null;
}

// Build journey data
function buildJourneyData(journeyName) {
  const dir = path.join(evidenceDir, journeyName);
  const files = fs.readdirSync(dir, { withFileTypes: true });

  const images = [];
  const jsonFiles = [];
  const textFiles = [];
  let verdictText = '';
  let verdict = null;

  for (const f of files) {
    if (!f.isFile()) continue;
    const ext = path.extname(f.name).toLowerCase();
    const filePath = path.join(dir, f.name);

    if (ext === '.png' || ext === '.jpg' || ext === '.jpeg' || ext === '.gif' || ext === '.webp') {
      const mime = ext === '.jpg' || ext === '.jpeg' ? 'image/jpeg'
        : ext === '.gif' ? 'image/gif'
        : ext === '.webp' ? 'image/webp'
        : 'image/png';
      const b64 = fs.readFileSync(filePath).toString('base64');
      images.push({ name: f.name, mime, b64 });
    } else if (ext === '.json') {
      let content = fs.readFileSync(filePath, 'utf8');
      try {
        content = JSON.stringify(JSON.parse(content), null, 2);
      } catch (_) { /* keep raw */ }
      jsonFiles.push({ name: f.name, content });
    } else if (ext === '.md' || ext === '.txt') {
      const content = fs.readFileSync(filePath, 'utf8');
      if (f.name.toLowerCase().includes('verdict')) {
        verdictText = content;
        verdict = extractVerdict(content);
      }
      textFiles.push({ name: f.name, content });
    }
  }

  // Fallback: check report.md for this journey
  if (!verdict) {
    const journeyPattern = new RegExp(`${journeyName}[\\s\\S]*?(PASS|FAIL)`, 'i');
    const m = reportMd.match(journeyPattern);
    if (m) verdict = m[1].toUpperCase();
  }

  return { name: journeyName, verdict, images, jsonFiles, textFiles, verdictText };
}

const journeys = journeyDirs.map(name => {
  console.log(`[generate-report]   Processing journey: ${name}`);
  return buildJourneyData(name);
});

// Overall verdict: PASS if all journeys pass, FAIL if any fail
const overallVerdict = journeys.length === 0 ? 'UNKNOWN'
  : journeys.every(j => j.verdict === 'PASS') ? 'PASS'
  : journeys.some(j => j.verdict === 'FAIL') ? 'FAIL'
  : 'UNKNOWN';

const passCount = journeys.filter(j => j.verdict === 'PASS').length;
const failCount = journeys.filter(j => j.verdict === 'FAIL').length;
const unknownCount = journeys.length - passCount - failCount;

// Read benchmark history from .vf/benchmarks/
function loadBenchmarkHistory() {
  const benchDir = '.vf/benchmarks';
  if (!fs.existsSync(benchDir)) return [];
  const files = fs.readdirSync(benchDir)
    .filter(f => f.startsWith('benchmark-') && f.endsWith('.json'))
    .sort();
  const history = [];
  for (const f of files) {
    try {
      const data = JSON.parse(fs.readFileSync(path.join(benchDir, f), 'utf8'));
      history.push(data);
    } catch (_) { /* skip malformed */ }
  }
  return history.slice(-30); // last 30 entries
}

const benchmarkHistory = loadBenchmarkHistory();

// Save new benchmark snapshot
function saveBenchmarkSnapshot() {
  const benchDir = '.vf/benchmarks';
  fs.mkdirSync(benchDir, { recursive: true });
  const today = new Date().toISOString().slice(0, 10);
  const snapshotPath = path.join(benchDir, `benchmark-${today}.json`);
  const snapshot = {
    timestamp: new Date().toISOString(),
    evidenceDir,
    totalJourneys: journeys.length,
    passCount,
    failCount,
    unknownCount,
    overallVerdict,
    journeys: journeys.map(j => ({ name: j.name, verdict: j.verdict || 'UNKNOWN' }))
  };
  fs.writeFileSync(snapshotPath, JSON.stringify(snapshot, null, 2));
  console.log(`[generate-report] Benchmark snapshot saved: ${snapshotPath}`);
  return snapshot;
}

const newSnapshot = saveBenchmarkSnapshot();
// Include new snapshot in chart data
const allBenchmarks = [...benchmarkHistory, newSnapshot];

// Generate SVG trend chart
function generateTrendChart(history) {
  if (history.length === 0) {
    return `<div class="no-history">No benchmark history yet</div>`;
  }

  const W = 600, H = 200;
  const padLeft = 40, padRight = 20, padTop = 20, padBottom = 40;
  const chartW = W - padLeft - padRight;
  const chartH = H - padTop - padBottom;
  const n = history.length;

  // Score = passCount / totalJourneys * 100, fallback to aggregate.weighted_score
  const scores = history.map(h => {
    if (typeof h.passCount === 'number' && typeof h.totalJourneys === 'number' && h.totalJourneys > 0) {
      return Math.round((h.passCount / h.totalJourneys) * 100);
    }
    if (h.aggregate && typeof h.aggregate.weighted_score === 'number') {
      return h.aggregate.weighted_score;
    }
    return 0;
  });

  const maxScore = 100;
  const minScore = 0;

  function px(i) {
    return padLeft + (n === 1 ? chartW / 2 : (i / (n - 1)) * chartW);
  }
  function py(score) {
    return padTop + chartH - ((score - minScore) / (maxScore - minScore)) * chartH;
  }

  // Build polyline points
  const points = scores.map((s, i) => `${px(i)},${py(s)}`).join(' ');

  // X axis labels (dates)
  const labels = history.map((h, i) => {
    const ts = h.timestamp ? h.timestamp.slice(0, 10) : '';
    const x = px(i);
    const show = n <= 6 || i === 0 || i === n - 1 || i % Math.ceil(n / 6) === 0;
    if (!show) return '';
    return `<text x="${x}" y="${H - 5}" text-anchor="middle" class="chart-label">${ts}</text>`;
  }).join('');

  // Y axis ticks
  const yTicks = [0, 25, 50, 75, 100].map(v => {
    const y = py(v);
    return `<line x1="${padLeft}" y1="${y}" x2="${W - padRight}" y2="${y}" class="chart-grid"/>
            <text x="${padLeft - 5}" y="${y + 4}" text-anchor="end" class="chart-label">${v}</text>`;
  }).join('');

  // Dots for each data point
  const dots = scores.map((s, i) => {
    const cls = s >= 75 ? 'dot-pass' : s >= 50 ? 'dot-warn' : 'dot-fail';
    return `<circle cx="${px(i)}" cy="${py(s)}" r="4" class="chart-dot ${cls}" title="${history[i].timestamp?.slice(0,10)}: ${s}%"/>`;
  }).join('');

  return `<svg viewBox="0 0 ${W} ${H}" class="trend-chart" role="img" aria-label="Validation score trend">
    <style>
      .chart-grid { stroke: #e2e8f0; stroke-width: 1; }
      .chart-line { fill: none; stroke: #3b82f6; stroke-width: 2; stroke-linejoin: round; stroke-linecap: round; }
      .chart-label { fill: #64748b; font-size: 10px; font-family: system-ui, sans-serif; }
      .chart-dot { stroke: none; }
      .dot-pass { fill: #22c55e; }
      .dot-warn { fill: #f59e0b; }
      .dot-fail { fill: #ef4444; }
    </style>
    ${yTicks}
    <polyline points="${points}" class="chart-line"/>
    ${dots}
    ${labels}
    <line x1="${padLeft}" y1="${padTop}" x2="${padLeft}" y2="${padTop + chartH}" class="chart-grid"/>
  </svg>`;
}

const trendChartSvg = generateTrendChart(allBenchmarks);

// JSON syntax highlighter (regex-based, no external deps)
function highlightJson(json) {
  return json
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+-]?\d+)?)/g, match => {
      let cls = 'json-number';
      if (/^"/.test(match)) {
        cls = /:$/.test(match) ? 'json-key' : 'json-string';
      } else if (/true|false/.test(match)) {
        cls = 'json-bool';
      } else if (/null/.test(match)) {
        cls = 'json-null';
      }
      return `<span class="${cls}">${match}</span>`;
    });
}

// Escape HTML for text content
function escapeHtml(str) {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

// Build per-journey HTML sections
function buildJourneyHtml(j, idx) {
  const badgeClass = j.verdict === 'PASS' ? 'badge-pass'
    : j.verdict === 'FAIL' ? 'badge-fail'
    : 'badge-unknown';
  const verdictLabel = j.verdict || 'UNKNOWN';

  const imageGrid = j.images.length === 0 ? ''
    : `<div class="image-grid">
        ${j.images.map((img, imgIdx) => `
          <div class="thumb-wrap" onclick="openModal('modal-${idx}-${imgIdx}')">
            <img src="data:${img.mime};base64,${img.b64}" alt="${escapeHtml(img.name)}" class="thumb" loading="lazy"/>
            <div class="thumb-label">${escapeHtml(img.name)}</div>
          </div>
          <div id="modal-${idx}-${imgIdx}" class="modal" onclick="this.style.display='none'">
            <div class="modal-inner" onclick="event.stopPropagation()">
              <button class="modal-close" onclick="document.getElementById('modal-${idx}-${imgIdx}').style.display='none'">&times;</button>
              <div class="modal-zoom-wrap">
                <img src="data:${img.mime};base64,${img.b64}" alt="${escapeHtml(img.name)}" class="modal-img" id="modal-img-${idx}-${imgIdx}"/>
              </div>
              <div class="modal-name">${escapeHtml(img.name)}</div>
              <div class="zoom-controls">
                <button onclick="zoomImg('modal-img-${idx}-${imgIdx}', -0.25)">&#8722; Zoom</button>
                <button onclick="resetZoom('modal-img-${idx}-${imgIdx}')">Reset</button>
                <button onclick="zoomImg('modal-img-${idx}-${imgIdx}', 0.25)">&#43; Zoom</button>
              </div>
            </div>
          </div>
        `).join('')}
      </div>`;

  const jsonBlocks = j.jsonFiles.length === 0 ? ''
    : `<div class="json-section">
        <h4>API Responses / JSON</h4>
        ${j.jsonFiles.map(jf => `
          <details class="json-details">
            <summary class="json-summary">${escapeHtml(jf.name)}</summary>
            <pre class="json-block"><code>${highlightJson(jf.content)}</code></pre>
          </details>
        `).join('')}
      </div>`;

  const logBlocks = j.textFiles.length === 0 ? ''
    : `<div class="log-section">
        ${j.textFiles.map(tf => `
          <details class="log-details" ${tf.name.toLowerCase().includes('verdict') ? 'open' : ''}>
            <summary class="log-summary">${escapeHtml(tf.name)}</summary>
            <pre class="log-block">${escapeHtml(tf.content)}</pre>
          </details>
        `).join('')}
      </div>`;

  return `<div class="journey-card" id="journey-${idx}">
    <div class="journey-header">
      <h3 class="journey-name">${escapeHtml(j.name)}</h3>
      <span class="badge ${badgeClass}">${verdictLabel}</span>
    </div>
    <div class="journey-stats">
      <span>${j.images.length} screenshot${j.images.length !== 1 ? 's' : ''}</span>
      <span>${j.jsonFiles.length} JSON file${j.jsonFiles.length !== 1 ? 's' : ''}</span>
      <span>${j.textFiles.length} log/text file${j.textFiles.length !== 1 ? 's' : ''}</span>
    </div>
    ${imageGrid}
    ${jsonBlocks}
    ${logBlocks}
  </div>`;
}

const journeyHtml = journeys.map(buildJourneyHtml).join('\n');

// Sidebar nav
const sidebarNav = journeys.map((j, i) => {
  const cls = j.verdict === 'PASS' ? 'nav-pass' : j.verdict === 'FAIL' ? 'nav-fail' : 'nav-unknown';
  return `<a href="#journey-${i}" class="nav-link ${cls}">${escapeHtml(j.name)}</a>`;
}).join('\n');

const generatedAt = new Date().toISOString();

// Full HTML document
const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>ValidationForge Evidence Dashboard</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; }
    :root {
      --pass: #16a34a; --pass-bg: #dcfce7; --pass-border: #86efac;
      --fail: #dc2626; --fail-bg: #fee2e2; --fail-border: #fca5a5;
      --unknown-bg: #f1f5f9; --unknown-border: #cbd5e1;
      --card-bg: #ffffff; --page-bg: #f8fafc;
      --text: #1e293b; --muted: #64748b;
      --border: #e2e8f0; --radius: 8px;
      --sidebar-w: 220px;
    }
    body {
      font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: var(--page-bg); color: var(--text);
      margin: 0; padding: 0; font-size: 14px; line-height: 1.6;
    }
    a { color: #3b82f6; text-decoration: none; }
    a:hover { text-decoration: underline; }

    /* Layout */
    .layout { display: flex; min-height: 100vh; }
    .sidebar {
      width: var(--sidebar-w); flex-shrink: 0;
      background: #1e293b; color: #e2e8f0;
      padding: 20px 0; position: sticky; top: 0; height: 100vh;
      overflow-y: auto;
    }
    .sidebar-title { padding: 0 16px 16px; font-size: 12px; text-transform: uppercase;
      letter-spacing: 0.08em; color: #94a3b8; font-weight: 600; }
    .nav-link {
      display: flex; align-items: center; gap: 8px;
      padding: 8px 16px; color: #e2e8f0; font-size: 13px;
      border-left: 3px solid transparent; transition: background 0.15s;
    }
    .nav-link:hover { background: #334155; text-decoration: none; }
    .nav-link::before { content: ''; width: 8px; height: 8px;
      border-radius: 50%; flex-shrink: 0; }
    .nav-pass::before { background: #22c55e; }
    .nav-fail::before { background: #ef4444; }
    .nav-unknown::before { background: #94a3b8; }

    .main { flex: 1; padding: 24px 32px; max-width: 1100px; }

    /* Header */
    .header { margin-bottom: 28px; }
    .header h1 { font-size: 22px; font-weight: 700; margin: 0 0 4px; }
    .header-meta { color: var(--muted); font-size: 13px; }
    .overall-badge {
      display: inline-flex; align-items: center; gap: 8px;
      padding: 6px 14px; border-radius: 20px; font-weight: 700;
      font-size: 15px; margin-top: 10px;
    }
    .overall-pass { background: var(--pass-bg); color: var(--pass); border: 1px solid var(--pass-border); }
    .overall-fail { background: var(--fail-bg); color: var(--fail); border: 1px solid var(--fail-border); }
    .overall-unknown { background: var(--unknown-bg); color: var(--muted); border: 1px solid var(--unknown-border); }

    /* Summary row */
    .summary-row { display: flex; gap: 16px; margin-bottom: 28px; flex-wrap: wrap; }
    .summary-card {
      background: var(--card-bg); border: 1px solid var(--border);
      border-radius: var(--radius); padding: 16px 20px; flex: 1; min-width: 120px;
    }
    .summary-card .num { font-size: 28px; font-weight: 800; line-height: 1; }
    .summary-card .lbl { color: var(--muted); font-size: 12px; margin-top: 4px; }
    .num-pass { color: var(--pass); }
    .num-fail { color: var(--fail); }
    .num-total { color: #3b82f6; }

    /* Trend chart */
    .section { margin-bottom: 32px; }
    .section-title { font-size: 15px; font-weight: 600; margin: 0 0 12px;
      padding-bottom: 8px; border-bottom: 1px solid var(--border); }
    .trend-wrap { background: var(--card-bg); border: 1px solid var(--border);
      border-radius: var(--radius); padding: 16px; }
    .trend-chart { width: 100%; max-width: 600px; height: auto; display: block; }
    .no-history { color: var(--muted); font-style: italic; padding: 16px 0; }

    /* Journey cards */
    .journey-card {
      background: var(--card-bg); border: 1px solid var(--border);
      border-radius: var(--radius); padding: 20px; margin-bottom: 20px;
    }
    .journey-header { display: flex; align-items: center; gap: 12px; margin-bottom: 10px; }
    .journey-name { font-size: 16px; font-weight: 600; margin: 0; }
    .badge {
      display: inline-block; padding: 2px 10px; border-radius: 12px;
      font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em;
    }
    .badge-pass { background: var(--pass-bg); color: var(--pass); border: 1px solid var(--pass-border); }
    .badge-fail { background: var(--fail-bg); color: var(--fail); border: 1px solid var(--fail-border); }
    .badge-unknown { background: var(--unknown-bg); color: var(--muted); border: 1px solid var(--unknown-border); }
    .journey-stats { color: var(--muted); font-size: 12px; margin-bottom: 14px;
      display: flex; gap: 12px; }

    /* Screenshot grid */
    .image-grid { display: grid;
      grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
      gap: 12px; margin-bottom: 16px; }
    .thumb-wrap {
      cursor: pointer; border: 1px solid var(--border); border-radius: 6px;
      overflow: hidden; background: #f1f5f9;
      transition: box-shadow 0.15s, transform 0.15s;
    }
    .thumb-wrap:hover { box-shadow: 0 4px 12px rgba(0,0,0,0.12); transform: translateY(-2px); }
    .thumb { width: 100%; height: 120px; object-fit: cover; display: block; }
    .thumb-label { padding: 6px 8px; font-size: 11px; color: var(--muted);
      white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }

    /* Modal lightbox */
    .modal {
      display: none; position: fixed; inset: 0;
      background: rgba(0,0,0,0.85); z-index: 1000;
      justify-content: center; align-items: center;
    }
    .modal.open { display: flex; }
    .modal-inner {
      background: #1e293b; border-radius: 10px; padding: 16px;
      max-width: 90vw; max-height: 90vh; position: relative;
      display: flex; flex-direction: column; align-items: center; gap: 12px;
    }
    .modal-close {
      position: absolute; top: 8px; right: 12px;
      background: none; border: none; color: #e2e8f0; font-size: 22px;
      cursor: pointer; line-height: 1; padding: 4px 8px;
    }
    .modal-zoom-wrap { overflow: auto; max-width: 80vw; max-height: 70vh; }
    .modal-img { display: block; transform-origin: top left; transition: transform 0.2s; }
    .modal-name { color: #94a3b8; font-size: 12px; }
    .zoom-controls { display: flex; gap: 8px; }
    .zoom-controls button {
      background: #334155; border: 1px solid #475569; color: #e2e8f0;
      border-radius: 4px; padding: 4px 12px; cursor: pointer; font-size: 13px;
    }
    .zoom-controls button:hover { background: #475569; }

    /* JSON blocks */
    .json-section, .log-section { margin-top: 12px; }
    .json-details, .log-details { margin-bottom: 8px; }
    .json-summary, .log-summary {
      cursor: pointer; font-size: 13px; font-weight: 600;
      padding: 6px 10px; background: #f1f5f9; border-radius: 4px;
      user-select: none; list-style: none;
    }
    .json-summary::-webkit-details-marker, .log-summary::-webkit-details-marker { display: none; }
    .json-summary::before, .log-summary::before { content: '▶ '; font-size: 10px; color: var(--muted); }
    details[open] .json-summary::before, details[open] .log-summary::before { content: '▼ '; }
    .json-block, .log-block {
      font-family: 'SFMono-Regular', 'Consolas', 'Liberation Mono', monospace;
      font-size: 12px; background: #0f172a; color: #e2e8f0;
      border-radius: 0 0 4px 4px; padding: 14px 16px;
      overflow-x: auto; margin: 0; line-height: 1.5; white-space: pre-wrap;
      word-break: break-word;
    }
    /* JSON syntax colors */
    .json-key { color: #93c5fd; }
    .json-string { color: #86efac; }
    .json-number { color: #fde68a; }
    .json-bool { color: #f9a8d4; }
    .json-null { color: #94a3b8; }

    /* Responsive */
    @media (max-width: 700px) {
      .layout { flex-direction: column; }
      .sidebar { width: 100%; height: auto; position: relative;
        display: flex; flex-wrap: wrap; gap: 4px; padding: 12px; }
      .nav-link { padding: 6px 10px; border-left: none; border-radius: 4px; }
      .main { padding: 16px; }
      .image-grid { grid-template-columns: repeat(auto-fill, minmax(140px, 1fr)); }
    }
  </style>
</head>
<body>
<div class="layout">
  <nav class="sidebar">
    <div class="sidebar-title">Journeys</div>
    ${sidebarNav || '<div style="padding:8px 16px;color:#64748b;font-size:12px;">No journeys</div>'}
  </nav>
  <main class="main">
    <div class="header">
      <h1>ValidationForge Evidence Dashboard</h1>
      <div class="header-meta">
        Generated: ${generatedAt} &mdash; Evidence: <code>${escapeHtml(evidenceDir)}</code>
      </div>
      <div class="overall-badge overall-${overallVerdict.toLowerCase()}">
        Overall: ${overallVerdict}
      </div>
    </div>

    <div class="summary-row">
      <div class="summary-card">
        <div class="num num-total">${journeys.length}</div>
        <div class="lbl">Total Journeys</div>
      </div>
      <div class="summary-card">
        <div class="num num-pass">${passCount}</div>
        <div class="lbl">Passed</div>
      </div>
      <div class="summary-card">
        <div class="num num-fail">${failCount}</div>
        <div class="lbl">Failed</div>
      </div>
      <div class="summary-card">
        <div class="num" style="color:var(--muted)">${unknownCount}</div>
        <div class="lbl">Unknown</div>
      </div>
    </div>

    <div class="section">
      <div class="section-title">Validation Score Trend (last 30 runs)</div>
      <div class="trend-wrap">
        ${trendChartSvg}
      </div>
    </div>

    <div class="section">
      <div class="section-title">Journey Evidence (${journeys.length})</div>
      ${journeyHtml || '<p style="color:var(--muted)">No journeys found in evidence directory.</p>'}
    </div>
  </main>
</div>

<script>
  // Zoom state map: imgId -> scale
  var zoomState = {};

  function openModal(id) {
    var m = document.getElementById(id);
    if (m) m.style.display = 'flex';
  }

  function zoomImg(imgId, delta) {
    var img = document.getElementById(imgId);
    if (!img) return;
    var current = zoomState[imgId] || 1;
    var next = Math.min(Math.max(current + delta, 0.25), 4);
    zoomState[imgId] = next;
    img.style.transform = 'scale(' + next + ')';
    img.style.transformOrigin = 'top left';
  }

  function resetZoom(imgId) {
    zoomState[imgId] = 1;
    var img = document.getElementById(imgId);
    if (img) img.style.transform = 'scale(1)';
  }

  // Close modal on Escape key
  document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
      var modals = document.querySelectorAll('.modal');
      modals.forEach(function(m) { m.style.display = 'none'; });
    }
  });
</script>
</body>
</html>`;

// Write output file
fs.writeFileSync(outputFile, html, 'utf8');
console.log(`[generate-report] Dashboard written: ${outputFile} (${Math.round(html.length / 1024)}KB)`);

// Open in browser
function openInBrowser(file) {
  try {
    execSync(`open "${file}" 2>/dev/null`);
    console.log(`[generate-report] Opened in browser (macOS).`);
  } catch (_) {
    try {
      execSync(`xdg-open "${file}" 2>/dev/null`);
      console.log(`[generate-report] Opened in browser (Linux).`);
    } catch (__) {
      console.log(`[generate-report] Open manually: file://${path.resolve(file)}`);
    }
  }
}

openInBrowser(outputFile);
console.log('[generate-report] Done.');
process.exit(0);
