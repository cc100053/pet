# AI Collaboration Workflow

This repo has production users and server-side behavior that affects old app
versions immediately. Treat AI agents as implementation partners that must work
inside explicit compatibility guardrails, not as one-shot bug fixers.

## When This Is Required

Read and follow this document before any task that touches one or more of:

- Supabase migrations, RPCs, RLS policies, triggers, cron, or Edge Functions.
- Client/server request or response contracts.
- Auth, purchases, rewards, feed uploads, notifications, room sharing, invites,
  account deletion, or force update behavior.
- Local durable state that can outlive a release, such as Hive queues/caches.
- Any change that can affect users on already-released App Store/TestFlight
  builds.

For simple UI-only or copy-only tasks, use normal repo workflow unless the UI
change also depends on a server contract.

## Collaboration Contract

Before implementation, establish the blast radius:

- Which app versions/users can be affected immediately?
- Is the change server-side, client-side, or both?
- Does it change request params, response fields, DB function signatures,
  table shape, RLS behavior, notification payloads, or local persisted state?
- Is there a rollback path if production behavior is worse?

If a server change can affect old app versions, do not proceed directly. First
propose backward-compatible alternatives, such as:

- Keeping old fields and types while adding optional fields.
- Adding new optional params instead of changing required params.
- Keeping old RPC overloads separate from new overloads.
- Version-gating visibility or behavior by app version.
- Phasing rollout through server defaults before requiring new client behavior.

Wait for user approval before implementing or deploying an incompatible change.

## Contract Inventory

For every high-risk change, write down the current contract before editing:

- Endpoint/RPC/function name.
- Caller locations in Flutter and Edge Functions.
- Request params/body fields and which are optional.
- Response fields and types.
- DB side effects and transactions.
- Old-client assumptions, including fields not used by current HEAD but likely
  used by released builds or debug tools.
- Local persisted state shape, if any.

Do not infer live DB behavior from the oldest migration that mentions an object.
Find the latest migration/live definition that rewrites the table, policy,
trigger, or function.

## Server vs App Fixes

Separate proposed fixes into two lanes:

- **Server hotfix:** takes effect for existing users immediately. It must be
  backward-compatible with already-installed app versions.
- **App fix:** ships in the next build. It can improve UI, local state recovery,
  retries, or client parsing, but it cannot be assumed to protect existing
  installed clients until that build is adopted.

When both are needed, usually deploy the compatible server hotfix first, then
land the app-side fix with tests.

## Tests

Do not only test the new happy path. Add regression coverage for compatibility
and old state:

- Old response fields still exist and keep their type.
- Old request shapes still work.
- Old RPC overloads remain unambiguous.
- Persisted local state from a previous app version reloads safely.
- Retry/reconciliation behavior does not replay stale user-facing errors.
- Server work that should be async is not accidentally awaited again.

Prefer focused tests at the contract seam, then run the repo-required full
checks before shipping code changes:

```sh
flutter analyze
flutter test
```

For Edge Functions, source-level contract tests are acceptable when local
execution cannot reliably reproduce production runtime behavior.

## Production Verification

After deploying server-side changes, verify with production signals, not just
local tests:

- Confirm the target Supabase project ref before deploy.
- Confirm deployed function version and `verify_jwt` setting.
- Check Edge Function logs for status, version, and `execution_time_ms`.
- Check Postgres/API logs for RPC failures, timeouts, or RLS errors.
- Compare the logs to the user-reported timing or error.
- If instrumentation was added, confirm it logs only non-sensitive data.

If production symptoms differ from the hypothesis, stop and re-plan instead of
stacking unrelated fixes.

## Documentation

When the behavior or operational contract changes, update the relevant docs in
the same task:

- `memory-bank/*.md` for current state.
- `docs/*.md` runbooks for operational behavior.
- `docs/release_status.md` for app release state, ASC build/version state,
  backend hotfixes, migrations, and compatibility-impacting deployments.
- `AGENTS.md` when future agents must follow a new rule before editing.
- `tasks/todo.md` review section for what changed and how it was verified.

Keep docs current-state focused. Move long historical detail to archive notes
when it stops being useful as mandatory reading.

## Prompt Template

Use this shape for high-risk requests:

```text
This is a high-risk compatibility task.

Before editing:
1. Read AGENTS.md, active memory-bank docs, and relevant docs/*.md runbooks.
2. List the client/server contract and existing-user compatibility risks.
3. Separate server hotfix vs app-side fix.
4. Propose backward-compatible alternatives for any param/response/RPC/schema
   change that can affect old app versions.
5. Add regression tests for current behavior plus old contract/persisted state.
6. Deploy only after target project/config is verified.
7. Verify with production logs after deploy.
```

This template is intentionally explicit. It helps the agent avoid making a
current-HEAD-only change that breaks old clients.
