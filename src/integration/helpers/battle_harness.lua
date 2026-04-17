-- Stub: battle_harness is not yet implemented. Replaced by Task 8.
local BattleHarness = {}
BattleHarness.__index = BattleHarness

local battle_harness = {}

function battle_harness.new(_overrides)
    return setmetatable({}, BattleHarness)
end

function battle_harness.build_map_fetch(_width, _height, _tile_positions)
    return {}
end

function BattleHarness:register_map_fetch(_path, _data) end
function BattleHarness:start_battle(_battle_id)          end
function BattleHarness:finish_player_turn()              end
function BattleHarness:tick_to_idle()                    end
function BattleHarness:battle_result()      return nil   end
function BattleHarness:emitted(_event_type) return {}    end
function BattleHarness:teardown()                        end

return battle_harness
