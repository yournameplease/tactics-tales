# Triage Labels

Triage roles are applied as **labels** on Backlog.md tasks. Status is a secondary signal.

| Role | Label | Status |
|------|-------|--------|
| `needs-triage` | `needs-triage` | `To Do` |
| `needs-info` | `needs-info` | `To Do` |
| `ready-for-agent` | `ready-for-agent` | `To Do` |
| `ready-for-human` | `ready-for-human` | `To Do` |
| `wontfix` | `wontfix` | `Done` |

When a skill mentions a triage role, apply the corresponding label via `mcp__backlog__task_edit` with `labels`.
