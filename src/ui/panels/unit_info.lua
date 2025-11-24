local Box = include "src/ui/box.lua"
local TextNode = include "src/ui/panels/text_node.lua"

local UnitInfo = {}
-- Inherit from Box so it behaves like a normal container
setmetatable(UnitInfo, { __index = Box })

function UnitInfo.new(props)
    -- 1. Create the Root Container
    -- We force direction to 'row' because we want [Sprite] | [Stats]
    props.dir = "row"
    props.gap = props.gap or 4
    props.padding = props.padding or 4

    local self = Box.new(props)
    setmetatable(self, { __index = UnitInfo })

    -- ---------------------------------------------------------
    -- LEFT COLUMN: Unit Sprite
    -- ---------------------------------------------------------
    -- We create a fixed-size box for the portrait (e.g., 20x20)
    local portrait_box = Box.new({ w=24, h=24 })

    -- Override the draw method ONLY for this specific box instance
    -- This allows us to inject the CharacterRenderer logic
    function portrait_box:draw(state)
        -- Draw background/debug rect if needed
        Box.draw(self, state)

        local unit = state:get_selected_unit()
        if unit then
            -- Center sprite in the box (assuming 16x16 sprites)
            local spr_x = self.x + (self.w / 2) - 8
            local spr_y = self.y + (self.h / 2) - 8

            -- Use the renderer we defined previously
            unit:draw(spr_x, spr_y, unit.side, true)
        end
    end

    self:add(portrait_box)

    -- ---------------------------------------------------------
    -- RIGHT COLUMN: Stats Text
    -- ---------------------------------------------------------
    -- Fills remaining width (flex_grow=1), stacks vertically (dir="col")
    local info_col = self:add(Box.new({
        flex_grow = 1,
        dir = "col",
        gap = 2
    }))

    -- ROW 1: Name and Level
    info_col:add(TextNode.new({
        func = function(state)
            local u = state:get_selected_unit()
            if not u then return { "No Unit Selected" } end
            return { u.name .. " Lv." .. 1 }
        end
    }))

    -- ROW 2-4: HP, Weapon
    info_col:add(TextNode.new({
        rows = 3,
        func = function(state)
            local u = state:get_selected_unit()
            if not u then return { "", "", "" } end

            local w = u.weapon

            return {
                "HP: " .. u.hp_current .. "/" .. u.hp_max,
                w and w.name or "Unarmed",
                w and ("(" .. w.accuracy .. "% for " .. w.damage .. " dmg)") or "",
            }
        end
    }))

    return self
end

return UnitInfo