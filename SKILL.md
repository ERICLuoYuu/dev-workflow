---
name: dev-workflow
description: "Orchestrate a strict phased development workflow using ECC's existing subagents and commands. Use this skill whenever: implementing a new feature, fixing a complex bug, refactoring code, adding new modules, or any task that touches multiple files. The workflow runs 5 phases — Explore, Plan, Implement (TDD), Strict Review Loop, Strict Test Loop — chaining ECC agents via /plan, /tdd, /code-review, /security-scan, /verify, /e2e, and /test-coverage. Even if the user doesn't mention 'workflow' or 'phases', trigger this skill for any request that benefits from research-before-coding, test-first implementation, or structured review. Do NOT use for: one-line fixes, documentation-only changes, dependency bumps, or when the user explicitly says 'just do it quickly'."
---

# Dev Workflow: Strict Orchestration over ECC

Pure orchestration skill. Does not define agents or prompts — delegates
to ECC's existing agents and commands. Adds strict sequencing, phase gates,
plan tracking, and iterative loop protocols.

## ECC components used

| Phase | ECC command | ECC agent | Model |
|-------|-------------|-----------|-------|
| 1. Explore | (built-in) | Explore (native) | haiku |
| 2. Plan | /plan | planner | sonnet |
| 2b. Design | (if needed) | architect | opus |
| 3. Implement | /tdd | tdd-guide | sonnet |
| 3 gate | /verify | verification-loop | — |
| 4. Review | /code-review | code-reviewer | opus |
| 4. Security | /security-scan | security-reviewer | opus |
| 5. Expand | /tdd | tdd-guide | sonnet |
| 5. E2E | /e2e | e2e-runner | sonnet |
| 5. Fix | (auto) | build-error-resolver | sonnet |
| Cleanup | (auto) | refactor-cleaner, doc-updater | sonnet |

All agents are defined in ECC's `agents/` directory. Do NOT write custom prompts.
Use the slash commands — they invoke the correct agent with the correct tools.

---

## Plan directory: `.claude/plan/`

All planning artifacts live in `.claude/plan/` at the project root.
This directory is the source of truth for what should be built and what
actually changed during implementation.

```
.claude/plan/
├── plan.md              # The implementation plan (Phase 2 output)
├── deviations.md        # Log of every plan change during execution
└── research-summary.md  # Codebase context from Phase 1 (optional)
```

### plan.md

Created by the planner agent in Phase 2. Contains:
- Approach and rationale (with alternatives considered)
- Test plan (what tests to write first)
- Implementation steps with file paths and dependencies
- Acceptance criteria (checkboxes)
- Out of scope

### deviations.md

Created automatically at the start of Phase 3. Updated whenever
implementation diverges from plan.md. Each entry records:

```markdown
## Deviation [N]: [short title]
- **Phase**: [which phase discovered this]
- **Planned**: [what plan.md said]
- **Actual**: [what we're doing instead]
- **Reason**: [why the change was necessary]
- **Impact on acceptance criteria**: [which criteria changed, added, or removed]
- **Approved**: [yes/no — user confirmed, or auto if trivial]
```

Rules for deviations:
- ANY change to scope, approach, file list, or acceptance criteria gets logged
- Trivial deviations (renaming a variable, minor refactor) = auto-approved
- Significant deviations (new endpoint, changed API contract, dropped feature)
  = STOP and ask the user before proceeding
- The reviewer reads deviations.md to distinguish intentional changes from drift

---

## Phase execution

### Phase 1: EXPLORE

Built-in Explore subagent (auto-delegates on read-heavy tasks).
No slash command needed — describe the task and the orchestrator routes to Explore.

If the task is complex, ask Explore to write findings to
`.claude/plan/research-summary.md`. Otherwise, Explore returns
a summary to the main context directly.

Gate: enough context to plan (relevant files, patterns, dependencies, risks).

### Phase 2: PLAN (THINK HARD)

```
/plan "[task description]"
```

The planner creates `.claude/plan/plan.md`. Use extended thinking.

The plan MUST address 6 aspects:
1. **Problem space** — what exactly needs to change, scope, boundaries
2. **Approach analysis** — at least 2 approaches, tradeoffs, why this one
3. **Failure modes** — what could go wrong, edge cases, regressions
4. **Dependency chain** — what must be done first, what can parallelize
5. **Test strategy** — what tests exist before implementation starts
6. **Acceptance criteria** — concrete, verifiable, each one testable

If any aspect is missing, the plan isn't ready. Keep thinking.

If architectural decisions needed (new services, schema, API contracts),
also invoke the architect agent.

After plan.md is created, initialize `.claude/plan/deviations.md`.

Gate: plan.md exists with all 6 aspects covered. If open blockers, STOP and ask user.

### Phase 3: IMPLEMENT (TDD)

```
/tdd
```

Tell the tdd-guide to read `.claude/plan/plan.md` for what to build.

During implementation, whenever the approach diverges from plan:
1. Log the deviation in `.claude/plan/deviations.md`
2. If significant → STOP, explain to user, get approval
3. If trivial → auto-approve and continue
4. Update acceptance criteria in plan.md if needed

Gate: all planned tests pass + no unapproved deviations. Then:

```
/verify
```

### Phase 4: STRICT REVIEW LOOP

Read `references/loops.md` for the complete protocol.

The reviewer has THREE inputs:
1. The code changes (git diff)
2. `.claude/plan/plan.md` (what was intended)
3. `.claude/plan/deviations.md` (what changed and why)

Review checklist includes plan compliance:
- Does the implementation fulfill every acceptance criterion in plan.md?
- Are all deviations logged and justified?
- Are there unlisted deviations (code changes with no plan entry)?
- Did the deviations compromise the original intent?

```
loop:
  /code-review + /security-scan  ← IN PARALLEL
  (reviewer reads plan.md + deviations.md for context)
  merge findings
  if ZERO high+medium → /verify → exit
  fix ALL high + medium (log deviation if fix changes approach)
  /verify
  re-review ALL changes
  repeat until clean (max 5 iterations)
```

### Phase 5: STRICT TEST LOOP (Minimum 3 Rounds)

Read `references/loops.md` for the complete protocol.

Before starting, ask user which cost tier:
- **Strict** (default): 3 rounds, ~15-20 spawns
- **Standard**: 2 rounds, ~10-12 spawns
- **Quick**: 1 round, ~4-6 spawns

Each round: expand → review test scripts → run+fix → /verify gate.

```
ROUND 1 — Edge cases & boundary values
  /tdd → expand (min 3 new tests: empty, max, zero, off-by-one)
  /code-review → review TEST SCRIPTS only (loop until clean)
  run suite → build-error-resolver if failures (loop until pass)
  /verify gate

ROUND 2 — Negative paths & error handling
  /tdd → expand (min 3 new tests: bad input, permissions, timeouts)
  /code-review → review test scripts (loop until clean)
  run + fix loop
  /verify gate

ROUND 3 — Integration & regression
  /tdd → expand (min 3 new tests: cross-module, regressions for review fixes)
  /e2e → Playwright critical flows (if applicable)
  /code-review → review ALL test files CUMULATIVE (loop until clean)
  run + fix loop
  /verify + /test-coverage (must hit 80%+)
  if coverage < 80% → add Round 4 targeting uncovered files

POST-TEST — Final review loop
  /code-review on ALL changes (production + tests) → loop until PASS
  /verify + /test-coverage → final gate
  → DONE
```

### Cleanup

After Phase 5:
- refactor-cleaner removes dead code (auto-delegates)
- doc-updater syncs documentation (auto-delegates)
- Update `.claude/plan/plan.md`: check off completed acceptance criteria
- Finalize `.claude/plan/deviations.md` with summary
- Suggest conventional commit message (feat:/fix:/refactor:)

The `.claude/plan/` directory stays in the repo as documentation.

---

## Phase gates

Every transition runs /verify:

```
Phase 3 → /verify → Phase 4
Phase 4 → /verify → Phase 5
Each test round → /verify → next round
Final → /verify + /test-coverage → done
```

---

## Overrides

- "Skip to phase N" — jump directly
- "Just implement it" — skip phases 1-2, do 3-5
- "Skip tests" — phases 1-3 only (warn: not recommended)
- "Quick fix" — skip entire workflow
- "Standard/Quick test mode" — reduce Phase 5 rounds

---

## Progress reporting

After each phase (2-3 sentences):
- Which phase completed
- Key output or findings
- Deviation count (if any)
- What comes next

---

## Hooks

Four hooks enforce the workflow automatically. They fire on lifecycle events
— if .claude/plan/ exists, the hooks are active.

| Hook | Event | What it does |
|------|-------|-------------|
| plan_init | SessionStart | Creates .claude/plan/ + deviations.md template |
| deviation_detector | PostToolUse (Edit/Write) | Warns when edited file isn't in plan.md |
| commit_gate | PreToolUse (Bash) | Blocks git commit if unchecked criteria or unapproved deviations |
| phase_tracker | SubagentStop | Logs subagent completions, prints next-step guidance |

---

## Enforcement: making CC actually follow the workflow

The skill alone is NOT enough — CC reads it but shortcuts phases.
Three mechanisms enforce full compliance:

### 1. Rule file: `rules/dev-workflow.md`

Loaded into context EVERY session (rules are stronger than skills).
Contains:
- Mandatory checklist that CC must print before starting any multi-file task
- Explicit "do NOT skip phases, do NOT combine phases"
- Plan quality requirements (6 aspects that must be covered)
- Clear criteria for when skipping IS allowed

Install: loaded automatically as part of this plugin.

### 2. Slash command: `/dev`

Explicit trigger that creates a numbered todo list CC must work through.
Usage: `/dev Add OAuth2 login with Google provider`

Creates full checklist + instructs "think hard" during plan phase.

### 3. Hooks

- commit-gate blocks shipping if plan incomplete
- deviation-detector catches unlisted changes
- phase-tracker keeps the orchestrator on track

### Why all three?

| Mechanism | What it does | Failure mode without it |
|-----------|-------------|----------------------|
| Rule | Forces checklist on every multi-file task | CC skips phases silently |
| /dev command | Creates explicit todo with deep planning | CC rushes the plan |
| Hooks | Blocks commit if plan incomplete | CC ships without finishing |

---

## Reference files

- `references/loops.md` — Strict loop protocols for Phase 4 and Phase 5,
  including plan-compliance review, inner loops, exit criteria, cost tiers.
- `rules/dev-workflow.md` — Rule enforcing workflow compliance on every session.
- `commands/dev.md` — Slash command for explicit workflow trigger with checklist.
- `hooks/hooks.json` — Hook configuration wiring all hooks to lifecycle events.