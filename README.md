# Tactics Tales

Picotron Tactics game.  Written in Lua.

## About

The game is designed to be moddable.  `mods/` contains mods as Lua files.  `mods/base/` is the base game data, which includes helpful utilities for mods to build off of.

## Compilation

Install necessary dependencies:

- lua-language-server
- busted
- luassert

Use the makefile to test:

```bash
make all        # clean, build, and test
make test       # build and run all tests (unit + integration)
make ut         # build and run unit tests only (excludes --tags='it')
make it         # build and run integration tests only (--tags='it')
make clean      # remove build/ artifacts
```
