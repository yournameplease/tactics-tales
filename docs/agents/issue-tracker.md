# Issue Tracker

This repo uses **Backlog.md** (via MCP) for all task and project management.

## Creating issues / tasks

Use `mcp__backlog__task_create`. Key fields:
- `title` — imperative short description
- `description` — what and why; files to create or modify
- `acceptanceCriteria` — how to confirm completion
- `milestone` — feature grouping (create with `mcp__backlog__milestone_add` first)
- `labels` — freeform strings (used for triage roles; see `triage-labels.md`)
- `status` — `Draft`, `To Do`, `In Progress`, or `Done`

## Reading / searching tasks

- `mcp__backlog__task_list` — list tasks (filter by status, milestone)
- `mcp__backlog__task_search` — search before creating to avoid duplicates
- `mcp__backlog__task_view` — read a specific task in full

## Updating tasks

- `mcp__backlog__task_edit` — edit any field, update status, add labels
- `mcp__backlog__task_complete` — mark a task Done

## Milestones

- `mcp__backlog__milestone_add` — create a milestone
- `mcp__backlog__milestone_list` — list existing milestones

## Workflow summary

See the `task-plan` and `task-work` skills for the full create→implement→complete loop.
