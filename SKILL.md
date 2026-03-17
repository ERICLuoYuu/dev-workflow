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
- Approach and rationale
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

### When to update deviations.md

During Phase 3 (implement):
- Discovery: "plan says modify file X, but file X doesn't exist" → log + ask user
- Scope change: "need an extra helper function not in plan" → log as auto-approved
- Blocker: "planned approach won't work because of Y" → log + STOP + ask user

During Phase 4 (review):
- Review finding requires approach change → log before fixing

During Phase 5 (test):
- Tests reveal behavior not covered by plan → log
- Coverage requires testing code paths not in plan → log as auto-approved

---

## Phase execution

### Phase 1: EXPLORE

Built-in Explore subagent (auto-delegates on read-heavy tasks).
No slash command needed.

If the task is complex, ask Explore to write findings to
`.claude/plan/research-summary.md`. Otherwise, Explore returns
a summary to the main context directly.

Gate: enough context to plan.

### Phase 2: PLAN

```
/plan "[task description]"
```

The planner creates `.claude/plan/plan.md` with implementation blueprint.
If architectural decisions needed, also invoke the architect agent.

After plan.md is created, initialize the deviation log:

```markdown
# Deviations from plan

No deviations yet. This file is updated whenever implementation
diverges from .claude/plan/plan.md.
```

Save to `.claude/plan/deviations.md`.

Gate: plan.md exists with clear steps, test strategy, and acceptance criteria.
If open blockers, STOP and ask user.

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

The reviewer now has THREE inputs:
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
  fix findings (log deviation if fix changes approach)
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
ROUND 2 — Negative paths & error handling
ROUND 3 — Integration & regression (cumulative review, /test-coverage)
POST-TEST — Final review (plan compliance check) → /verify → DONE
```

Test expansion should target acceptance criteria from plan.md —
every criterion should have at least one test that directly verifies it.
Log any test that reveals behavior not covered by plan as a deviation.

### Cleanup

After Phase 5:
- refactor-cleaner removes dead code
- doc-updater syncs documentation
- Update `.claude/plan/plan.md` acceptance criteria: check off completed items
- Finalize `.claude/plan/deviations.md` with summary
- Suggest conventional commit message

The `.claude/plan/` directory stays in the repo as implementation
documentation. It answers "what did we plan, what actually happened,
and why did it change" for anyone reading the code later.

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
without any manual trigger — if the workflow is active (.claude/plan/ exists),
the hooks are active.

| Hook | Event | What it does |
|------|-------|-------------|
| plan-init.sh | SessionStart | Creates .claude/plan/ + deviations.md template |
| deviation-detector.sh | PostToolUse (Edit/Write) | Warns when edited file isn't in plan.md |
| commit-gate.sh | PreToolUse (Bash) | Blocks git commit if unchecked criteria or unapproved deviations |
| phase-tracker.sh | SubagentStop | Logs subagent completions, prints next-step guidance |

### How they work together

1. **Session starts** → plan-init.sh creates the directory structure
2. **During implementation** → every file edit triggers deviation-detector.sh.
   If the file isn't listed in plan.md and isn't already in deviations.md,
   it prints a warning. This nudges the agent to log deviations in real time.
3. **At commit time** → commit-gate.sh blocks the commit (exit code 2) if:
   - plan.md has unchecked acceptance criteria (`- [ ]`)
   - deviations.md has entries marked `**Approved**: no`
4. **After each subagent** → phase-tracker.sh logs the completion and
   prints which step comes next, keeping the orchestrator on track.

### Installation

Copy hooks to your project:
```bash
cp -r hooks/ .claude/hooks/
chmod +x .claude/hooks/*.sh
```

Merge hooks.json into your `.claude/settings.json`:
```bash
# If you already have hooks in settings.json, merge manually
# If not, copy the hooks section from hooks/hooks.json
```

Or if using ECC as a plugin, the hooks load automatically from
`hooks/hooks.json` in the plugin directory.

### Disabling hooks

If hooks conflict with ECC hooks or cause slowdowns:
```bash
export ECC_DISABLED_HOOKS="post:edit:deviation-detector,pre:bash:commit-gate"
```

Or remove specific entries from hooks.json.

---

## Reference files

- `references/loops.md` — Strict loop protocols for Phase 4 and Phase 5,
  including plan-compliance review, inner loops, exit criteria, cost tiers.
- `hooks/hooks.json` — Hook configuration wiring all 4 hooks to lifecycle events.
- `hooks/*.sh` — Hook scripts (must be executable).
