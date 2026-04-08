# ValidationForge Demo: The Bug Unit Tests Can't Catch

## The Scenario

A Next.js dashboard app has a user list page that fetches from `/api/users`. A developer makes a "simple" change: renaming the API response field from `users` to `data` for consistency.

## The Code Change

**Before (working):**
```typescript
// app/api/users/route.ts
export async function GET() {
  const users = await db.query("SELECT * FROM users");
  return Response.json({ users });  // ← returns { users: [...] }
}
```

**After (broken):**
```typescript
// app/api/users/route.ts
export async function GET() {
  const users = await db.query("SELECT * FROM users");
  return Response.json({ data: users });  // ← returns { data: [...] }
}
```

**Frontend (unchanged, still reads `.users`):**
```typescript
// app/dashboard/page.tsx
export default async function Dashboard() {
  const res = await fetch("/api/users");
  const json = await res.json();
  const users = json.users;  // ← still reads .users (now undefined!)
  return (
    <div>
      <h1>Users ({users.length})</h1>  {/* ← TypeError: Cannot read property 'length' of undefined */}
      {users.map(u => <UserCard key={u.id} user={u} />)}
    </div>
  );
}
```

## What Unit Tests See

```
✓ GET /api/users returns 200 (3ms)
✓ GET /api/users returns array of users (5ms)
✓ UserCard renders user name (2ms)
✓ Dashboard component renders heading (4ms)

4 passing (14ms)
```

**All tests pass.** Why?

1. The API test mocks the database and checks `response.status === 200` ✓
2. The API test checks `response.body.data` exists (updated with the rename) ✓
3. The UserCard test passes mock user props directly ✓
4. The Dashboard test mocks the fetch response with the old format ✓

The mock in the Dashboard test still returns `{ users: [...] }` because nobody updated the mock when the API changed. Tests pass. App crashes.

## What ValidationForge Catches

### Step 1: Preflight
```
✓ Dev server running (http://localhost:3000, 200 OK)
✓ Database seeded (5 users)
✓ Browser automation available
✓ Evidence directory created
```

### Step 2: API Validation (Bottom-Up)
```bash
$ curl -s http://localhost:3000/api/users | tee e2e-evidence/api-users.json | jq .
{
  "data": [
    { "id": 1, "name": "Alice", "email": "alice@example.com" },
    { "id": 2, "name": "Bob", "email": "bob@example.com" },
    ...
  ]
}
```

**Verdict:** API returns `{ data: [...] }` — valid JSON, 200 OK. **PASS**

### Step 3: Web Validation
Navigate to `http://localhost:3000/dashboard` via Playwright:

```
Screenshot: e2e-evidence/web-dashboard.png
Console: TypeError: Cannot read properties of undefined (reading 'length')
         at Dashboard (app/dashboard/page.tsx:6:32)
```

**Screenshot shows:** Blank white page with React error overlay:
"Unhandled Runtime Error — TypeError: Cannot read properties of undefined (reading 'length')"

**Verdict:** Dashboard crashes on load. **FAIL**

### Step 4: Root Cause
```
API returns:     { data: [...] }
Frontend reads:  json.users      → undefined
                 undefined.length → TypeError
```

The API renamed `users` to `data` but the frontend wasn't updated.

### Step 5: Fix
```typescript
// app/dashboard/page.tsx — line 4
- const users = json.users;
+ const users = json.data;
```

### Step 6: Re-validate
Navigate to dashboard again:

```
Screenshot: e2e-evidence/web-dashboard-fixed.png
Console: No errors
```

**Screenshot shows:** "Users (5)" heading with 5 UserCard components rendered.

**Verdict:** Dashboard renders correctly with 5 users. **PASS**

## The Scorecard

| Check | Unit Tests | ValidationForge |
|-------|-----------|----------------|
| API returns 200 | ✓ PASS | ✓ PASS |
| API returns user data | ✓ PASS (reads `.data`) | ✓ PASS (reads `.data`) |
| Frontend renders users | ✓ PASS (mocked fetch) | ✗ FAIL (real fetch → crash) |
| End-to-end works | Not tested | ✗ FAIL → fix → ✓ PASS |

**Unit tests: 4/4 passing. App: broken.**
**ValidationForge: caught the bug in 30 seconds.**

## Why This Happens in Real Projects

This isn't a contrived example. This exact pattern — API change + stale mock — is the #1 cause of "but tests were green!" production incidents. It happens because:

1. **Mocks drift from reality.** The moment you mock an API response, you're testing against a snapshot of how the API *used to* work, not how it works *now*.

2. **Integration boundaries are invisible to unit tests.** Each component works perfectly in isolation. The bug exists only at the boundary between API and frontend.

3. **Developers update the code but not the mocks.** The developer who renamed `users` to `data` updated the API test mock but forgot the Dashboard test mock. This is human nature, not negligence.

4. **ValidationForge validates through the same interfaces users use.** It calls the real API, renders the real frontend, and sees the same crash the user would see.

## Try It Yourself

```bash
# Install ValidationForge
git clone https://github.com/krzemienski/validationforge ~/.claude/plugins/validationforge

# In any fullstack project:
/validate
```

ValidationForge will detect the platform, build a validation plan, execute it through real interfaces, and tell you exactly what's broken — with evidence.
