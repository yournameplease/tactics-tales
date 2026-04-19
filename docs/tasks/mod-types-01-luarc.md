# Task: Verify mods/ is in LLS workspace

## Goal
Ensure Lua Language Server scans the mods/ directory so annotations in
mods/types.d.lua and mod content files are resolved.

## File
`.luarc.json` — check the `workspace.library` or `workspace.userThirdParty`
arrays. If `mods/` is not listed, add it.

## Verification
After change: open any mod file in an LLS-enabled editor; hovering a type
from mods/types.d.lua should resolve (not show as `unknown`).

## Notes
- Do not change anything else in .luarc.json.
- Run `make test` after to confirm nothing broke.
