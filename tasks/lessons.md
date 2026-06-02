# Lessons

## 2026-04-22
- When a user names the ship target release for a feature, align every rollout gate to that exact version: repo app version, seeded `min_app_version`, compatibility checks, and user-facing release notes or task notes.

## 2026-04-18
- **Brand Spelling:** The product name is `PetTomo`, with a capital `T` and one
  `t` after `Pe`. Do not add extra letters in user-facing copy, tests, fallback
  pages, or task notes.
- **Paired CTA Labels:** In side-by-side mobile buttons, keep action labels
  short across every locale. Prefer verb-only labels like `Copy`/`Share` when
  surrounding UI already explains the object.
- **Shared Flow Entry Points:** When restoring a user-facing flow that exists in Profile and onboarding, check every entry point before finishing. The correct avatar upload path is pick -> adjust -> save/upload for both existing users and new-user setup, not just the Profile menu.
- **Localization File Handling:** For small localization files (like `.strings` or `.arb`), prefer using `write_file` to overwrite the entire content instead of multiple `replace` calls. This prevents "ghost" content or duplicate entries caused by overlapping matches.
- **Strings File Integrity:** App Store Connect `.strings` files are extremely sensitive to trailing content and unclosed quotes. Always verify the file ends exactly after the last semicolon and that no partial strings from previous versions remain at the bottom.
- **Catalog Entry Point:** When adding a new "What's New" version, ensure the entry is added to BOTH the `entries` list at the top AND the builder methods at the bottom of `app_whats_new_catalog.dart`. Missing either will lead to unused elements or missing UI.

## 2026-04-15
- When the user corrects a rollout/version assumption, treat the explicit
  version as product intent and update the task plan before implementation; do
  not keep using "next version" as a default if the current released version is
  named.
- Do not run multiple `flutter test` commands in parallel in this repo. The
  Flutter tool writes shared `build/unit_test_assets` shader outputs and can
  crash with `ShaderCompilerException`; run Flutter tests sequentially.
- Even for small focused checks, never use `multi_tool_use.parallel` with
  `flutter test`. Use one `flutter test` invocation with multiple test files,
  or run separate invocations one after another.
- Do not feed `TweenSequence` with an overshooting curve such as
  `Curves.easeOutBack`; it can output `t > 1.0` and trip Flutter's
  `t >= 0.0 && t <= 1.0` assertion.
- For Shop consumables that grant an existing currency balance, trigger the SFX
  from the purchase-success path. A passive balance-chip rebuild can animate
  while the sound call is too indirect or easy to miss.

## 2026-04-04
- Do not bind a precision multi-touch action directly to a tiny object in the scene. If the target can be smaller than comfortable touch size, move the adjustment onto a large dedicated control surface and keep direct manipulation for single-finger drag/select only.
- For full-screen blur overlays, do not rely only on route-level child fade/scale. Animate the blur sigma and scrim opacity themselves, or the background still appears to snap abruptly between sharp and blurred states.
- For chat long-press overlays, “has fade” is not the same as “feels soft.” Tune transition duration, intervals, and travel distance together; slightly longer timing with smaller motion reads calmer than a fast fade plus large offsets.
- When a rollout includes free compatibility-only backgrounds, hide them from the Shop catalog explicitly instead of relying on `0` pricing; otherwise they surface as user-facing store items even though they are meant to be silently granted.
- After renaming asset files to fix typos, verify both the registry file and every preview surface that resolves those assets. Background bugs can look like “preview component broken” when the real issue is a stale asset path feeding the shared preview widget.
- When Flutter assets live inside nested subfolders, do not assume declaring the parent directory in `pubspec.yaml` is enough. Verify the generated `build/flutter_assets` output; if nested files are missing, list each subdirectory explicitly in `pubspec.yaml`.
- When extending a store rollout from active items to version-gated items, update every enforcement layer together: catalog RPC, purchase RPCs, and any table RLS policies they write through. Fixing only one layer just moves the failure from validation to authorization.
- For Godot editor APIs, do not infer return values from method names. Check the actual Godot version signature before assigning a call result; `EditorInterface.open_scene_from_path()` returns `void` in Godot 4.6, so assigning it creates a GDScript parse error that prevents the whole add-on from loading.
- For preview tools with optional overlays, keep base playback independent from overlay availability. A "clear equipment" state should remove only the equipment sprite, not block the underlying pet sequence timer.

## 2026-04-03
- When product compatibility rules are defined for shared room content, apply them to every shared visual state type, not just shop-backed decor. Pets need the same version-gated visibility, old-client fallback, and update-prompt path as backgrounds and furniture.

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
- When replacing a package-managed chat list with a custom deterministic list, explicitly re-add any list-level affordances the package used to provide, especially long-press action hooks and jump-to-latest controls.
- For Telegram-style chat keyboard dismiss, composer-local drag handlers are not enough: if the swipe may start in the message list and finish over the composer, track pointer movement at the route layer and key the dismiss logic to the composer bounds plus a protected text-input region.
- For sweep-into-composer keyboard dismissal, do not dismiss on first contact with the composer edge. Record the entry point into the composer zone and require additional downward travel from that entry point so reversing direction before the threshold cleanly cancels the dismiss.
- For keyboard-collapse animation in chat, never let the active bottom inset fall below the route safe-area inset during dismiss. Clamp `viewInsets.bottom` with the safe-area bottom and use one shared helper for both list padding and composer bottom offset to avoid the final downward dip / rebound.
- For dynamically measured chat composers, do not schedule post-frame height measurement from every build. Measure on real content changes only (text wrap/input growth, reply-preview presence changes, theme/layout-affecting props) or keyboard animation will create top-edge jitter even when bottom inset math is already fixed.

## 2026-03-13
- Before any mutating Supabase MCP call (`apply_migration`, `execute_sql`, function deploys), verify the current MCP project URL/ref against the repo's intended project (`.env`, known project ref, or explicit user confirmation). If they do not match, stop and resolve the target first.

## 2026-03-15
- For reply composers and other multi-line text inputs, keep the platform-default keyboard action (`newline`) unless the user explicitly asks for a custom IME action; do not override it to `send`.
- When a user asks to reduce success-toast intrusion inside media viewers, prefer inline control-level success feedback (for example a temporary `Sent` state on the initiating button) over bottom snackbars.
- For Supabase RPC/schema tracing, do not infer the live behavior from the first matching migration found by `rg`; first identify the latest applied migration that rewrites the relevant function/object on the target project, then confirm against current schema/memory notes before stating the rule.
- When a user distinguishes a feature’s own UI from the gate/controller that triggers it, move the presentation into the feature module and keep orchestration code thin.
- When changing visual order inside a shared wrapper component, inspect the wrapper’s own layout before claiming the UI moved; reordering children inside a body slot cannot override a wrapper that renders its own header first.
- For compact announcement modals, avoid `Expanded`-driven vertical fill unless the product explicitly wants a tall sheet; content-driven sizing plus a bounded outer scroll is usually the correct default and prevents large dead zones under short bullet lists.

## 2026-03-17
- For media viewers and other layout-sensitive surfaces, do not use decode/provider changes as a first-line memory fix unless the rendered output is verified on-device; keep the UI path unchanged and prefer cache-level or non-visual memory guards first.
- For shared thumbnail components, do not wrap the displayed provider in an exact-size resize layer just because cache bounds were added; keep cache sizing and rendered-provider semantics separate or image aspect/presentation can drift across multiple surfaces at once.

## 2026-03-19
- When the user asks to adjust chat avatar "height" or "high/low" only, do not reinterpret that as changing the avatar’s anchor semantics in the message-group layout; preserve whether the icon belongs to the last message and limit the change to vertical offset/alignment within that existing anchor rule.

## 2026-03-21
- When reviewing a regression list and the user narrows the requested fixes, immediately rescope the implementation to the explicitly accepted items instead of restoring every previous behavior by default.
- For store/economy UX, treat the purchase interaction model itself as product intent: if the user explicitly wants a single buy action, keep that constraint and fix surrounding regressions without reintroducing multi-button currency choice.

## 2026-03-23
- For chat keyboard/scroll fixes, do not rely only on synthetic inset-only widget tests. Reproduce the real interaction path too: focus the composer, open the keyboard, and verify viewport preservation from the actual user gesture flow.
- For explicit “jump to latest” UX, avoid combining an immediate animated scroll with mandatory post-frame correction jumps. Let layout settle first, animate once to the final target, and defer minor latest corrections until that animation has finished.
- In bounded-window chat histories, do not collapse the visible dataset to the newest page before starting a `Latest` animation. That shrinks scroll extent first and produces the exact down-then-up jitter users notice. Transition through a merged window, then trim to the latest page after the animation settles.
- When preserving reading position through keyboard/composer size changes, do not anchor to a message's top edge. Preserve a concrete point inside the message at the viewport reading line, or the background will resize while the perceived content focus drifts.
- For post-action Home coaching on a dense HUD, default to a floating title-only hint anchored to the target control instead of an inline help card; inline guidance that pushes surrounding UI reads as layout breakage immediately.

## 2026-03-24
- When a user pushes back on a chat-order review, separate the UX choice (`reverse` list to keep newest at bottom) from the actual invariant bug. The high-signal question is whether every layer shares the same canonical message/index contract, not whether `reverse` exists at all.

## 2026-03-26
- For overlay controls inside small `Stack` children, do not reach for `OverflowBox` blindly. If the parent axis is unbounded, `OverflowBox` can receive infinite size and crash; prefer explicit overlay width plus negative offset positioning so the child can extend beyond the item without unconstrained layout.
- When a control is painted outside a small draggable item's bounds with `clipBehavior: Clip.none`, do not assume it remains tappable. Visual overflow does not extend the parent's hit-test region; move interactive overlays to a larger ancestor layer or expand the actual widget bounds.
- In a `Stack`, even a harmless-looking `SizedBox.shrink()` counts as a non-positioned child and can collapse the stack's layout size. For overlay helpers that may have no content, do not return a zero-size widget into the stack; conditionally omit the child entirely.
- Entering an edit mode should reset transient selection state unless preserving the previous selection is an explicit product decision; otherwise stale selection UI can appear immediately and read like the whole surface auto-selected itself.
- When the interaction model changes from explicit controls to gestures, remove the old affordance path entirely and update every localized hint string in the same pass; leaving both behind creates contradictory UX and stale memory/docs.
- When a user asks for a new details surface to be separate from an existing long-press sheet, do not merge them into one “improved” modal even if the functionality overlaps. Preserve the original surface and add the new one on its own trigger path.

## 2026-04-03
- For new shared room decor (backgrounds/furniture), do not activate the catalog rows globally by default. Treat them as mixed-version compatibility work: gate Shop visibility by app version, add client-side fallback rendering for unsupported shared state, and prompt unsupported clients to update when the room is using newer decor.

## 2026-05-22
- For App Store submissions with auto-renewable subscriptions, treat the direct Apple Standard EULA link in version metadata as a release-blocking invariant. Keep the URL footer in every `.asc/version-localizations/*.strings` description and verify it with `test/app_store_metadata_terms_test.dart` before uploading metadata.

## 2026-06-02
- When decomposing god files via the `part`/`part of` extension idiom: (1)
  extensions cannot call `State.setState` directly (warns
  `invalid_use_of_protected_member`) — route through a plain
  `_setStateForXxx(VoidCallback)` wrapper on the State class, matching the
  existing convention; (2) references to `static` members of the extended
  class must be qualified (`_HomeViewState._foo`); (3) several tests are
  source-introspection tests (`File('.../home_view.dart').readAsStringSync()`)
  that assert symbol LOCATION, so moving code to a new part file breaks them —
  update the test to also read the new part file (same library, behavior
  unchanged). Always `flutter analyze` + `flutter test` after each extraction.
- Part files in a SUBDIRECTORY must use a relative `part of '../parent.dart';`
  directive (not `part of 'parent.dart';`). A wrong path yields
  `part_of_different_library` which cascades into hundreds of bogus
  "undefined Widget/Colors/..." errors. NOTE: `flutter analyze <partfile>`
  alone is misleading (a part has no imports of its own) — always analyze the
  whole project.
