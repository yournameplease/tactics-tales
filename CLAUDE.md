Be consise in all responses.

## Project Overview

Tactics Tales is a Picotron tactics-RPG game written in Lua. The game is designed to be moddable — game content (maps, battles, characters, stories, items) is loaded from mod data files at runtime rather than hardcoded.

## Commands

```bash
make all        # clean, build, and test
make test       # build and run all tests (unit + integration)
make ut         # build and run unit tests only (excludes --tags='it')
make it         # build and run integration tests only (--tags='it')
make clean      # remove build/ artifacts
```

Tests use the [Busted](https://lunarmodules.github.io/busted/) test runner. Run a single spec file:

```bash
busted build/spec/path/to/file_spec.lua
```

<!-- BACKLOG.MD MCP GUIDELINES START -->

<CRITICAL_INSTRUCTION>

## BACKLOG WORKFLOW INSTRUCTIONS

This project uses Backlog.md MCP for all task and project management activities.

**CRITICAL GUIDANCE**

- If your client supports MCP resources, read `backlog://workflow/overview` to understand when and how to use Backlog for this project.
- If your client only supports tools or the above request fails, call `backlog.get_backlog_instructions()` to load the tool-oriented overview. Use the `instruction` selector when you need `task-creation`, `task-execution`, or `task-finalization`.

- **First time working here?** Read the overview resource IMMEDIATELY to learn the workflow
- **Already familiar?** You should have the overview cached ("## Backlog.md Overview (MCP)")
- **When to read it**: BEFORE creating tasks, or when you're unsure whether to track work

These guides cover:
- Decision framework for when to create tasks
- Search-first workflow to avoid duplicates
- Links to detailed guides for task creation, execution, and finalization
- MCP tools reference

You MUST read the overview resource to understand the complete workflow. The information is NOT summarized here.

</CRITICAL_INSTRUCTION>

<!-- BACKLOG.MD MCP GUIDELINES END -->
