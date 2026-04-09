# Teal → Lua + LuaCATS Migration Plan

## Motivation

Migrating from Teal to plain Lua with LuaCATS type annotations trades a bespoke compiler
for the well-supported `lua-language-server` ecosystem. The gains are:

- Full LSP support (go-to-definition, rename, inlay hints, find-references)
- No transpile step for source navigation — debuggers, profilers, and stack traces point at
  actual source files
- Type annotations live in the same file without a separate `.d.tl` layer for external libs
- Lua 5.4 / LuaJIT idioms work as expected without Teal surprises

The trade-off is losing Teal's compile-time type enforcement; `lua-language-server` is a
linter, not a compiler. Discipline in CI (running `lua-language-server --check` as a build
step) compensates.

---

## Principles

1. **Leaf-first**: migrate modules with no game dependencies before those that depend on them.
2. **Tests move with their module**: when a module migrates, its spec file migrates in the
   same batch. Where critical paths lack tests, write them *before* migrating.
3. **No type regressions**: every migrated file must have full LuaCATS annotations — all
   public functions, all record fields, all type aliases. The bar is equal to or stricter
   than what Teal enforced.
4. **Documentation required**: every public function must have an `---@brief` equivalent (`---`
   summary line) and `---@param` / `---@return` annotations where parameter semantics are
   non-obvious.
5. **No `any` leakage**: avoid `---@type any` in migrated files except when interfacing with
   established `any`-typed boundaries (mod data, `pt.*` raw APIs). Flag each occurrence with
   a `-- TODO: narrow` comment.
6. **Delete, don't leave behind**: when a `.tl` file is migrated, delete it. Do not maintain
   both `.tl` and `.lua` versions.

---

## Toolchain Setup

### lua-language-server

Install `lua-language-server` (the standalone binary, not just the VS Code extension).

```bash
# Fedora / RPM
sudo dnf install lua-language-server

# Or via Mason in Neovim, or download from:
# https://github.com/LuaLS/lua-language-server/releases
```

The `.luarc.json` at the project root (already in place):

```json
{
  "workspace.library": ["types/"],
  "workspace.ignoreDir": ["build", "tactics.p64", "lib", ".git"],
  "runtime.version": "Lua 5.4",
  "diagnostics.enable": true,
  "workspace.checkThirdParty": false,
  "type.checkTableShape": true,
  "runtime.builtin": { "package": "enable", ... },
  "runtime.special": { "include": "require" }
}
```

Key decisions:
- `lib/` is ignored — it contains Picotron runtime bridge files, not source to check.
- `package` is enabled — the test environment uses standard Lua `require`.
- Game-specific globals (`log`, `DYNAMIC_CONFIG`, `pt`, etc.) are declared in `types/globals.lua`.
- `types/` Picotron system definitions were copied from the Picotron install and are used as-is.

Run type checking:

```bash
make check
# or directly:
lua-language-server --check=$(pwd) --configpath=.luarc.json --check_format=pretty
```

### Selene (optional linter)

Selene catches things LLS misses (unused variables, incorrect standard library usage):

```bash
cargo install selene  # or download binary
```

`selene.toml`:

```toml
std = "lua54"

[rules]
unused_variable = "deny"
```

---

## Build System Changes

The current build flow: `cyan build` compiles `src/**/*.tl` → `build/**/*.lua`; busted runs
with `lpath = build/?.lua`.

During migration, source `.tl` files are kept in place so that `cyan` can continue to
type-check the unmigrated files that depend on them. Migrated `.lua` files are created
alongside their `.tl` counterparts and **overwrite** the cyan-compiled output in `build/`,
so tests always run against the migrated Lua. Spec `.tl` files are the exception — they
can be deleted immediately because no other file imports them.

The Makefile must guarantee that the `.lua` copy runs *after* `cyan build`, because
pattern-rule ordering in Make is not sufficient when both `src/%.tl` and `src/%.lua` exist
for the same module (both produce the same `build/%.lua` target). Replace the
`$(BUILD_MARKER)` recipe with an explicit sequential copy:

```makefile
LUA_SRC = $(shell find src/ -type f -name '*.lua')

$(BUILD_MARKER): $(TL_SRC) $(LUA_SRC)
    $(CYAN) $(CYANFLAGS) build
    @for f in $(LUA_SRC); do \
        dest="build/$${f#src/}"; \
        mkdir -p "$$(dirname $$dest)"; \
        cp "$$f" "$$dest"; \
    done
    @touch $@
```

This ensures cyan compiles `.tl` files first, then every `.lua` in `src/` is copied on top —
migrated modules overwrite their teal-compiled counterparts, unmigrated modules are unaffected.

Once the final `.tl` source file is deleted (Final Cleanup), remove `cyan` and the loop;
the recipe becomes just the copy.

---

## Teal → LuaCATS Translation Reference

### Enums

```teal
-- Teal
local enum Foo
    "a"
    "b"
end

global enum Bar
    "x"
    "y"
end
```

```lua
-- LuaCATS
---@alias Foo "a"|"b"

-- global (in types/globals.lua or inline)
---@alias Bar "x"|"y"
```

### Records (data types)

```teal
local record Point
    x: integer
    y: integer
end
```

```lua
---@class Point
---@field x integer
---@field y integer
```

### Interfaces

Teal interfaces become abstract `---@class` declarations. Mark them as abstract in a comment:

```lua
---@class MenuSignal Abstract base for all menu signals.
---@field type MenuSignalType
```

### Discriminated unions (`where self.type == "x"`)

Teal's `where` narrowing has no LuaCATS equivalent. Model as a subclass:

```teal
local record MenuSignalNavigate
    is MenuSignal
    where self.type == "navigate"
    target: MenuStep
end
```

```lua
---@class MenuSignalNavigate : MenuSignal
---@field type "navigate"   -- narrows the union
---@field target MenuStep
```

Call sites that need to narrow: use `---@cast` or check `signal.type` before accessing
subtype fields (the same pattern the Teal code already uses).

### Generics on functions

```teal
function lists.filter<A>(filter: function(A): boolean): function({A}): {A}
```

```lua
---@generic A
---@param filter fun(elem: A): boolean
---@return fun(list: A[]): A[]
function lists.filter(filter) ... end
```

### Generics on record-like tables

```teal
local type MapEntry<Key,Value> = { Key, Value }
```

```lua
---@alias MapEntry<K, V> [K, V]
-- or
---@class MapEntry<K, V>
---@field [1] K
---@field [2] V
```

### Method definitions

Unchanged — `function Foo:method()` syntax stays the same. Add annotations above:

```lua
---@param x integer
---@return boolean
function Foo:is_valid(x) ... end
```

### `as` casts

Most `as Type` casts in the Teal source are needed only by the type checker. In plain Lua,
delete them. Where runtime narrowing logic is needed, use `---@cast`:

```lua
local val = some_map[key]  ---@cast val integer  -- we know this is always integer here
```

Use `---@cast` sparingly — it suppresses checking. Prefer restructuring code to avoid it.

### `local type _ = require(...)` imports

These are Teal-only type-import idioms. Delete them entirely. Bring in only what is actually
used at runtime.

### `global` declarations

Teal `global` variables are declared in `types/picotron.d.tl`. After migration, these move
to LuaCATS definition files (`.lua` files with `---@meta` header) in `types/`:

```lua
---@meta

---@type Picotron
pt = {}

---@type DynamicConfig
DYNAMIC_CONFIG = {}
```

---

## `pt.*` → Standard Lua Replacement Table

During migration, replace all `pt.*` standard-library wrappers with their Lua equivalents.
Only the Picotron-specific APIs (rendering, sound, input, filesystem) remain in `pt` and
the test shim.

### Drop-in replacements

| `pt.*` call | Lua equivalent | Notes |
|-------------|----------------|-------|
| `pt.add(t, v)` | `table.insert(t, v)` | |
| `pt.add(t, v, i)` | `table.insert(t, i, v)` | **Argument order is reversed** |
| `pt.deli(t, i)` | `table.remove(t, i)` | |
| `pt.pop(t)` | `table.remove(t)` | |
| `pt.type(x)` | `type(x)` | |
| `pt.flr(x)` | `math.floor(x)` | |
| `pt.abs(x)` / `pt.absf(x)` | `math.abs(x)` | |
| `pt.max(a, b)` | `math.max(a, b)` | |
| `pt.min(a, b)` | `math.min(a, b)` | |
| `pt.rnd(n)` | `math.random() * n` | Returns float 0..n, matching Picotron behaviour |
| `pt.cos(x)` | `math.cos(x)` | |
| `pt.sin(x)` | `math.sin(x)` | |
| `pt.sqrt(x)` | `math.sqrt(x)` | |
| `pt.chr(n)` | `string.char(n)` | |
| `pt.printh(s)` | `print(s)` | |
| `pt.cocreate(f)` | `coroutine.create(f)` | |
| `pt.coresume(co)` | `coroutine.resume(co)` | |
| `pt.costatus(co)` | `coroutine.status(co)` | |
| `pt.yield(...)` | `coroutine.yield(...)` | |
| `pt.tonum(s)` | `tonumber(s)` | |

### Replacements requiring care

**`pt.mid(lo, val, hi)`** — returns the middle (median) of three values, used as a clamp:

```lua
-- pt.mid(lo, val, hi)  →
math.max(lo, math.min(val, hi))
```

**`pt.atan2(dx, dy)`** — Picotron's argument order is `(dx, dy)`, opposite of standard Lua:

```lua
-- pt.atan2(dx, dy)  →
math.atan(dy, dx)
```

**`pt.del(t, v)`** — removes the first element equal to `v` by value (not by index). Only
two uses in the source; inline the removal directly:

```lua
-- pt.del(self.tasks, co)  →
for i = #self.tasks, 1, -1 do
    if self.tasks[i] == co then
        table.remove(self.tasks, i)
        break
    end
end
```

**`pt.sub(s, start, end_or_bool)`** — the boolean form `pt.sub(s, n, true)` means "single
character at position n". Replace with:

```lua
-- pt.sub(s, start, finish)  →  string.sub(s, start, finish)
-- pt.sub(s, n, true)         →  string.sub(s, n, n)
```

**`pt.split(str, sep)`** — used twice. Replace with the equivalent Lua pattern loop, or
extract a small helper in `util/string.lua` if the same semantics are needed more broadly.

### What stays in `pt` (Picotron-specific, still shimmed in tests)

These are not replaceable with standard Lua and must remain accessed via `pt`:

`cls`, `print`, `rectfill`, `rrectfill`, `rect`, `rrect`, `line`, `circ`, `circfill`,
`spr`, `sspr`, `map`, `mget`, `mset`, `fget`, `fset`, `set_pal`, `reset_pal`, `set_palt`,
`reset_palt`, `set_camera`, `reset_camera`, `get_spr`, `set_spr`, `set_draw_target`,
`get_draw_target`, `btn`, `btnp`, `key`, `keyp`, `get_mouse`, `set_mouse`,
`sfx`, `music`, `note`, `ls`, `fetch`, `store`, `fetch_metadata`, `store_metadata`,
`mkdir`, `cd`, `cp`, `mv`, `rm`, `fullpath`, `fstat`, `pwd`, `mount`, `include`,
`stat`, `set_window_attributes`, `set_window_size`, `vid`, `flip`, `userdata`, `vec`,
`tline3d`, `pset`, `pget`, `peek`, `poke`, `memcpy`, `memset`, `pod`, `unpod`,
`env`, `pid`, `send_message`, `on_event`, `create_process`, `time`, `t`, `notify`,
`stop`, `open`, `theme`, `pwf`, `wrangle_working_file`.

### Shim simplification

After migration, the shim (`spec/picotron_shim.lua`) can remove all the stdlib wrapper
entries (`add`, `del`, `deli`, `pop`, `type`, `flr`, `abs`, `absf`, `max`, `min`, `mid`,
`rnd`, `cos`, `sin`, `sqrt`, `atan2`, `chr`, `printh`, `cocreate`, `coresume`, `costatus`,
`yield`, `tonum`, `pack`, `unpack`, `all`, `foreach`, `count`). The block that copies shim
keys onto `_G` can also be removed once source code no longer uses bare `add()` / `del()`
calls. (Mod files use bare globals — that is a separate migration concern for mod authors.)

---

## Quality Standard (Definition of Done per File)

A migrated file is complete when:

- [ ] `.tl` source deleted; `.lua` source in `src/` with identical runtime behaviour
- [ ] All public functions have: summary doc comment, `---@param` for every parameter,
  `---@return` for non-void functions
- [ ] All record/class types fully annotated with `---@class` and `---@field` for every field
- [ ] All enums converted to `---@alias`
- [ ] Zero `---@type any` in new code (document exceptions with `-- TODO: narrow`)
- [ ] `lua-language-server --check` produces no new warnings/errors for this file
- [ ] All existing tests for this file pass unchanged
- [ ] Any new pre-migration tests for this file also pass

---

## Pre-Migration Testing

Before migrating each batch, verify that critical flows have integration test coverage.
Write tests in **plain Lua** (`.lua` spec files) that exercise the public interface
of the modules being migrated. These tests serve two purposes:

1. Confirm the module's current behaviour before rewriting the file
2. Act as a regression suite post-migration

### Critical flows to cover before their batches

| Flow | Modules | Test file |
|------|---------|-----------|
| Util functions (all) | `util/*` | Most already covered — verify `make ut` passes |
| Schema validation | `validator/*` | `spec/validator/validator_spec` — already exists |
| Mod loading | `mods/mod_loader` | `spec/mods/mod_loader_spec` — already exists |
| Menu navigation (joypad) | `menu/cursor/*`, `menu/menu_manager` | Already exists |
| Menu serialization / deserialization | `menu/cursor/*` | Add round-trip tests |
| Event bus pub/sub | `systems/event_bus` | Add: subscribe, publish, unsubscribe |
| Task coroutine lifecycle | `systems/tasks` | Add: start, complete, error cases |
| Battle: combat calculation | `battle/combat/combat_calculator` | Add before Batch 6 |
| Battle: pathfinding | `battle/pathfinding` | Add before Batch 6 |
| Story: memory conditionals | `story/story_memory` | Add before Batch 7 |

For each: run the tests against the *Teal-compiled* code first to establish a green baseline,
then again against the migrated Lua.

---

## Migration Batches

Files are grouped by dependency layer. Each batch assumes all previous batches are complete.
Spec files migrate in the same batch as their module.

---

### Batch 0 — Test Infrastructure

These files underpin all tests. Migrate them first to ensure the test harness itself is in
plain Lua.

| File | Notes |
|------|-------|
| `spec/picotron_shim.tl` | Large; heavy use of `as` casts — all can be deleted in `.lua`; replace `Userdata` Teal type annotations with LuaCATS `---@class` |
| `spec/require_trimmer.tl` | Trivial — two lines plus type annotation |
| `spec/input/input_helper.tl` | Small |
| `busted_setup.lua` | Already Lua — add LuaCATS `---@type` to globals it sets up |

---

### Batch 1 — Leaf Utilities

No dependencies on game code. All have existing spec files.

| File | Spec |
|------|------|
| `tactics/util/lists.tl` | `spec/util/lists_spec.tl` |
| `tactics/util/maps.tl` | `spec/util/maps_spec.tl` |
| `tactics/util/fp.tl` | `spec/util/fp_spec.tl` |
| `tactics/util/array_2d.tl` | `spec/util/array_2d_spec.tl` |
| `tactics/util/point.tl` | `spec/util/point_spec.tl` |
| `tactics/util/string.tl` | `spec/util/string_spec.tl` |
| `tactics/util/text.tl` | `spec/util/text_spec.tl` |
| `tactics/util/id_generator.tl` | `spec/util/id_generator_spec.tl` |
| `tactics/util/randomizer.tl` | No spec — add basic tests |
| `tactics/util/random.tl` | No spec — add basic tests |
| `tactics/constants.tl` | No spec — verify constant values, no behaviour |
| `tactics/colors.tl` | No spec — verify constant values |
| `tactics/corpora/names.tl` | No spec — verify list is non-empty |

---

### Batch 2 — Core Systems

| File | Spec |
|------|------|
| `tactics/systems/tasks.tl` | Add: coroutine lifecycle tests |
| `tactics/systems/event_bus/event_listener.tl` | Add: with event_bus spec |
| `tactics/systems/event_bus/event_writer.tl` | Add: with event_bus spec |
| `tactics/systems/event_bus.tl` | Add: pub/sub integration test |
| `tactics/validator/schema_definition.tl` | `spec/validator/validator_spec.tl` |
| `tactics/validator/schema_validator.tl` | `spec/validator/validator_spec.tl` |
| `tactics/types/item_definition.tl` | Type-only; no spec needed |

---

### Batch 3 — Domain Type Files

These are mostly pure type definitions (enums, records). Little behaviour to test.

| File | Notes |
|------|-------|
| `tactics/menu/types.tl` | Enums and records only |
| `tactics/battle/definition/types.tl` | Enums and records only |
| `tactics/battle/map/types.tl` | |
| `tactics/battle/tactics/types.tl` | |
| `tactics/battle/battle_map/types.tl` | |
| `tactics/battle/definition/objective.tl` | |
| `tactics/battle/definition.tl` | |
| `tactics/character/items/types.tl` | |
| `tactics/story/types.tl` | |
| `tactics/ui/types.tl` | |

---

### Batch 4 — Joypad & Input

| File | Spec |
|------|------|
| `tactics/joypad.tl` | No spec — shim-dependent; verify shape |
| `tactics/input/input_context.tl` | No spec |

---

### Batch 5 — Menu System

The menu system has good existing test coverage. Expand serialization/deserialization tests
before starting.

| File | Spec |
|------|------|
| `tactics/menu/menu_cursor.tl` | (used by cursor specs) |
| `tactics/menu/menu_context.tl` | |
| `tactics/menu/cursor/button.tl` | `spec/tactics/menu/cursor/button_spec.tl` |
| `tactics/menu/cursor/selection.tl` | `spec/tactics/menu/cursor/selection_spec.tl` |
| `tactics/menu/cursor/nested/grid.tl` | `spec/tactics/menu/cursor/nested/grid_spec.tl` |
| `tactics/menu/cursor/nested/list.tl` | `spec/tactics/menu/cursor/nested/list_spec.tl` |
| `tactics/menu/menu_manager.tl` | `spec/tactics/menu/menu_manager_spec.tl` |
| `tactics/menu/on_screen_keyboard.tl` | |
| `tactics/menu/menu_cursor.tl` | |

---

### Batch 6 — Mod Loading

| File | Spec |
|------|------|
| `tactics/mods/mod_schema.tl` | |
| `tactics/mods/mod_loader.tl` | `spec/mods/mod_loader_spec.tl` |
| `tactics/mods.tl` | |
| `integration/modloading_spec.tl` | |

---

### Batch 7 — Character & Item Domain

| File | Notes |
|------|-------|
| `tactics/character/definition.tl` | |
| `tactics/character/object/character.tl` | |
| `tactics/character/items/object/item.tl` | |
| `tactics/character/items/object/weapon.tl` | |
| `tactics/character/items/object/item_inventory.tl` | |
| `tactics/character/items/item_generator.tl` | Add generator tests |
| `tactics/character/character_generator.tl` | Add generator tests |
| `tactics/character/character_manager.tl` | |
| `tactics/character/sprite_data.tl` | |
| `tactics/character/animation_data.tl` | |
| `tactics/character/character_renderer.tl` | Rendering; test output shape, not pixels |

---

### Batch 8 — Battle Domain

Add combat and pathfinding tests before starting this batch.

| File | Notes |
|------|-------|
| `tactics/battle/pathfinding.tl` | Add: path exists, no path, blocked cases |
| `tactics/battle/combat/combat_calculator.tl` | Add: damage formula, hit chance |
| `tactics/battle/objective.tl` | |
| `tactics/battle/battle_objective_service.tl` | |
| `tactics/battle/tactics/battle_unit.tl` | |
| `tactics/battle/tactics/tactics_engine.tl` | |
| `tactics/battle/tactics/ai_engine.tl` | |
| `tactics/battle/unit/spawn_data.tl` | |
| `tactics/battle/unit/unit_ai.tl` | |
| `tactics/battle/map/map_generator.tl` | |
| `tactics/battle/battle_map.tl` | |
| `tactics/battle/scripts/battle_script.tl` | |
| `tactics/battle/scripts/script_manager.tl` | |
| `tactics/battle/battle_menu_context.tl` | |
| `tactics/battle/battle_ui_context.tl` | |
| `tactics/battle/battle_menu_manager.tl` | |
| `tactics/battle/battle_manager.tl` | |

---

### Batch 9 — Story Domain

Add story memory conditional tests before starting.

| File | Notes |
|------|-------|
| `tactics/story/story_memory.tl` | Add: flag set/get, conditional evaluation |
| `tactics/story/types.tl` | Already in Batch 3 |
| `tactics/story/story_page.tl` | |
| `tactics/story/story.tl` | |
| `tactics/story/drawable_character.tl` | |
| `tactics/story/story_menu_context.tl` | |
| `tactics/story/story_menu_manager.tl` | |
| `tactics/story/story_ui_context.tl` | |
| `tactics/story/statistics/stats_service.tl` | |
| `tactics/story/statistics/story_statistics.tl` | |

---

### Batch 10 — UI System

The UI system is the most complex; leave it late. No direct test path for rendering —
test data transformation and layout computation where possible.

| File | Notes |
|------|-------|
| `tactics/ui/box.tl` | Test layout calculation in isolation |
| `tactics/ui/theme.tl` | |
| `tactics/ui/validator.tl` | |
| `tactics/ui/layout.tl` | |
| `tactics/ui/containers.tl` | |
| `tactics/ui/ui_context.tl` | |
| `tactics/ui/ui_context_manager.tl` | |
| `tactics/ui/ui_manager.tl` | |
| `tactics/ui/components/dialogue_node.tl` | |
| `tactics/ui/components/menu.tl` | |
| `tactics/ui/decoration/book.tl` | |
| `tactics/ui/layout/game.tl` | |
| `tactics/ui/layout/story_page.tl` | |
| `tactics/ui/layout/tactics.tl` | |
| `tactics/ui/layout/title_screen.tl` | |
| `tactics/ui/modal/tactics.tl` | |
| `tactics/ui/panels/battle.tl` | |
| `tactics/ui/panels/control_hints.tl` | |
| `tactics/ui/panels/portrait_box.tl` | |
| `tactics/ui/panels/story_page.tl` | |
| `tactics/ui/panels/tactics_map.tl` | |

---

### Batch 11 — Remaining Top-Level

| File | Notes |
|------|-------|
| `tactics/debug.tl` | |
| `tactics/config.tl` | |
| `tactics/config/config_manager.tl` | |
| `tactics/game_data.tl` | |
| `tactics/draw.tl` | |
| `tactics/draw/draw_target_manager.tl` | |
| `tactics/animation.tl` | |
| `tactics/animation/animated_skeleton.tl` | |
| `tactics/save/save_system.tl` | |
| `tactics/music/music_player.tl` | |
| `tactics/dialogue/dialogue.tl` | |
| `tactics/dialogue/dialogue_manager.tl` | |
| `tactics/turn_manager.tl` | |
| `tactics/game/game.tl` | |
| `tactics/game/game_menu_context.tl` | |
| `tactics/game/game_menu_manager.tl` | |
| `tactics/game/game_ui_context.tl` | |
| `tactics/main.tl` | Entry point — migrate last |

---

### Batch 12 — Type Definition Files (types/)

After all source is migrated, convert the Teal `.d.tl` declaration files to LuaCATS
`---@meta` files:

| File | Target |
|------|--------|
| `types/picotron.d.tl` | `types/picotron.lua` with `---@meta` |
| `types/busted.d.tl` | `types/busted.lua` with `---@meta` |
| `types/lfs.d.tl` | `types/lfs.lua` with `---@meta` |
| `types/luassert.d.tl` | `types/luassert.lua` with `---@meta` |
| `types/profiler.d.tl` | `types/profiler.lua` with `---@meta` |

---

## Per-Batch Process Checklist

For each batch:

1. **Write missing tests** (in plain `.lua`) against the current Teal-compiled code. Run `make
   ut` and confirm green.
2. **For each file in the batch, migrate spec then source:**
   a. Translate the `_spec.tl` → `_spec.lua`: remove Teal imports (`local type _ = require`),
      convert inline type annotations on lambdas, replace `local record` with `---@class`.
   b. Delete the `_spec.tl` file.
   c. Translate the source `.tl` → `.lua` alongside the existing `.tl`:
      - Remove Teal-specific syntax: `global`, `local record`, `local interface`, `local enum`,
        generic angle-bracket syntax, `is`/`where` constraints, `as` casts, `local type _`
      - Add LuaCATS annotations for all types, functions, and fields
      - Translate `pt.add` → `table.insert`, `pt.max` → `math.max`, etc. (see replacement
        table above)
   d. **Keep the `.tl` source file** — do not delete it. Cyan still needs it to type-check
      other unmigrated files that import this module. The `.lua` file overwrites the built
      output so tests run against the migrated code.
   e. **Run `make ut`** (or `make it` for integration specs). All tests must pass.
3. **Run `lua-language-server --check src/`**. Resolve all new warnings.
4. **Review**: confirm every public symbol has documentation and type annotations.

> **Note on `pt.*` APIs**: `pt.add`, `pt.del`, `pt.mid`, etc. are Picotron globals that the
> shim provides in tests. During migration, decide whether to keep them (simpler — just keep
> the shim providing them) or replace with standard Lua (`table.insert`, `table.remove`,
> `math.max(math.min(...))`, etc.). Replacing makes the source less Picotron-specific and
> removes the shim dependency for logic-only modules, which is preferable for testability.
> This can be done per-file as part of migration.

---

## Final Cleanup

Once all 12 batches are complete:

1. Delete all remaining `src/**/*.tl` source files (kept during migration for cyan's
   benefit). This is the single bulk deletion deferred from the per-file process.
2. Remove `tlconfig.lua`
3. Simplify `Makefile`: remove the `cyan` step; the `$(BUILD_MARKER)` recipe becomes just
   the `cp` loop (or eliminate `build/` entirely — see below)
4. Remove `types/*.d.tl` (replaced by `types/*.lua` with `---@meta`)
4. Consider: can `build/` be eliminated entirely? If `src/` is pointed at in `.busted`, the
   copy step disappears. The `require_trimmer` would need adjustment or removal.
5. Update `CLAUDE.md` to reflect the new toolchain (no `cyan`, add `lua-language-server`)
6. CI: add `lua-language-server --check` alongside the `busted` run

---

## Open Questions

- **`pt.*` API calls in source**: keep the shim API throughout, or replace with standard
  Lua? Keeping it means less diff noise during migration; replacing it improves portability.
- **`build/` directory**: keep for Picotron deployment (which may need the flat `.lua`
  layout), or eliminate and build a separate deployment pipeline.
- **Selene**: worth adding now for early catches, or add after migration is complete to avoid
  two linters fighting.
- **Teal generics on tables**: `MapEntry<K,V>` — LuaCATS supports `---@class Foo<K, V>`
  syntax in recent LLS versions; verify the installed version supports it before committing
  to that pattern.
