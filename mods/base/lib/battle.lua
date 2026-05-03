local battle = {}

battle.character_source = {}

---@param template string
---@return table
function battle.character_source.template(template)
    return { type = "template", template = template }
end

---@return table
function battle.character_source.player_roster()
    return { type = "player_roster" }
end

battle.victory = {}

---@return table
function battle.victory.rout()
    return { type = "rout", text = "Defeat all enemies" }
end

---@param tag string
---@param text string
---@return table
function battle.victory.defeat_tagged(tag, text)
    return { type = "defeat_tagged", text = text, tag = tag }
end

---@return table
function battle.victory.survive()
    return { type = "survive", text = "Survive" }
end

---@return table
function battle.victory.escape()
    return { type = "escape", text = "Escape" }
end

battle.failure = {}

---@return table
function battle.failure.all_players_die()
    return { type = "all_players_die" }
end

---@param tag string
---@return table
function battle.failure.tagged_unit_dies(tag)
    return { type = "tagged_unit_dies", tag = tag }
end

---@return table
function battle.failure.turn_limit()
    return { type = "turn_limit" }
end

---@type table<string, UnitAI>
battle.ai = {
    default          = { move = "two",      target_sides = {"player", "neutral"}, exclude_tags = {"neutral_enemy"} },
    move_one         = { move = "one",      target_sides = {"player", "neutral"}, exclude_tags = {"neutral_enemy"} },
    move_two         = { move = "two",      target_sides = {"player", "neutral"}, exclude_tags = {"neutral_enemy"} },
    move_inf         = { move = "infinity", target_sides = {"player", "neutral"}, exclude_tags = {"neutral_enemy"} },
    stationary       = { move = "zero",     target_sides = {"player", "neutral"}, exclude_tags = {"neutral_enemy"} },
    stationary_allied  = { move = "zero",     target_sides = {"enemy"},  exclude_tags = {} },
    move_one_allied    = { move = "one",      target_sides = {"enemy"},  exclude_tags = {} },
    move_inf_allied    = { move = "infinity", target_sides = {"enemy"},  exclude_tags = {} },
    stationary_neutral = { move = "zero",     target_sides = {},         exclude_tags = {} },
}

return { battle = battle }
