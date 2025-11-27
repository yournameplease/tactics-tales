require("src/util/data_utils")

local TurnManager = {}

local PHASE = enum({"PLAYER", "ENEMY"})

local turn = 1
local phase = PHASE.PLAYER

function TurnManager.get_turn()
    return turn
end

BUS.on("TACTICS_BEGIN_PLAYER_TURN", function()
    LOG.info("Begin player turn!")
    phase = PHASE.PLAYER
    battle_manager.tactics_engine:refresh_units()
end)

BUS.on("TACTICS_END_PLAYER_TURN", function()
    if phase ~= PHASE.PLAYER then
        LOG.warn("Got message 'TACTICS_END_PLAYER_TURN', but phase was "..phase..".  Ignoring message.")
        return
    end

    LOG.info("End player turn!")

    BUS.emit("TACTICS_BEGIN_ENEMY_TURN", battle_manager.tactics_engine) -- TODO: global
end)

BUS.on("TACTICS_BEGIN_ENEMY_TURN", function()
    phase = PHASE.ENEMY
    LOG.info("Begin enemy turn!")

end)

BUS.on("TACTICS_END_ENEMY_TURN", function()
    if phase ~= PHASE.ENEMY then
        LOG.warn("Got message 'TACTICS_END_ENEMY_TURN', but phase was "..phase..".  Ignoring message.")
        return
    end
    LOG.info("End enemy turn!")

    turn = turn + 1

    battle_result = battle_manager:check_for_end()

    if not battle_result.finished then
        BUS.emit("TACTICS_BEGIN_PLAYER_TURN")
    else
        BUS.emit(battle_result.command)
    end
end)

BUS.on("BATTLE_END_VICTORY", function()
    LOG.info("You win!")
end)

BUS.on("BATTLE_END_FAILURE", function()
    LOG.info("You lose!")
end)

return TurnManager
