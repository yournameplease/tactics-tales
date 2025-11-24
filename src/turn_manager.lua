
local TurnManager = {}

local turn = 1

function TurnManager.get_turn()
    return turn
end

BUS.on("TACTICS_BEGIN_PLAYER_TURN", function()
    LOG.info("Begin player turn!")
    TACTICS:refresh_units()
end)

BUS.on("TACTICS_END_PLAYER_TURN", function()
    LOG.info("End player turn!")

    BUS.emit("TACTICS_BEGIN_ENEMY_TURN")
end)

BUS.on("TACTICS_BEGIN_ENEMY_TURN", function()
    LOG.info("Begin enemy turn!")

end)

BUS.on("TACTICS_END_ENEMY_TURN", function()
    LOG.info("End enemy turn!")

    turn = turn + 1

    battle_result = Battle:check_for_end()

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