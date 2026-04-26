---
id: TASK-40
title: 'Engine: add jump_to_choice story node'
status: To Do
assignee: []
created_date: '2026-04-26 20:09'
labels: []
milestone: m-6
dependencies: []
priority: high
ordinal: 500
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add a new story node type for runtime player choices during story execution (distinct from the config-phase selection node). Renders a list of options to the player; each option has a label and a jump target node name. Jumps directly to the selected target. Does not write to story memory. Used for recruitment prompts (accept/decline) and any other runtime branching that needs player input.

Hot areas: `src/tactics/story/types.lua`, `src/tactics/story/handlers/node_handlers.lua`
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 New story node type exists for runtime player choice
- [ ] #2 Node accepts a list of options (each with label and target node name)
- [ ] #3 Player is shown each option's label
- [ ] #4 Engine jumps to the selected target node
- [ ] #5 Does not write to story memory
- [ ] #6 Works during normal story execution (not config phase only)
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
