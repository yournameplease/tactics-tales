
local TurnManager = {}

BUS.on("TACTICS_BEGIN_PLAYER_TURN", function()
    printh("Begin player turn!")
    TACTICS:refresh_units()
end)

BUS.on("TACTICS_END_PLAYER_TURN", function()
    printh("End player turn!")

    BUS.emit("TACTICS_BEGIN_ENEMY_TURN")
end)

BUS.on("TACTICS_BEGIN_ENEMY_TURN", function()
    printh("Begin enemy turn!")

end)

BUS.on("TACTICS_END_ENEMY_TURN", function()
    printh("End enemy turn!")

    BUS.emit("TACTICS_BEGIN_PLAYER_TURN")
end)

return TurnManager