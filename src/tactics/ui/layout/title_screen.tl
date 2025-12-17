require("src/tactics/systems/service")
require("src/tactics/types")
require("src/tactics/ui/types")

require("src/tactics/battle/battle_context")
require("src/tactics/story/story_context")
require("src/tactics/config")

require("src/tactics/ui/panels/tactics_map")
require("src/tactics/ui/box")
require("src/tactics/ui/components/text_node")
require("src/tactics/ui/panels/unit_info")
require("src/tactics/ui/panels/combat_preview")
require("src/tactics/ui/panels/event_message_log")


require("src/tactics/ui/validator")


local root = Box.new({
    x=0, y=0,
    w=480, h=270,
    internal_margin = {t = 4},
    dir="row",
    transparent = true
})

-- Left Sidebar
root:add(TextNode.new( { text = {"Title Screen"} } ))

return { root = root }
