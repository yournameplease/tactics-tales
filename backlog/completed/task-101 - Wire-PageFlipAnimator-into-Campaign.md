---
id: TASK-101
title: Wire PageFlipAnimator into Campaign
status: Done
assignee: []
created_date: '2026-05-08 04:32'
updated_date: '2026-05-08 04:53'
labels: []
milestone: m-15
dependencies:
  - TASK-96
ordinal: 7000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Instantiate and connect `PageFlipAnimator` within the campaign lifecycle.

**`src/tactics/campaign/campaign.lua`:**
- `require` the new module
- In `campaign.new(...)`, after creating `self.campaign_page`, add: `self.page_flip_animator = page_flip_animator.new()`

**`src/tactics/campaign/handlers/node_handlers.lua`:**
- Replace the `new_page.enter` body:
  ```lua
  new_page = {
      enter = function(campaign)
          campaign.page_flip_animator:begin_flip("forward", function()
              campaign.campaign_page:clear_page()
              campaign:advance_node()
          end)
      end,
  },
  ```

**Unit tests:**
- Campaign constructed with a `page_flip_animator` field that responds to `begin_flip`
- `new_page` handler calls `begin_flip` with direction `"forward"` and a callback that clears the page and advances the node
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 campaign.page_flip_animator is non-nil after campaign.new()
- [x] #2 new_page handler calls page_flip_animator:begin_flip (verified via spy/stub in unit test)
- [x] #3 Callback passed to begin_flip calls clear_page and advance_node
- [x] #4 `make test` passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
