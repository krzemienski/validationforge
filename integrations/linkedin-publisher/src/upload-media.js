// Upload an image to LinkedIn so it can be referenced in a post.
// Two-step flow: registerUpload -> PUT binary -> use returned asset URN.
// Scaffold; requires valid LINKEDIN_ACCESS_TOKEN + personUrn.

import { promises as fs } from 'node:fs';
import path from 'node:path';

const REGISTER_URL = 'https://api.linkedin.com/v2/assets?action=registerUpload';

/**
 * @param {object} args
 * @param {string} args.accessToken
 * @param {string} args.personUrn        owner of the asset
 * @param {string} args.filePath         absolute path to image (PNG/JPG, <10MB)
 * @returns {Promise<string>} asset URN to reference in publishPost mediaIds
 */
export async function uploadImage({ accessToken, personUrn, filePath }) {
  if (!accessToken) throw new Error('accessToken required');
  if (!personUrn) throw new Error('personUrn required');
  if (!filePath) throw new Error('filePath required');

  const absPath = path.resolve(filePath);
  const stat = await fs.stat(absPath);
  if (!stat.isFile()) throw new Error(`not a file: ${absPath}`);
  if (stat.size > 10 * 1024 * 1024) throw new Error('image >10MB; LinkedIn limit');

  // Step 1: register upload
  const regRes = await fetch(REGISTER_URL, {
    method: 'POST',
    headers: {
      authorization: `Bearer ${accessToken}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      registerUploadRequest: {
        recipes: ['urn:li:digitalmediaRecipe:feedshare-image'],
        owner: personUrn,
        serviceRelationships: [
          {
            relationshipType: 'OWNER',
            identifier: 'urn:li:userGeneratedContent',
          },
        ],
      },
    }),
  });

  if (!regRes.ok) {
    throw new Error(`registerUpload failed: ${regRes.status} ${await regRes.text()}`);
  }

  const reg = await regRes.json();
  const uploadUrl = reg?.value?.uploadMechanism?.['com.linkedin.digitalmedia.uploading.MediaUploadHttpRequest']?.uploadUrl;
  const assetUrn = reg?.value?.asset;

  if (!uploadUrl || !assetUrn) {
    throw new Error('registerUpload response missing uploadUrl/asset');
  }

  // Step 2: PUT binary
  const buf = await fs.readFile(absPath);
  const putRes = await fetch(uploadUrl, {
    method: 'PUT',
    headers: {
      authorization: `Bearer ${accessToken}`,
      'content-type': 'application/octet-stream',
    },
    body: buf,
  });

  if (!putRes.ok) {
    throw new Error(`binary upload failed: ${putRes.status} ${await putRes.text()}`);
  }

  return assetUrn;
}
