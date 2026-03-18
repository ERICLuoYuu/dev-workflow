You are starting a strict phased development workflow. Follow every phase in order.
Do NOT skip phases. Do NOT combine phases.

## Task: $ARGUMENTS

## Step 1: Create the checklist

Print this checklist NOW, before doing anything else:

```
## Dev workflow: $ARGUMENTS
- [ ] Phase 1: Explore — gather context
- [ ] Phase 2: Plan — .claude/plan/plan.md (think hard)
- [ ] Phase 3: /tdd — tests first, then implement
- [ ] Phase 3 gate: /verify
- [ ] Phase 4a: /code-review — loop until PASS
- [ ] Phase 4b: /security-scan — loop until PASS
- [ ] Phase 4 gate: /verify
- [ ] Phase 5 R1: /tdd edge cases → review test scripts → run → /verify
- [ ] Phase 5 R2: /tdd negative paths → review test scripts → run → /verify
- [ ] Phase 5 R3: /tdd integration → review ALL tests → run → /verify + /test-coverage
- [ ] Phase 5 final: /code-review ALL changes → loop until PASS
- [ ] Phase 5 gate: /verify + /test-coverage (80%+)
- [ ] Cleanup: refactor-cleaner + doc-updater
- [ ] Commit: conventional format
```

## Step 2: Phase 1 — Explore

Use the built-in Explore subagent to gather context. Investigate:
- All files relevant to this task
- Existing patterns and conventions
- Dependencies and integration points
- Risks and edge cases

After exploring, check off Phase 1 and report findings.

## Step 3: Phase 2 — Plan (THINK HARD)

This is the most important phase. Use extended thinking.

Initialize .claude/plan/ directory if it doesn't exist.

Think through these aspects BEFORE writing the plan:

**Aspect 1 — Problem space**: What exactly needs to change? What's the scope?
What are the boundaries of this change? What is explicitly OUT of scope?

**Aspect 2 — Approach analysis**: What are at least 2 different approaches?
What are the tradeoffs of each? Why is the chosen approach better?

**Aspect 3 — Failure modes**: What could go wrong? What edge cases exist?
What happens if a dependency is unavailable? What about concurrent access?
What about data migration? What about backwards compatibility?

**Aspect 4 — Dependency chain**: What must be done first? What can be
parallelized? What has external dependencies (APIs, packages, services)?

**Aspect 5 — Test strategy**: What tests must exist BEFORE implementation?
What's the minimum set that proves the feature works?
What edge case tests would catch the failure modes from Aspect 3?

**Aspect 6 — Acceptance criteria**: Write concrete, verifiable criteria.
Each criterion must be testable — "works correctly" is NOT a criterion.
"Returns 401 for unauthenticated requests" IS a criterion.

Write the complete plan to .claude/plan/plan.md.
Initialize .claude/plan/deviations.md.
Check off Phase 2 and report the plan summary.

## Step 4: Execute remaining phases

For each subsequent phase, follow the dev-workflow skill and
references/loops.md exactly. Check off each item as you complete it.

CRITICAL RULES:
- After EVERY phase, update the checklist showing what's done
- If you discover the plan needs to change, log it in deviations.md
- Significant deviations → STOP and ask the user
- Review loops continue until PASS — do NOT exit on first attempt
- Test loop has 3 MANDATORY rounds — do NOT stop after 1
- /verify runs at every gate — do NOT skip gates
