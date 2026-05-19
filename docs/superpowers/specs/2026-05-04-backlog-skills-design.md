# Backlog Skills Design

**Date:** 2026-05-04

Two skills to support backlog hygiene and release planning. Both use Backlog.md via MCP.

---

## Skill 1: `task-cleaner`

### Purpose

Audit stale or draft tasks, confirm intent with the user, investigate the codebase for accuracy, and apply approved edits interactively.

### Trigger

User invokes the skill. Optionally supplies context about specific tasks or areas that have changed (e.g. "the renderer was reworked", "I don't think I want X anymore").

### Staleness heuristic

Use the file modification timestamp on the task's `.md` file in `backlog/tasks/`. Tasks untouched for 30+ days are flagged as stale candidates. The threshold can be overridden in the invocation message.

### Process

1. **Load candidates** — list all `Draft` and `To Do` tasks; sort by last-modified ascending (stalest first). Apply any user-supplied context as a filter or override.
2. **Triage pass** — display all candidates in a table (ID, title, age). For each, user marks **keep / drop / unsure**. User may batch responses or go one at a time.
3. **Investigate `unsure` tasks** — for each unsure task, read codebase relevant to the description (files mentioned, related code). Check:
   - Does the described behavior still exist?
   - Is the AC testable against current code?
   - Has the need been superseded?
4. **Present findings per task** — show: current description/AC, what changed in the codebase, recommended edit or archive. Ask for approval before touching anything.
5. **Apply** — on approval: `task_edit` to update description/AC/labels. `drop` decisions from triage are archived immediately without investigation.

### Output

Updated task cards. Stale/unwanted tasks archived.

---

## Skill 2: `release-planner`

### Purpose

Turn rough feature goals into a coherent release plan: aligned backlog tasks, identified gaps, suggested priorities, and a lightweight reference doc.

### Trigger

User invokes with rough feature goals (stated in the message or provided interactively). A full grill session always happens, even when goals are pre-stated.

### Process

1. **Grill goals with docs** — invoke `grill-with-docs` to extract and stress-test feature goals. Challenges each goal against `CONTEXT.md`, sharpens vague terminology, cross-references with codebase. Goals are locked after the grill session completes.
2. **Load backlog** — list all tasks and milestones; group existing tasks by milestone.
3. **Map goals → tasks** — for each goal, identify: tasks that fully cover it, partial coverage, and gaps with no tasks.
4. **Gap + priority analysis** — surface:
   - Uncovered goals that need new tasks
   - Tasks that seem misaligned with stated goals
   - Suggested priority reordering
5. **Present draft plan** — structured summary: goals, coverage map, gaps, proposed new tasks, suggested reordering. Adjust until user approves.
6. **Write plan doc** — save to `docs/superpowers/release-notes/YYYY-MM-DD-<release-name>.md`. Lightweight reference only, not official. Commit.
7. **Apply to backlog** — on approval: create new tasks under a confirmed milestone, reorder/relabel existing ones.

### Output

- A markdown reference doc in `docs/superpowers/release-notes/`
- Backlog tasks reflecting the agreed plan
