# Tactics Tales

Picotron Tactics game.  Written in [Teal](https://teal-language.org/).

## About

The game is designed to be moddable.  `mods/` contains mods as Lua files.  `mods/base/` is the base game data, which includes helpful utilities for mods to build off of.

Better modding support, including an in-game modloader, is planned.


## Compilation

Install necessary dependencies:

- teal
- busted

then:

- `make all`: build and test.
- `make test`: test.

## Notes

`lib/` contains various helper utilities in Lua.
`types/` contains type definitions for Lua modules and libs.

## Documentation

Ideally, code should be documented. Documentation comments should use triple hyphens, with the following directives:

- `@brief`
  - One per file, a brief summary of what that file does/contains
- `@desc`
  - Documents the piece of code under it, giving a description. Use for function, record, interface, and enum declarations.
  - These should briefly describe what something is or does, not necessarily how it does it, unless that is relevant. (For example: You should document when a function modifies its arguments)
- If parameters warrant deeper documentation, use LuaCATS annotations `@param`, `@return`, etc.
