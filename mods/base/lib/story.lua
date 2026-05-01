local story = {}

---@param predicate fun(config: StoryConfig): boolean
---@param node_if_true StoryNode
---@param node_if_false StoryNode
---@return StoryNodeFactory
function story.config_branch(predicate, node_if_true, node_if_false)
    return function(config)
        if predicate(config) then
            return node_if_true
        else
            return node_if_false
        end
    end
end

---@param predicate fun(config: StoryConfig, state: table<string, string>): boolean
---@param node_if_true StoryNode
---@param node_if_false StoryNode
---@return StoryNodeFactory
function story.memory_branch(predicate, node_if_true, node_if_false)
    return function(config, _rng, state)
        if predicate(config, state) then
            return node_if_true
        else
            return node_if_false
        end
    end
end

---@param target string
---@return DetourNode
function story.detour(target)
    return { type = "detour", target = target }
end

return { story = story }
