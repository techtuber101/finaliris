Public Homepage Dashboard — Behavior, Handoff, and Toggle

Overview
- The root route `/` renders a “ChatGPT-style” public dashboard shell that visually matches the logged-in dashboard but is read-only.
- Any interaction (typing, submit, starter-card click, or file drop) triggers an auth handoff. The user’s prompt is preserved and auto-submitted on `/dashboard` after login.
- If a user is already authenticated and navigates to `/`, they are server-side redirected to `/dashboard` without flashing the public UI.

Key Behaviors
- Public UI parity: Reuses the same layout, theme, and components (no style fork). Components that require auth are rendered in read-only/gated mode.
- Redirect triggers: First keypress, submit, starter-card click, and drag/drop — immediately redirect to `/auth` with `returnUrl` set to `/dashboard`.
- Prompt preservation: Preserves the full text in `localStorage` and `sessionStorage` under `pendingAgentPrompt`. Also passes a URL-safe truncated prefill via `?prefill=` on the `returnUrl`.
- Dashboard autosend: On `/dashboard`, `DashboardContent` restores the prompt from `localStorage` or `?prefill=`, auto-submits once, and cleans both the storage key and URL param.
- Cancel auth: Returning to `/auth` cancel/close leads back to `/`, where the draft is restored into the composer.
- Fast path when logged-in: `middleware.ts` performs a server-side redirect from `/` to `/dashboard`, preserving any query params.
- Legal links: The footer provides links to `/legal?tab=terms` and `/legal?tab=privacy`.

Where Things Live
- Public homepage shell: `frontend/src/app/page.tsx`
- Dashboard content (autosend logic): `frontend/src/components/dashboard/dashboard-content.tsx:1`
- Middleware (server-side redirects and route protection): `frontend/src/middleware.ts:1`
- Auth page: `frontend/src/app/auth/page.tsx:1`
- Auth callback (returns to `returnUrl`): `frontend/src/app/auth/callback/route.ts:1`

Prompt Preservation Details
- Storage key: `pendingAgentPrompt` (full text; cleared after autosend)
- URL param: `?prefill=` (truncated to 1000 chars; removed from the URL after first read)
- Sanitization: Uses `encodeURIComponent` for the `prefill`. Avoid logging prompt content in server logs.

Public Variant Constraints
- No chat/network actions run while logged out. Uploads and agent fetches are gated behind the `isLoggedIn` prop on shared components.
- The composer UI is identical; it simply triggers auth instead of sending.
- Subtle inline message appears briefly during redirect: “Sign in required — redirecting…”.

How To Toggle On/Off
- Default: The public dashboard is enabled at `/` via `frontend/src/app/page.tsx`.
- To disable and show the marketing homepage instead, replace the default export in `frontend/src/app/page.tsx` with the marketing variant component from `frontend/src/app/(home)/page.tsx` or redirect `/` to `/(home)`.
  - Example approach (manual): change `export default function HomePage()` in `frontend/src/app/page.tsx:183` to render the marketing home.
  - Server-side behavior (logged-in fast path) remains handled by `frontend/src/middleware.ts:1`.

Performance & Prefetch
- The public homepage prefetches `/auth` and `/dashboard` to speed up handoff (`router.prefetch`).
- Layout and theme are shared with dashboard to avoid style drift and reduce layout shifts.

Accessibility & SEO
- A visually hidden H1 is included for assistive tech and SEO in `frontend/src/app/page.tsx:72`.
- `/` remains crawlable; Open Graph and other meta are defined in the app layout.

Testing Checklist
- Logged-in visit to `/` redirects to `/dashboard` instantly (no flash of public UI).
- Logged-out visit to `/` shows the dashboard-lookalike page with a “Sign in” button.
- First keypress redirects to `/auth` and the draft is preserved.
- After successful auth, `/dashboard` auto-sends the preserved prompt once and cleans the URL.
- Cancel auth returns to `/` with the draft restored in the composer.

