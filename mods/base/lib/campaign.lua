local campaign = {}

---@param config BattleConfigInput
---@return fun(CampaignConfig): BattleConfig
function campaign.static_battle_config(config)
    return function()
        return {
            permadeath = config.permadeath or true
        }
    end
end

function campaign.new_page()
    return { type = "new_page" }
end

---@param text string
---@param number integer?
function campaign.chapter_header(text, number)
    return {
        type = "chapter_header",
        text = text,
        chapter_number = number,
    }
end

---@param t string
function campaign.text(t)
    return { type = "text", text = t }
end

function campaign.save_game()
    return { type = "save_game" }
end

function campaign.delete_file()
    return { type = "delete_file" }
end

function campaign.advance()
    return { type = "advance" }
end

function campaign.exit_campaign()
    return { type = "exit_campaign" }
end

function campaign.game_results()
    return { type = "game_results" }
end

---@param template string
---@param tags string[]?
function campaign.recruit(template, tags)
    return {
        type = "roster_add",
        template = template,
        tags = tags,
    }
end

---@param battle_id BattleId
---@param branches { victory: NodeId, failure: NodeId }
function campaign.start_battle(battle_id, branches)
    return {
        type = "battle",
        battle_id = battle_id,
        next_node_victory = branches.victory,
        next_node_failure = branches.failure,
    }
end

---@param key string
---@param name_key string
function campaign.character_customizer(key, name_key)
    return {
        type = "character_customizer",
        key = key,
        name_key = name_key,
    }
end

---@param text string
---@param key string
function campaign.text_input(text, key)
    return {
        type = "text_input",
        text = text,
        key = key,
    }
end

---@param key string
---@param value string
function campaign.set_state(key, value)
    return {
        type = "set_memory",
        key = key,
        value = value,
    }
end

---@param next_node string
function campaign.jump(next_node)
    return {
        type = "jump",
        next_node = next_node,
    }
end

---@param target string
---@return DetourNode
function campaign.detour(target)
    return { type = "detour", target = target }
end

---@param options table
---@param state_key string
function campaign.select_option(options, state_key)
    return {
        type = "select_option",
        options = options,
        memory_key = state_key,
    }
end

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
function campaign.state_branch(predicate, node_if_true, node_if_false)
    return function(config, _rng, state)
        if predicate(config, state) then
            return node_if_true
        else
            return node_if_false
        end
    end
end

---@param roster_units string[]
---@param name string
---@param text string
---@param battle_id BattleId
---@return MissionDefinition
function campaign.chapter_debug(roster_units, name, text, battle_id)
    local intro_node = {}
    add(intro_node, campaign.recruit("protagonist", { "hero" }))
    for _, u in ipairs(roster_units) do
        add(intro_node, campaign.recruit(u))
    end
    add(intro_node, campaign.text(text))
    add(intro_node, campaign.start_battle(battle_id, { victory = "victory", failure = "defeat" }))

    return {
        starting_node = "intro",
        name = name,
        description = text or "A single chapter.",
        battle_config = campaign.static_battle_config { permadeath = true },
        nodes = {
            intro = intro_node,
            victory = {
                campaign.text("You Win!"),
                campaign.game_results(),
                campaign.exit_campaign(),
            },
            defeat = {
                campaign.text("You Lose..."),
                campaign.game_results(),
                campaign.exit_campaign(),
            },
        }
    }
end

return { campaign = campaign }
