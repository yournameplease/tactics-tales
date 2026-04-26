---
id: TASK-18
title: 'Engine: add generic selection story node'
status: To Do
assignee: []
created_date: '2026-04-26 19:11'
updated_date: '2026-04-26 20:08'
labels: []
milestone: m-3
dependencies: []
priority: high
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add a new story node type for config-phase option selection. Renders a list of named options (each with a name and description) and stores the chosen option's ID in a specified story memory key. The engine has no concept of archetypes — that is entirely mod-level. This is the only engine addition needed for milestone m-3.

Hot areas: `src/tactics/story/types.lua`, `src/tactics/story/handlers/node_handlers.lua`
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 New story node type exists for config-phase selection
- [ ] #2 Node accepts a list of options (each with id, name, description) and a memory_key to write to
- [ ] #3 Player is shown each option's name and description
- [ ] #4 Chosen option ID is written to the specified story memory key
- [ ] #5 Works within the existing config node flow
- [ ] #6 Engine has no knowledge of archetypes or what the options mean
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
