#!/bin/bash
# phase-tracker.sh
# SubagentStop hook: fires when any subagent completes
# Logs completion to .claude/plan/phase-log.md
# Prints guidance about what comes next

PLAN_DIR=".claude/plan"
LOG="$PLAN_DIR/phase-log.md"

# Exit if workflow not active
[ -d "$PLAN_DIR" ] || exit 0

# Parse subagent info from stdin
INPUT=$(cat)
AGENT_NAME=$(echo "$INPUT" | jq -r '.agent_name // .tool_input.description // "unknown"' 2>/dev/null)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Initialize log if needed
if [ ! -f "$LOG" ]; then
  echo "# Phase log" > "$LOG"
  echo "" >> "$LOG"
fi

# Log the completion
echo "- [$TIMESTAMP] Subagent completed: $AGENT_NAME" >> "$LOG"

# Print next-step guidance based on which agent just finished
case "$AGENT_NAME" in
  *planner*|*plan*)
    echo "[dev-workflow] Plan phase complete. Next: /tdd to implement" >&2
    ;;
  *tdd*|*test-driven*)
    echo "[dev-workflow] TDD phase complete. Next: /verify then /code-review" >&2
    ;;
  *code-review*|*reviewer*)
    echo "[dev-workflow] Review complete. Check review-comments.md for verdict" >&2
    ;;
  *security*)
    echo "[dev-workflow] Security scan complete. Check security-comments.md" >&2
    ;;
  *build-error*|*error-resolver*)
    echo "[dev-workflow] Error resolution complete. Re-run tests to confirm" >&2
    ;;
  *e2e*)
    echo "[dev-workflow] E2E tests complete. Check results" >&2
    ;;
esac

exit 0
