Public Homepage Dashboard

Overview
- The root route `/` renders a public, read-only variant of the chat dashboard that visually matches the authenticated dashboard.
- Any interaction (typing, submit, starter card click, or file drop) triggers an auth redirect while preserving the prompt.
- If a user is already authenticated and visits `/`, middleware redirects them to `/dashboard` server-side to avoid UI flicker.

Prompt Preservation
- Primary: the typed prompt is saved to `localStorage` and `sessionStorage` under `pendingAgentPrompt`.
- Secondary: the prompt is also passed via a URL query param `prefill` on the auth return URL (truncated to 1000 chars).
- After successful auth, `/dashboard` reads the preserved prompt and auto-submits once, then cleans the URL.

Key Files
- `frontend/src/app/page.tsx`: Public dashboard shell with sign-in gating and prompt preservation.
- `frontend/src/components/dashboard/dashboard-content.tsx`: Enhanced to accept a `prefill` query param and auto-submit once.
- `frontend/src/middleware.ts`: Fast-path redirect from `/` to `/dashboard` when authenticated.

Behavior
- Non-logged-in visits: show full dashboard UI (same layout/theme). Chat cannot send. First interaction redirects to `/auth` with `returnUrl=/dashboard?prefill=...`.
- Logged-in visits to `/`: SSR redirect to `/dashboard` (no flicker). Any `prefill` from the URL is auto-submitted and then cleared.
- Cancelling auth: returning to `/` restores any draft from storage into the composer.

Notes
- No new style variants were introduced. Existing components are reused with read-only gating.
- File uploads are hidden in public mode and any drag/drop triggers the auth handoff.
- For A/B or flag gating, wrap the `/` page export with your feature flag check as needed.

