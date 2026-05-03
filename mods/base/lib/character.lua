local character = {}

character.options = {}

---@param opts string[]
---@return ListOptions
function character.options.list(opts)
    return { type = "list", options = opts }
end

---@param opts table<string, integer>
---@return WeightedOptions
function character.options.weighted(opts)
    return { type = "weighted", options = opts }
end

return { character = character }
