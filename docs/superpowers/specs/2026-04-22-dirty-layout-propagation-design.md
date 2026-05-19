# Dirty Layout Upward Propagation

## Context

When a node marks itself dirty (e.g., `compute_children` regenerates children), only the node itself was flagged. Its parent — unaware — returned early from `measure()` without incorporating the new child size. Siblings with `fill` dimensions were never recalculated. This design adds upward dirty propagation so any ancestor that needs re-measuring gets flagged.

## Design

### Parent reference

Add `parent UIElement?` to `UIElement`. Set it in `Box:add()`, which is the single point where parent-child relationships are formed.

```lua
---@field parent UIElement? nil for the root node and modal roots
```

```lua
function Box:add(child)
    child.parent = self
    table.insert(self.children, child)
    return child
end
```

Modals are treated as root nodes. Change `recalculate_modal` to set children to `{}` and then use `self:add(node)` instead of the direct `self.children = { node }` assignment, so modal children automatically receive a parent ref pointing at the modal element.

### `Box:mark_dirty_layout()`

Replaces all direct `cacheable.dirty_layout = true` writes at call sites where upward propagation is needed.

```lua
-- Future optimization: stop early when all ancestors have fixed numeric
-- width and height, since a fixed-size ancestor's measured rect won't change.
function Box:mark_dirty_layout()
    self.cacheable.dirty_layout = true
    if self.parent then
        self.parent:mark_dirty_layout()
    end
end
```

### Call site changes

| Site | File | Change |
|------|------|--------|
| `build()` init | `box.lua` | Keep as direct assignment — no parent exists at build time |
| `compute_children()` | `box.lua:926` | Replace `self.cacheable.dirty_layout = true` with `self:mark_dirty_layout()` |
| `recalculate_modal()` | `box.lua:1058` | Replace `self.children = { node }` with `self.children = {}; self:add(node)` |

`post_layout()` clears `dirty_layout` directly — no change needed there.

## Tests (TDD — write before implementation)

All new cases go in the existing `describe("tactics.ui.box")` block in `src/spec/ui/box_spec.lua`.

### `Box:mark_dirty_layout`

1. Sets `dirty_layout = true` on self
2. Sets `dirty_layout = true` on parent
3. Sets `dirty_layout = true` on grandparent (transitive)
4. Does not error when called on a root node (no parent)

### `Box:add`

5. Sets `child.parent` to the parent element

### `Box:compute_children`

6. Parent's `dirty_layout` becomes `true` when the generator key changes

## Verification

Run the unit test suite:

```bash
make ut
```

All existing tests must continue to pass. The six new tests must pass. No integration test changes expected.
