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

return { story = story }
