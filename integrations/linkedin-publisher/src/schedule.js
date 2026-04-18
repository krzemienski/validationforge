// Cron-like queue runner. Reads linkedin-queue.json, publishes due items.
// Idempotent: items marked "published" are skipped.
// Phase-01 (260418-1036): added list/peek/next subcommands + 401 retry.

import { promises as fs } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { getValidAccessToken, refreshAccessToken } from './auth.js';
import { publishPost } from './publish.js';
import { uploadImage } from './upload-media.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const QUEUE_PATH = path.resolve(__dirname, '..', 'linkedin-queue.json');

async function readQueue() {
  try {
    const raw = await fs.readFile(QUEUE_PATH, 'utf8');
    return JSON.parse(raw);
  } catch (err) {
    if (err.code === 'ENOENT') return { items: [] };
    throw err;
  }
}

async function writeQueue(queue) {
  await fs.writeFile(QUEUE_PATH, JSON.stringify(queue, null, 2) + '\n', 'utf8');
}

export async function addToQueue({ id, markdownPath, mediaPath, scheduledAt }) {
  const queue = await readQueue();
  if (!Array.isArray(queue.items)) queue.items = [];
  if (queue.items.find((i) => i.id === id)) {
    throw new Error(`queue already has id=${id}`);
  }
  queue.items.push({
    id,
    markdown_path: markdownPath,
    media_path: mediaPath || null,
    scheduled_at: scheduledAt,
    status: 'queued',
  });
  await writeQueue(queue);
  return queue;
}

// List all items grouped by status. Used by `lp queue list`.
export async function listQueue() {
  const queue = await readQueue();
  const items = queue.items || [];
  const buckets = { queued: [], published: [], failed: [], 'dry-run': [] };
  for (const it of items) (buckets[it.status] ||= []).push(it);
  return { total: items.length, buckets };
}

// Peek at the next due item without publishing. Used by `lp queue peek`.
export async function peekQueue({ now = new Date() } = {}) {
  const queue = await readQueue();
  const queued = (queue.items || []).filter((i) => i.status === 'queued');
  if (!queued.length) return null;
  queued.sort((a, b) => new Date(a.scheduled_at) - new Date(b.scheduled_at));
  const head = queued[0];
  const headTime = new Date(head.scheduled_at);
  return {
    item: head,
    is_due: headTime <= now,
    fires_in_ms: headTime - now,
  };
}

async function loadMarkdown(mdPath) {
  const abs = path.resolve(__dirname, '..', mdPath);
  const raw = await fs.readFile(abs, 'utf8');
  // Strip leading frontmatter if present
  const stripped = raw.replace(/^---\n[\s\S]*?\n---\n/, '');
  return stripped.trim();
}

// Publish one item: upload media if present, POST /rest/posts, retry once on 401.
async function publishOne(item, { accessToken, personUrn, dryRun }) {
  const text = await loadMarkdown(item.markdown_path);
  let mediaIds = [];
  if (item.media_path) {
    const absMedia = path.resolve(__dirname, '..', item.media_path);
    const assetUrn = await uploadImage({
      accessToken,
      personUrn,
      filePath: absMedia,
    });
    mediaIds = [assetUrn];
  }

  try {
    return {
      accessToken,
      result: await publishPost({ accessToken, personUrn, text, mediaIds, dryRun }),
    };
  } catch (err) {
    // 401: token revoked/expired since auth check. Refresh + retry once.
    if (/publish failed: 401/.test(err.message)) {
      console.log('   401 detected — refreshing access token and retrying...');
      const refreshed = await refreshAccessToken();
      return {
        accessToken: refreshed,
        result: await publishPost({
          accessToken: refreshed, personUrn, text, mediaIds, dryRun,
        }),
      };
    }
    throw err;
  }
}

export async function runQueue({ now = new Date(), dryRun = false } = {}) {
  const queue = await readQueue();
  if (!queue.items?.length) {
    console.log('queue empty');
    return { processed: 0 };
  }

  const due = queue.items.filter(
    (i) => i.status === 'queued' && new Date(i.scheduled_at) <= now,
  );
  if (!due.length) {
    console.log('no items due');
    return { processed: 0 };
  }

  let processed = 0;
  let accessToken;
  const personUrn = process.env.LINKEDIN_PERSON_URN;

  for (const item of due) {
    try {
      console.log(`-> processing ${item.id}`);
      if (!accessToken) accessToken = await getValidAccessToken();

      const { accessToken: usedToken, result } = await publishOne(item, {
        accessToken, personUrn, dryRun,
      });
      accessToken = usedToken;

      item.status = dryRun ? 'dry-run' : 'published';
      item.published_at = new Date().toISOString();
      item.post_urn = result.postUrn || null;
      processed += 1;
      console.log(`   ${item.status}: ${result.postUrn || '(dry-run)'}`);
    } catch (err) {
      console.error(`   failed: ${err.message}`);
      item.status = 'failed';
      item.error = err.message;
      item.failed_at = new Date().toISOString();
    }
  }

  await writeQueue(queue);
  return { processed };
}

// Alias matching phase-01 spec: `lp queue next` = "publish anything due now."
export const nextQueue = runQueue;
