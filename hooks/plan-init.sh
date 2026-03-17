#!/bin/bash
# plan-init.sh
# SessionStart hook: initializes .claude/plan/ directory
# Only runs if directory doesn't exist yet — idempotent

PLAN_DIR=".claude/plan"

# Already initialized — skip
[ -d "$PLAN_DIR" ] && exit 0

# Only initialize if we're in a git repo (sanity check)
git rev-parse --git-dir > /dev/null 2>&1 || exit 0

mkdir -p "$PLAN_DIR"

cat > "$PLAN_DIR/deviations.md" << 'EOF'
# Deviations from plan

No deviations yet. This file is updated whenever implementation
diverges from .claude/plan/plan.md.

<!-- Format for each deviation:
## Deviation [N]: [short title]
- **Phase**: [which phase discovered this]
- **Planned**: [what plan.md said]
- **Actual**: [what we're doing instead]
- **Reason**: [why the change was necessary]
- **Impact on acceptance criteria**: [which criteria changed]
- **Approved**: [yes/no]
-->
EOF

echo "[dev-workflow] Initialized .claude/plan/ directory" >&2

exit 0
