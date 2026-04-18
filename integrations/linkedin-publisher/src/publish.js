// Publish a post to LinkedIn on the authenticated member's behalf.
// Uses the current Posts API: POST https://api.linkedin.com/rest/posts
// Scaffold; requires valid LINKEDIN_ACCESS_TOKEN + LINKEDIN_PERSON_URN.

const POSTS_URL = 'https://api.linkedin.com/rest/posts';

/**
 * @param {object} args
 * @param {string} args.accessToken         OAuth bearer token
 * @param {string} args.personUrn           urn:li:person:{id}
 * @param {string} args.text                Post body (LinkedIn auto-renders URLs/hashtags)
 * @param {string[]} [args.mediaIds]        Asset URNs from upload-media.js
 * @param {string} [args.apiVersion]        e.g. "202504"
 * @param {boolean} [args.dryRun]           If true, returns the request body without posting
 */
export async function publishPost({
  accessToken,
  personUrn,
  text,
  mediaIds = [],
  apiVersion = process.env.LINKEDIN_API_VERSION || '202604',
  dryRun = false,
}) {
  if (!accessToken) throw new Error('accessToken required');
  if (!personUrn) throw new Error('personUrn required');
  if (!text || !text.trim()) throw new Error('text required');

  const body = {
    author: personUrn,
    commentary: text,
    visibility: 'PUBLIC',
    distribution: {
      feedDistribution: 'MAIN_FEED',
      targetEntities: [],
      thirdPartyDistributionChannels: [],
    },
    lifecycleState: 'PUBLISHED',
    isReshareDisabledByAuthor: false,
  };

  if (mediaIds.length === 1) {
    body.content = {
      media: {
        id: mediaIds[0],
      },
    };
  } else if (mediaIds.length > 1) {
    body.content = {
      multiImage: {
        images: mediaIds.map((id) => ({ id })),
      },
    };
  }

  if (dryRun) {
    return { dryRun: true, request: body };
  }

  const res = await fetch(POSTS_URL, {
    method: 'POST',
    headers: {
      authorization: `Bearer ${accessToken}`,
      'content-type': 'application/json',
      'LinkedIn-Version': apiVersion,
      'X-Restli-Protocol-Version': '2.0.0',
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`publish failed: ${res.status} ${errText}`);
  }

  // LinkedIn returns the new post URN in the X-RestLi-Id header
  const postUrn = res.headers.get('x-restli-id') || res.headers.get('X-RestLi-Id');
  return { postUrn, status: res.status };
}
