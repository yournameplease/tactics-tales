---
id: m-24
title: "Engine extraction prep"
---

## Description

Prepare the codebase for extracting a shared engine library (UI, menus, event bus, util) that can be reused by other game projects. This milestone covers decoupling work and a relocation step — it does NOT yet cut the subrepo or commit to a sharing mechanism (submodule vs. subtree). That decision happens after this prep is done and we can validate the engine seam compiles and tests pass in place.
