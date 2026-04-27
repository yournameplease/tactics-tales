---
id: TASK-40
title: 'Engine: add list type to StoryMemory and set_memory_list node'
status: To Do
assignee: []
created_date: '2026-04-26 20:09'
updated_date: '2026-04-27 13:41'
labels: []
milestone: m-6
dependencies: []
priority: high
ordinal: 400
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Two related engine additions needed for recruitment quota:

1. ListMemoryEntry in src/tactics/story/story_memory.lua:
   - New class: { type = "list", values: string[] }
   - Factory: story_memory.list(values)
   - Excluded from get_as_map() (programmatic data, like map entries)
   - Handled in serialize() / deserialize()

2. set_memory_list story node in src/tactics/story/types.lua + node_handlers.lua:
   - Node shape: { type = "set_memory_list", key: string, values: string[] }
   - Handler: writes story_memory.list(node.values) under node.key, then auto-advances
   - Analogous to existing set_memory node

Files: src/tactics/story/story_memory.lua, src/tactics/story/types.lua, src/tactics/story/handlers/node_handlers.lua, src/spec/story/story_memory_spec.lua
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 ListMemoryEntry type exists with values: string[] field
- [ ] #2 story_memory.list(values) factory creates correct entry
- [ ] #3 List entries are excluded from get_as_map()
- [ ] #4 List entries round-trip correctly through serialize/deserialize
- [ ] #5 set_memory_list node writes a list entry to story memory and auto-advances
- [ ] #6 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
