#!/usr/bin/env bash
# PreToolUse gate for Supabase writes.
#
# AGENTS.md makes two demands that are easy to satisfy *after* the fact and
# useless then:
#
#   - read docs/ai_collaboration_workflow.md BEFORE any high-risk compatibility
#     task (server/API/RPC/migration/...);
#   - for changes that can affect old app versions, propose alternatives and
#     WAIT for approval before implementing.
#
# Both were skipped on the 2026-08-14 pet-name migration: it went to production
# first, and the old-client impact was reported afterwards. A rule that is only
# in a document depends on the agent having read the document. This puts the
# obligations in front of the human at the moment of the write instead.
#
# Reads the PreToolUse payload on stdin. Emits an "ask" decision for writes;
# stays silent for everything else so read-only work is not slowed down.

set -uo pipefail

payload="$(cat)"
tool="$(printf '%s' "$payload" | jq -r '.tool_name // ""')"

case "$tool" in
  *apply_migration | *deploy_edge_function | *create_branch | *merge_branch | \
  *reset_branch | *delete_branch | *rebase_branch | *restore_project | \
  *pause_project)
    gated=1
    ;;
  *execute_sql)
    # execute_sql is the read path too, and gating every SELECT would train
    # everyone to click through the prompt. Only stop on statements that write.
    query="$(printf '%s' "$payload" | jq -r '.tool_input.query // ""')"
    if printf '%s' "$query" |
      grep -Eiq '(^|[[:space:];(])(create|alter|drop|truncate|grant|revoke|insert|update|delete|comment[[:space:]]+on|refresh[[:space:]]+materialized)[[:space:]]'; then
      gated=1
    else
      gated=0
    fi
    ;;
  *)
    gated=0
    ;;
esac

if [ "$gated" -ne 1 ]; then
  exit 0
fi

read -r -d '' reason <<'EOF' || true
AGENTS.md "Core workflow (non-negotiable)" applies to this write. Confirm before approving:

1. docs/ai_collaboration_workflow.md — read BEFORE this change, and its
   contract-inventory / server-vs-app-fix / compatibility-test /
   production-verification steps followed?
2. Old app versions — can this change their behaviour? If so, AGENTS.md
   requires proposing alternatives that avoid the impact (version-gated flags,
   backward-compatible defaults, new optional params, phased rollout) and
   WAITING for approval. Stating the impact after applying does not satisfy it.
3. docs/release_status.md — read and updated for migration / Edge Function
   deploy / server hotfix work? Git commit messages are not the source of truth.
4. memory-bank/database-schema.md — will it still be true after this?

Deny if any answer is no; the write can be redone once they are.
EOF

jq -n --arg reason "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "ask",
    permissionDecisionReason: $reason
  }
}'
