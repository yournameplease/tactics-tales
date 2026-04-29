---@brief
--- Defines the context object for the battle menu system.
--- It provides the menu manager with necessary access to the battle state,
--- such as the battle map and tactics engine.


---@class BattleMenuContext : GameContext
---@field deployment_tiles_tag string Tag identifying tiles available for unit deployment.
---@field battle_map BattleMap
---@field tactics_engine TacticsEngine
---@field handle_start_battle fun() Callback invoked when the player starts the battle.
---@field handle_end_turn fun() Callback invoked when the player ends their turn.
---@field tutorial_mode boolean When true, hides Wait and End Turn to force scripted actions.
local BattleMenuContext = {}
BattleMenuContext.__index = BattleMenuContext

local battle_menu_context = {}

--- Create a new BattleMenuContext.
---@param map BattleMap
---@param tactics TacticsEngine
---@param deployment_tiles_tag string Tag identifying tiles available for deployment.
---@param handle_start_battle fun() Callback invoked when the player starts the battle.
---@param handle_end_turn fun() Callback invoked when the player ends their turn.
---@return BattleMenuContext
function battle_menu_context.new(map, tactics, deployment_tiles_tag, handle_start_battle, handle_end_turn)
    ---@type BattleMenuContext
    local self = setmetatable({}, BattleMenuContext)
    self.battle_map = map
    self.tactics_engine = tactics
    self.deployment_tiles_tag = deployment_tiles_tag
    self.handle_start_battle = handle_start_battle
    self.handle_end_turn = handle_end_turn
    self.tutorial_mode = false
    return self
end

return battle_menu_context
