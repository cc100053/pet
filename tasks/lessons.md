# Lessons

## 2026-02-23
- When tightening image-size policy, always profile send latency on real upload path (pick -> compress -> invoke -> reward), not just final byte size.
- Prefer precomputing expensive transforms (compression) before user-confirmed send so reward/UI feedback stays responsive.
- Even when backend timing is unchanged, add explicit pending-state feedback near the affected HUD metric to avoid perceived freezes.
- iOS AppTrackingTransparency (ATT) prompt timing must be lifecycle-gated (`resumed`) instead of delay-based; fixed startup delays can still suppress the system prompt on newer iOS builds.
- Any SDK path that can participate in tracking (analytics/ad SDK init, ad preload, ad request) must be blocked until ATT authorization is resolved, not just the explicit ATT API call site.

## 2026-02-25
- If the user explicitly says not to modify a governance file (for example `AGENTS.md`), treat it as a hard constraint for the rest of the task and implement runtime/code fixes without further edits to that file.
- When MCP login/handshake paths are flaky, retry with project MCP tools directly (`mcp__supabase__*`) and verify real runtime behavior end-to-end (HTTP response + logs), not just job creation.

## 2026-02-28
- When normalizing tablet widths for breakpoint/scale selection, do not collapse to phone-regular width by default; use a tablet content width that preserves the expanded tier unless there is explicit evidence oversized rendering persists.
- Treat real-device iPad validation feedback as authoritative and adjust adaptive constants to match actual layout behavior, then lock with tests.
- Do not rely on viewport width alone for iPad classification; in iPhone-compat mode on iPad, use physical display traits to prevent accidental compact-tier selection.
- Keep scaling architecture consistent across related screens: avoid mixing globally scaled and locally unscaled card dimensions (or vice versa), because users immediately notice mismatched sizing between Room Selection and Pet Home gallery cards.
- When users report limited movement area, verify layout occupancy first: visual transforms (`Transform.scale`) do not free interaction space; adjust parent layout constraints (aspect ratio, gaps, padding) to increase real movement bounds.

## 2026-03-01
- For multi-step create flows, keep the progress/loading state on the page where the user confirms the action (for example `PetSelectionPage`) instead of popping early and showing loading on the previous page, to avoid disorienting context switches.
- In debug-override flows, evaluate override-specific dismiss/hide branches before normal persisted-state guards; otherwise users can get stuck with non-dismissible debug UI.
- In debug-force visibility logic, avoid combining debug and normal activation conditions with `OR`; treat debug mode as an exclusive branch so hide flags are not reactivated by normal-state predicates.

## 2026-03-04
- Use the dedicated `apply_patch` tool directly for patch edits; do not invoke `apply_patch` through `exec_command`.
- When users request a naming change on a localized item, confirm and update all locale variants for that key, not only the initially mentioned language.
- When renaming a themed item (for example moonlight -> galaxy), update both the display name key and its description key so copy stays semantically consistent.
- For chat keyboard dismiss gestures, never attach broad pointer-based dismissal logic that can start inside the composer/input hit area; restrict the start zone to a narrow band above composer so tap-to-focus cannot trigger immediate keyboard collapse.
- For focus-sensitive chat composers, avoid global `Listener`-based gesture interception for keyboard dismiss; use isolated gesture regions (for example a dedicated strip above composer) so focus and dismiss recognizers cannot race on the same tap sequence.
- If tap-outside dismissal is required, attach it to the message-list layer only (behind composer) instead of a full-screen wrapper that can overlap composer hit testing during keyboard transitions.
- In `Stack`-based chat layouts, do not conditionally insert/remove unkeyed siblings around the composer on keyboard visibility changes; this can remount `TextField` and drop focus. Keep stable keys (or stable child slots) for message list + composer across inset transitions.
- `DragUpdateDetails.delta` is per-update movement, not total drag distance; do not use a large absolute threshold there (for example `>= 6`) for keyboard dismiss triggers.
- When built-in Flutter behavior satisfies the UX (for example `ScrollViewKeyboardDismissBehavior.onDrag`), prefer it over custom gesture strips to reduce maintenance and regression surface.
- For keyboard-aware composer positioning, never let runtime keyboard inset drive bottom spacing below safe-area inset during dismiss animation; clamp with `max(viewInsets.bottom, safeAreaBottom)` to avoid end-frame down-then-up jitter.
- For keyboard-corner underlay rendering, avoid hardcoded neutral colors; source the underlay from the same active chatroom background surface color to prevent rounded-corner square-patch artifacts.
- For chatrooms using gradient/image decorations, prefer removing synthetic keyboard underlay color layers entirely; exposing the true decorated background avoids unavoidable color mismatch at keyboard rounded corners.

## 2026-03-07
- When the user asks to keep an existing primary CTA, do not duplicate that action inside onboarding chrome; add only the requested secondary control (for example `Skip`) and preserve the established interaction path through the original UI element.
- For onboarding coach cards, avoid repeating the same CTA label or step metadata inside both the card and the highlighted target. Keep the card to one short heading, one short explanation, and only the necessary secondary action.
- When users ask for concise onboarding copy, create a dedicated localization key for the coach-card title instead of reusing broader CTA strings; this keeps CTA labels stable while letting the prompt use a more conversational tone per locale.
- For Traditional Chinese product copy, default to written/formal wording unless the user explicitly asks for colloquial Cantonese phrasing.

## 2026-03-08
- In `ConsumerState`, never call `ref.read(...)` from post-frame callbacks, timers, or other async/lifecycle work that can outlive the widget; cache provider-backed services/notifiers into fields during `initState` while the widget is still mounted.
- If an initialization path needs `AppLocalizations`, `Theme`, `MediaQuery`, or any other inherited-widget data, do not start that path from `initState`; kick it off from `didChangeDependencies()` (or later) and guard it with a one-shot flag if it should run only once.
- For new Supabase columns/relationships, do not make the primary app-load query depend on a fresh PostgREST self-referential join. Keep the critical path to direct columns first, then hydrate related preview data in a best-effort follow-up query so schema-cache lag cannot blank the whole screen.
- When a debug tool is meant to replay onboarding, it must override all progression shortcuts and completeness checks, not just visibility. Start from the true first step so QA can exercise every onboarding page end-to-end.

## 2026-03-10
- For chat reply jumps to off-screen messages, do not stack package-managed lazy-list scrolling with app-side centering corrections. If the UX requires one clean jump-to-center motion, the screen must own a single scroll controller and compute the final offset itself after data is loaded.
- When a package abstracts list virtualization and scroll positioning too aggressively, treat that as an architectural boundary issue instead of tuning durations/curves. Keep the package for rendering/providers if useful, but reclaim list ownership before shipping more scroll-behavior patches.
- For Telegram-style chat keyboard dismiss, composer-local drag handlers are not enough: if the swipe may start in the message list and finish over the composer, track pointer movement at the route layer and key the dismiss logic to the composer bounds plus a protected text-input region.
- For sweep-into-composer keyboard dismissal, do not dismiss on first contact with the composer edge. Record the entry point into the composer zone and require additional downward travel from that entry point so reversing direction before the threshold cleanly cancels the dismiss.
