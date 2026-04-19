# Task: Annotate tactics_puzzler/lib/weapon.lua (weapon factories)

## Goal
Add inline LuaCATS to the weapon factory functions so mods get type
checking when constructing weapons.

## File
`mods/tactics_puzzler/lib/weapon.lua`

## What to annotate

Factory functions — all return `ItemDefinition`:
- `weapon.melee(name, sprite, damage, accuracy, slots, effects?)`
- `weapon.two_handed(name, sprite, damage, accuracy, slots, effects?)`
- `weapon.ranged(name, sprite, damage, accuracy, min_range, max_range, slots, effects?)`
- `weapon.of(name, slots, equip_slot, sprite_data, data)`

Effect helpers — check `src/tactics/types/item_definition.lua` for the
exact type used for equipment_effects entries; likely `EquipmentEffect`:
- `weapon.effect.long_reach()`
- `weapon.effect.shieldsplitter()`
- `weapon.effect.armorkiller()`
- `weapon.effect.shieldkiller()`

Range helper — check src/ for the targeting type name:
- `weapon.range.single_target(min_range, max_range)` → `---@return WeaponTargeting`
  (or the correct type; look at WeaponDefinition.targeting in src/)

## Notes
- Do not change runtime behavior — annotations only.
- Use `---@param effects? EquipmentEffect[]` for optional effects params.

## Verification
- Run `make test`.
- Hover `lib.libs.weapon.melee(...)` in tt_fantasy_demo_story/game_data/items.lua;
  LLS should resolve to `ItemDefinition`.
