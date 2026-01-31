### Tactics Tales

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
