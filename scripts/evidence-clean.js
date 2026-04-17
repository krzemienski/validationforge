#!/usr/bin/env node
/**
 * evidence-clean.js — Evidence retention enforcement for ValidationForge.
 *
 * Reads evidence_retention_days from config (precedence order below), then
 * removes evidence directories whose mtime is older than the retention window.
 *
 * Config precedence (highest → lowest):
 *   1. $VF_CONFIG_FILE env var
 *   2. $HOME/.claude/.vf-config.json
 *   3. ./.vf-config.json (CWD)
 *   4. ./config/standard.json (repo fallback)
 *
 * Usage:
 *   node scripts/evidence-clean.js [--dry-run]
 *
 * Environment:
 *   VF_EVIDENCE_ROOT  — override evidence root dir (default: ./e2e-evidence)
 *   VF_CONFIG_FILE    — override config file path
 *
 * Lock protocol:
 *   If .vf/state/validation-in-progress.lock exists:
 *     - Parse pid= and started= lines.
 *     - If PID is live (process.kill(pid,0) succeeds) → exit 1, stderr contains
 *       literal "validation in progress". No files removed.
 *     - If PID dead AND started > 1h ago → WARN to stderr and cleanup.log, proceed.
 *     - If PID dead but started <= 1h ago → treat conservatively as live; exit 1.
 *
 * Cleanup log format (appended to <evidence_root>/cleanup.log):
 *   <ISO-8601-UTC> | <absolute-path> | <mtime-ISO-8601-UTC> | deleted|skipped|dry-run
 */

'use strict';

const fs   = require('fs');
const path = require('path');
const os   = require('os');

// ── CLI flags ─────────────────────────────────────────────────────────────────
const args    = process.argv.slice(2);
const DRY_RUN = args.includes('--dry-run');

// ── Evidence root ─────────────────────────────────────────────────────────────
const evidenceRoot = path.resolve(
  process.env.VF_EVIDENCE_ROOT || path.join(process.cwd(), 'e2e-evidence')
);

// ── Config resolution — captured ONCE at script start ─────────────────────────
function readJsonSafe(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch {
    return null;
  }
}

function resolveRetentionDays() {
  const candidates = [];

  if (process.env.VF_CONFIG_FILE) {
    candidates.push(process.env.VF_CONFIG_FILE);
  }
  candidates.push(path.join(os.homedir(), '.claude', '.vf-config.json'));
  candidates.push(path.join(process.cwd(), '.vf-config.json'));
  candidates.push(path.join(process.cwd(), 'config', 'standard.json'));

  for (const candidate of candidates) {
    const data = readJsonSafe(candidate);
    if (data && typeof data.evidence_retention_days === 'number' && data.evidence_retention_days > 0) {
      return { days: data.evidence_retention_days, source: candidate };
    }
  }
  return { days: 30, source: 'built-in default' };
}

const { days: RETENTION_DAYS, source: configSource } = resolveRetentionDays();

// ── Audit log helpers ─────────────────────────────────────────────────────────
function isoNow() {
  return new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');
}

function appendCleanupLog(rootDir, line) {
  try {
    if (!fs.existsSync(rootDir)) {
      fs.mkdirSync(rootDir, { recursive: true });
    }
    fs.appendFileSync(path.join(rootDir, 'cleanup.log'), line + '\n');
  } catch (err) {
    process.stderr.write(`[evidence-clean] WARN: could not write cleanup.log: ${err.message}\n`);
  }
}

function logEntry(absPath, mtime, action) {
  const ts       = isoNow();
  const mtimeIso = mtime.toISOString().replace(/\.\d{3}Z$/, 'Z');
  return `${ts} | ${absPath} | ${mtimeIso} | ${action}`;
}

// ── Lock file check ───────────────────────────────────────────────────────────
const LOCK_FILE   = path.join(process.cwd(), '.vf', 'state', 'validation-in-progress.lock');
const ONE_HOUR_MS = 60 * 60 * 1000;

function parseLock(lockPath) {
  try {
    const content   = fs.readFileSync(lockPath, 'utf8');
    const pidMatch  = content.match(/^pid=(\d+)/m);
    const timeMatch = content.match(/^started=(.+)/m);
    const pid       = pidMatch ? parseInt(pidMatch[1], 10) : null;
    const started   = timeMatch ? new Date(timeMatch[1].trim()) : null;
    return { pid, started };
  } catch {
    return { pid: null, started: null };
  }
}

function isPidLive(pid) {
  if (!pid || !Number.isFinite(pid)) return false;
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
}

if (fs.existsSync(LOCK_FILE)) {
  const { pid, started } = parseLock(LOCK_FILE);
  const live  = isPidLive(pid);
  const ageMs = started ? (Date.now() - started.getTime()) : 0;

  if (live) {
    process.stderr.write(
      `[evidence-clean] validation in progress (pid=${pid} is live). Aborting cleanup.\n`
    );
    process.exit(1);
  }

  if (ageMs > ONE_HOUR_MS) {
    const warnMsg = `WARN: stale lock ignored (pid=${pid}, age=${Math.round(ageMs / 60000)}min)`;
    process.stderr.write(`[evidence-clean] ${warnMsg}\n`);
    appendCleanupLog(evidenceRoot, `${isoNow()} | ${LOCK_FILE} | - | ${warnMsg}`);
  } else {
    // Dead PID but lock is recent — conservatively treat as in-progress
    process.stderr.write(
      `[evidence-clean] validation in progress (pid=${pid} recently started lock, treating as live). Aborting cleanup.\n`
    );
    process.exit(1);
  }
}

// ── Guard: evidence root must exist ──────────────────────────────────────────
if (!fs.existsSync(evidenceRoot)) {
  process.stdout.write(
    `[evidence-clean] evidence root does not exist: ${evidenceRoot} — nothing to clean.\n`
  );
  process.exit(0);
}

process.stdout.write(
  `[evidence-clean] retention=${RETENTION_DAYS}d (from ${path.basename(configSource)}) | root=${evidenceRoot} | dry-run=${DRY_RUN}\n`
);

// ── Scan one level deep ───────────────────────────────────────────────────────
let entries;
try {
  entries = fs.readdirSync(evidenceRoot, { withFileTypes: true });
} catch (err) {
  process.stderr.write(`[evidence-clean] ERROR: cannot read evidence root: ${err.message}\n`);
  process.exit(1);
}

const dirs      = entries.filter(e => e.isDirectory());
const cutoffMs  = Date.now() - RETENTION_DAYS * 24 * 60 * 60 * 1000;
let removedCount = 0;
let skippedCount = 0;

for (const dirent of dirs) {
  const absPath = path.join(evidenceRoot, dirent.name);
  let stat;

  try {
    stat = fs.statSync(absPath);
  } catch (err) {
    process.stderr.write(`[evidence-clean] WARN: cannot stat ${absPath}: ${err.message}\n`);
    continue;
  }

  const mtime = stat.mtime;

  if (mtime.getTime() < cutoffMs) {
    const action = DRY_RUN ? 'dry-run' : 'deleted';
    appendCleanupLog(evidenceRoot, logEntry(absPath, mtime, action));

    if (DRY_RUN) {
      process.stdout.write(
        `[evidence-clean] DRY-RUN would delete: ${absPath} (mtime=${mtime.toISOString()})\n`
      );
    } else {
      try {
        fs.rmSync(absPath, { recursive: true, force: true });
        process.stdout.write(
          `[evidence-clean] deleted: ${absPath} (mtime=${mtime.toISOString()})\n`
        );
        removedCount++;
      } catch (err) {
        process.stderr.write(`[evidence-clean] ERROR deleting ${absPath}: ${err.message}\n`);
        appendCleanupLog(evidenceRoot, logEntry(absPath, mtime, 'error'));
      }
    }
  } else {
    appendCleanupLog(evidenceRoot, logEntry(absPath, mtime, 'skipped'));
    skippedCount++;
  }
}

// ── Summary ───────────────────────────────────────────────────────────────────
const summary = DRY_RUN
  ? `dry-run complete. ${dirs.length} dir(s) scanned, ${dirs.length - skippedCount} eligible for removal.`
  : `done. removed=${removedCount} skipped=${skippedCount}`;

process.stdout.write(`[evidence-clean] ${summary}\n`);
appendCleanupLog(evidenceRoot, `${isoNow()} | SUMMARY | - | ${summary}`);
