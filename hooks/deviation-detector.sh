#!/bin/bash
# deviation-detector.sh
# PostToolUse hook: fires after Edit/Write/MultiEdit
# Checks if the modified file appears in .claude/plan/plan.md
# If not, warns about potential unlisted deviation

PLAN=".claude/plan/plan.md"
DEVIATIONS=".claude/plan/deviations.md"

# Exit silently if no plan exists (workflow not active)
[ -f "$PLAN" ] || exit 0

# Parse the modified file path from stdin
FILE_PATH=$(jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$FILE_PATH" ] && exit 0

# Skip non-source files (tests, configs, plan artifacts)
case "$FILE_PATH" in
  .claude/*|*.md|*.json|*.lock|*.yml|*.yaml|node_modules/*|__pycache__/*|*.pyc)
    exit 0
    ;;
esac

# Check if this file is mentioned in the plan
if ! grep -qF "$FILE_PATH" "$PLAN" 2>/dev/null; then
  # Check if already logged as a deviation
  if [ -f "$DEVIATIONS" ] && grep -qF "$FILE_PATH" "$DEVIATIONS" 2>/dev/null; then
    exit 0  # Already tracked
  fi
  # Warn — this file isn't in the plan and isn't logged
  echo "[dev-workflow] File not in plan: $FILE_PATH" >&2
  echo "[dev-workflow] Log this in .claude/plan/deviations.md if intentional" >&2
fi

exit 0
