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
