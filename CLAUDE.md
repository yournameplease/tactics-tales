# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Tactics Tales is a Picotron tactics-RPG game written in [Teal](https://teal-language.org/), a statically-typed language that compiles to Lua. The game is designed to be moddable — game content (maps, battles, characters, stories, items) is loaded from mod data files at runtime rather than hardcoded.

## Commands

```bash
make all        # clean, build, and test
make test       # build and run all tests (unit + integration)
make ut         # build and run unit tests only (excludes --tags='it')
make it         # build and run integration tests only (--tags='it')
make tactics    # build only (via cyan)
make clean      # remove build/ artifacts
```

Tests use the [Busted](https://lunarmodules.github.io/busted/) test runner. Run a single spec file:

```bash
cyan build && busted build/spec/path/to/file_spec.lua
```

## Architecture

### Entry Point & Game Loop

`src/tactics/main.tl` is the Picotron entry point. It wires the `_init`, `_update`, and `_draw` hooks and coordinates the top-level services: `TaskManager`, `EventBus`, `UIManager`, `GameManager`, `AnimationManager`, and `JoypadManager`.

### Top-Level Systems

| System | Path | Role |
|--------|------|------|
| `GameManager` | `game/game.tl` | State machine: Main Menu ↔ Story. Loads mods via `ModLoader`. |
| `StoryManager` | `story/` | Plays story nodes (text, dialogue, battles). Manages `StoryMemory` for conditional logic. |
| `BattleManager` | `battle/` | Orchestrates battles. Delegates to `TacticsEngine`, `AIEngine`, `BattleMap`, `CombatCalculator`. |
| `UIManager` | `ui/` | Flexbox-like layout engine (`box.tl`) + declarative layout definitions + theme system. |
| `MenuManager` | `menu/` | Cursor/selection management for joypad and mouse, including nested menus and on-screen keyboard. |
| `EventBus` | `systems/event_bus.tl` | Pub/Sub decoupling distant systems (battle events, turn events, etc.). |
| `TaskManager` | `systems/tasks.tl` | Coroutine-based async runner for animations and story sequences. |
| `ModLoader` | `mods/` | Loads `.lua` mod files; validates mod data schema and cross-references. |

### Data Flow

Mods in `mods/` are loaded at startup into a `GameData` record:

```
GameData { loaded_mods, maps, battles, stories, characters, items }
```

`mods/base/` provides base utilities. `mods/tt_fantasy_demo_story/` is the demo story content.

### Build System

Teal source lives in `src/tactics/` and `src/spec/` (tests). `cyan build` transpiles `.tl` → `build/*.lua`. Tests run against the compiled Lua in `build/`.

- `lib/` — Lua helper utilities (not Teal)
- `types/` — LuaCATS type definitions for Lua modules and libs
- `src/spec/picotron_shim.tl` — Picotron API mock for tests

## Code Style

- **Types** (Records, Interfaces, Enums): `PascalCase`
- **Functions and variables**: `snake_case`
- **Services**: Define a public interface + private `Impl` record; hide private fields in the impl.
- **Static methods**: Belong to the module's local table, not on the Record itself (no dot-methods on records unless it's a variable).
- Do not use `as Type` casts or `any` unless interfacing with code that already uses them, or given explicit permission.

## Testing

- Test files: `src/spec/<path>/<tested_file>_spec.tl`
- Follow the import/setup pattern in `src/spec/util/lists_spec.tl`
- Prefer integration tests over mocks/spies. Picotron API mocks are acceptable using `src/spec/picotron_shim.tl`.
- Only test public interfaces.
- If new Teal test code won't compile, comment it out and note the issue rather than forcing a broken build.

## Documentation

Use triple-hyphen doc comments:

- `@brief` — one per file, summarizes the file's purpose
- `@desc` — documents the declaration below it (function, record, interface, enum)
- `@param` / `@return` — LuaCATS annotations when parameter details matter

## Teal Compilation Issues

If Teal code fails to compile after a few attempts, stop and ask the user to resolve the type issue rather than working around it with casts or `any`.
