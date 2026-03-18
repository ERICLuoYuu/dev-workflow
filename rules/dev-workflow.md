# Development workflow enforcement

For ANY task that modifies production code across multiple files or introduces
new behavior, you MUST follow the dev-workflow skill phases in order.
Do NOT skip phases. Do NOT combine phases. Do NOT shortcut.

## Mandatory phase sequence

Before writing any code, create a checklist in your response:

```
## Workflow checklist
- [ ] Phase 1: Explore — gather codebase context
- [ ] Phase 2: Plan — write .claude/plan/plan.md (use extended thinking)
- [ ] Phase 3: Implement — /tdd (tests first, then code)
- [ ] Phase 3 gate: /verify
- [ ] Phase 4: Review loop — /code-review + /security-scan until PASS
- [ ] Phase 4 gate: /verify
- [ ] Phase 5: Test loop — 3 rounds minimum (edge → negative → integration)
- [ ] Phase 5 gate: /verify + /test-coverage
- [ ] Cleanup: refactor-cleaner + doc-updater + commit
```

Check off each item as you complete it. Do NOT proceed to the next phase
until the current phase is complete and its gate passes.

## When to skip the workflow

ONLY skip if ALL of these are true:
- Change is a single file
- Change is under 20 lines
- No new behavior introduced
- User explicitly says "quick fix" or "just do it"

If in doubt, follow the workflow.

## Plan phase requirements

The plan phase is the most important phase. Do NOT rush it.
Use extended thinking (think hard) when creating the plan.
The plan MUST address these aspects before you write any code:

1. What exactly needs to change and why (problem definition)
2. What approaches were considered and why this one was chosen
3. What could go wrong (failure modes, edge cases, regressions)
4. What the dependency chain looks like (order matters)
5. What tests need to exist before implementation starts
6. What the acceptance criteria are (concrete, verifiable)

If the plan doesn't cover all 6, it's not ready. Keep thinking.
