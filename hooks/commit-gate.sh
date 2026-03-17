#!/bin/bash
# commit-gate.sh
# PreToolUse hook: fires before Bash commands
# Blocks git commit if:
#   1. Plan exists but has unchecked acceptance criteria
#   2. Deviations exist that aren't approved
# Exit 2 = block, Exit 0 = allow

# Only intercept git commit commands
COMMAND=$(jq -r '.tool_input.command // empty' 2>/dev/null)
echo "$COMMAND" | grep -qE '^\s*git\s+commit' || exit 0

PLAN=".claude/plan/plan.md"
DEVIATIONS=".claude/plan/deviations.md"

# If no plan directory, workflow isn't active — allow
[ -f "$PLAN" ] || exit 0

# Check 1: Are there unchecked acceptance criteria?
UNCHECKED=$(grep -c '^\s*- \[ \]' "$PLAN" 2>/dev/null || echo 0)
if [ "$UNCHECKED" -gt 0 ]; then
  echo "[dev-workflow] BLOCKED: $UNCHECKED unchecked acceptance criteria in $PLAN" >&2
  echo "[dev-workflow] Complete all criteria or update the plan before committing" >&2
  # Output deny decision
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Unchecked acceptance criteria in .claude/plan/plan.md"}}'
  exit 2
fi

# Check 2: Any unapproved deviations?
if [ -f "$DEVIATIONS" ]; then
  UNAPPROVED=$(grep -ciE '^\s*-\s*\*\*Approved\*\*:\s*no' "$DEVIATIONS" 2>/dev/null || echo 0)
  if [ "$UNAPPROVED" -gt 0 ]; then
    echo "[dev-workflow] BLOCKED: $UNAPPROVED unapproved deviations in $DEVIATIONS" >&2
    echo "[dev-workflow] Get user approval on deviations before committing" >&2
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Unapproved deviations in .claude/plan/deviations.md"}}'
    exit 2
  fi
fi

# All checks passed
exit 0
