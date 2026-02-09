---@brief
--- Defines the context object for the battle menu system.
--- It provides the menu manager with necessary access to the battle state,
--- such as the battle map and tactics engine.

local bm = require("src.tactics.battle.battle_map")
local tactics_engine = require("src.tactics.battle.tactics.tactics_engine")
local menu_context = require("src.tactics.menu.menu_context")
local GameContext = menu_context.GameContext

local record BattleMenuContext
    is GameContext
    deployment_tiles_tag: string
    battle_map: bm.BattleMap
    tactics_engine: tactics_engine.TacticsEngine
    handle_start_battle: function()
end

local battle_menu_context = {
    BattleMenuContext = BattleMenuContext
}

function battle_menu_context.new(
    map: bm.BattleMap,
    tactics: tactics_engine.TacticsEngine,
    deployment_tiles_tag: string,
    handle_start_battle: function()
): BattleMenuContext
    return {
        battle_map = map,
        tactics_engine = tactics,
        deployment_tiles_tag = deployment_tiles_tag,
        handle_start_battle = handle_start_battle
    }
end

return battle_menu_context
