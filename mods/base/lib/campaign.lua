local campaign = {}

---@param predicate fun(config: CampaignConfig): boolean
---@param node_if_true CampaignNode
---@param node_if_false CampaignNode
---@return CampaignNodeFactory
function campaign.config_branch(predicate, node_if_true, node_if_false)
    return function(config)
        if predicate(config) then
            return node_if_true
        else
            return node_if_false
        end
    end
end

---@param predicate fun(config: CampaignConfig, state: table<string, string>): boolean
---@param node_if_true CampaignNode
---@param node_if_false CampaignNode
---@return CampaignNodeFactory
function campaign.memory_branch(predicate, node_if_true, node_if_false)
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
function campaign.detour(target)
    return { type = "detour", target = target }
end

return { campaign = campaign }
