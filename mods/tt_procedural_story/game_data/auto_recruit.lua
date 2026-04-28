local story_memory_mod = include("src/tactics/story/story_memory.lua")

--- Process pending recruits after a battle and clear the pending list.
--- Initial implementation logs the list for debugging only; actual roster
--- integration (turncoat capture, wanderer fallback) is a future extension.
---@param mem StoryMemory
---@return string debug_text
local function auto_recruit_pending(mem)
    local pending_entry = mem:get("pending_recruits")
    local values = {}
    if pending_entry then
        ---@cast pending_entry ListMemoryEntry
        values = pending_entry.values
    end

    local list_str = #values > 0 and table.concat(values, ", ") or "none"
    mem:set("pending_recruits", story_memory_mod.list({}))

    return string.format("[auto_recruit] Pending recruits processed: %s.", list_str)
end

return {
    auto_recruit_pending = auto_recruit_pending,
}
