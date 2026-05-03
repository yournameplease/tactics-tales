--- Forced-join helper for the procedural campaign mod.
---
--- A slot may declare a forced_join template ID.  When it does, the
--- post-battle sequence emits a roster_add node directly (bypassing the
--- recruitment-quota system) so the character is added with no player prompt
--- and no credits consumed.  Works for both beat and filler slots.

--- Return the campaign node that should be executed for forced joining.
--- If the slot has a forced_join template, returns a roster_add node.
--- Otherwise returns an advance node so the sequence step is a no-op.
---@param slot ArchetypeSlot
---@return table
local function forced_join_node(slot)
    if slot and slot.forced_join then
        return { type = "roster_add", template = slot.forced_join, tags = {} }
    end
    return { type = "advance" }
end

return {
    forced_join_node = forced_join_node,
}
