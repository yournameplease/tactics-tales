---
id: m-4
title: "proc-story-2-sequence-generation"
---

## Description

Implement beat/filler slot sequences per archetype and the RNG infrastructure. Story seed persists; per-battle seed is derived deterministically from story seed + battle index. Sequence is re-derived on load rather than stored. Encounter templates are sampled without replacement per run.
