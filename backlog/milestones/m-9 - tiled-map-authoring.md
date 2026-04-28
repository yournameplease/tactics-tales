---
id: m-9
title: "tiled-map-authoring"
---

## Description

Replace Picotron's map editor with Tiled for tile authoring and spawn point placement. Build-time converter (Picotron cart) converts Tiled Lua exports + _meta.lua sidecars into Picotron .map files and .spawn.lua coordinate tables. Engine gains a new "tiled" map definition type that reads .spawn.lua instead of the metatile layer, supporting spawn variant groups and active_variants selection in battle definitions.
