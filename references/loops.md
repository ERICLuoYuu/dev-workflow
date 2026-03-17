# Strict Loop Protocols

All loops have hard exit criteria. No early exits. No skipping rounds.
The orchestrator drives all loops — subagents don't loop themselves.

Reviewers always read THREE inputs:
1. Code changes (git diff or modified files)
2. `.claude/plan/plan.md` (what was intended)
3. `.claude/plan/deviations.md` (what changed and why)

---

## Phase 4: Strict Review Loop

Exit: ZERO high/medium findings from BOTH code-reviewer AND security-reviewer
in the SAME iteration. No partial passes.

```
iteration = 0
max_iterations = 5

loop:
  iteration += 1

  # 1. Spawn BOTH reviewers in parallel
  /code-review → code-reviewer (opus)
    - Review all changes since task began
    - Read .claude/plan/plan.md for intended behavior
    - Read .claude/plan/deviations.md for approved changes
    - PLAN COMPLIANCE CHECK (see below)
    - Write to review-comments.md

  /security-scan → security-reviewer (opus) IN PARALLEL
    - OWASP Top 10, secrets, dependency audit
    - Write to security-comments.md

  # 2. Merge findings, categorize HIGH / MEDIUM / LOW

  # 3. Evaluate
  if ZERO high + medium across both:
    → /verify gate
    → exit loop → Phase 5

  if iteration >= max_iterations:
    report findings to user
    ask: "Not converged after {max_iterations}. Continue or ship?"

  # 4. Fix ALL high + medium findings
  If a fix changes the implementation approach:
    → log deviation in .claude/plan/deviations.md
    → if significant, ask user before proceeding

  # 5. /verify — confirm fixes didn't break anything
  if /verify fails → build-error-resolver → fix → re-verify

  # 6. Delete old review files, re-review EVERYTHING
  repeat loop
```

### Plan compliance check

The code-reviewer MUST evaluate these in addition to standard code quality:

1. **Acceptance criteria coverage**: For each criterion in plan.md,
   is there code that fulfills it? Flag any unmet criteria as HIGH.

2. **Unlisted changes**: Are there code changes that don't correspond
   to any plan step or logged deviation? Flag as MEDIUM.
   (This catches accidental scope creep or forgotten deviation logging.)

3. **Deviation justification**: For each entry in deviations.md,
   is the reason valid and the impact accurately described? Flag
   unjustified or under-documented deviations as MEDIUM.

4. **Plan intent preservation**: Did the deviations collectively
   compromise the original goal? This is a judgment call — flag as
   HIGH if the implementation no longer achieves what was planned.

Tell the code-reviewer explicitly:
```
"In addition to code quality, check plan compliance:
 - Read .claude/plan/plan.md and verify every acceptance criterion is met
 - Read .claude/plan/deviations.md and verify all deviations are logged
 - Flag any code changes not covered by plan.md or deviations.md
 - Flag any unmet acceptance criteria"
```

### Review loop rules

- Orchestrator makes fixes, not the reviewer (reviewers are read-only)
- Fix ALL high + medium before re-running
- Each re-review covers ALL changes, not just fixes
- /verify between fix and re-review catches mechanical breakage
- Both reviewers must PASS in same iteration
- Deviation log must be updated if fixes change the approach

---

## Phase 5: Strict Test Loop (Minimum 3 Rounds)

Three mandatory rounds with specific focus areas.
Each round follows the same protocol:

```
ROUND PROTOCOL:
  a. /tdd         → expand tests (focus area, min 3 new tests)
  b. test-review  → inner loop: review test scripts until clean
  c. test-run     → inner loop: run suite, fix failures until pass
  d. /verify      → gate
```

### Round 1: Edge cases and boundary values

Focus for tdd-guide:
- Edge cases, boundary values, off-by-one errors
- Empty inputs, max values, zero, negative values
- Unicode, special characters, very long strings
- MINIMUM 3 new test cases
- Cross-reference: plan.md acceptance criteria — each criterion
  should have at least one test that verifies it directly

### Round 2: Negative paths and error handling

Focus for tdd-guide:
- Bad/malformed inputs, missing required fields
- Permission denied, unauthorized access attempts
- Network failures, timeouts, service unavailable
- Database constraint violations, duplicate keys
- MINIMUM 3 new test cases
- Log any discovered behavior not in plan as deviation

### Round 3: Integration and regression

Focus for tdd-guide:
- Cross-module interactions between changed and existing code
- Regression tests for every bug found during Phase 4 review
- Regression tests for every fix made during Rounds 1-2
- End-to-end flows if applicable (/e2e for Playwright)
- MINIMUM 3 new test cases

Round 3 review is CUMULATIVE — all test files, not just new ones.
Checks for duplication, gaps, flaky patterns.

Round 3 gate:
```
/verify
/test-coverage (must hit 80%+)
if coverage < 80% → Round 4 targeting uncovered files
```

### Acceptance criteria test mapping

During Round 1, create a mapping in the test review:
```
For each acceptance criterion in .claude/plan/plan.md:
  → Which test(s) verify this criterion?
  → If no test exists → flag as HIGH finding in test review
```

This ensures the test suite directly validates the plan,
not just random code paths.

---

## Inner Loop: Test Script Review

Used in step (b) of each round.

```
test_review_iteration = 0
test_review_max = 3

loop:
  test_review_iteration += 1

  /code-review targeting TEST FILES ONLY:
    - "Review ONLY test files. Do NOT review production code."
    - "Are assertions testing the right thing?"
    - "Are test names descriptive?"
    - "Is each test independent (no shared mutable state)?"
    - "Do mocks/stubs match real behavior?"
    - "Does every acceptance criterion from plan.md have a test?"
    - "Are there obvious gaps?"

  if clean → exit
  if findings:
    if test_review_iteration >= test_review_max → escalate to user
    fix test script issues
    repeat loop
```

---

## Inner Loop: Test Run + Fix

Used in step (c) of each round.

```
run_iteration = 0
run_max = 5

loop:
  run_iteration += 1
  run full test suite

  if all pass → exit
  if failures:
    if run_iteration >= run_max → escalate to user
    build-error-resolver:
      - Read error output
      - Check plan.md for intended behavior
      - Is the test wrong or the code wrong?
      - Fix with minimal change
      - Log deviation if fix changes approach
      - Re-run to confirm
    repeat loop
```

---

## Post-Test: Final Review Loop

After all rounds complete:

```
/code-review on ALL changes (production + tests):
  "Final review. All production code AND test files.
   Verify plan compliance: every acceptance criterion met,
   all deviations logged, no unlisted changes."

if findings → fix → re-review → loop until PASS

/verify + /test-coverage → final gate

if pass + coverage >= 80% → DONE → cleanup
if failures → back to test run+fix loop
```

### Plan finalization (during cleanup)

After DONE:
1. Update plan.md: check off completed acceptance criteria
2. Finalize deviations.md: add summary section at top

```markdown
## Summary
- Total deviations: [N]
- User-approved: [N]
- Auto-approved (trivial): [N]
- Plan completion: [X/Y acceptance criteria met]
- Unmet criteria: [list any, with explanation]
```

3. The .claude/plan/ directory stays in the repo as documentation

---

## Cost Tiers

| Mode | Rounds | Test review | Min tests/round | Est. spawns |
|------|--------|-------------|-----------------|-------------|
| Strict | 3+ | Every round | 3 | 15-20 |
| Standard | 2 | Every round | 2 | 10-12 |
| Quick | 1 | Once | None | 4-6 |

Default: Strict. Ask BEFORE starting Phase 5.
