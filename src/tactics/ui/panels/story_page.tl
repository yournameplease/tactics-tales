
require("src/tactics/ui/box")
local DrawTargetManager = require("src/tactics/draw/draw_target_manager").DrawTargetManager
require("src/tactics/ui/components/text_node")
require("src/tactics/ui/panels/portrait_box")
require("src/tactics/character/items/object/item")
require("src/tactics/ui/ui_context_manager")
require("src/tactics/character/items/object/item_inventory")
local wpn = require("src/tactics/character/items/object/weapon")
local story_page = require("src/tactics/story/story_page")
local rendered_story_node = story_page.rendered_story_node
local RenderedStoryNode = rendered_story_node.RenderedStoryNode
local multiple_options_cursor = require("src/tactics/menu/cursor/multiple_options_cursor")
local VerticalMultiSelectMenu = require("src/tactics/ui/panels/vertical_list_multi_select")

local record StoryPage
    is UIElement

    rendered_nodes: {rendered_story_node.RenderedStoryNode}
end

setmetatable(StoryPage, { __index = Box })

local story_page_panel = {}

function story_page_panel.new(props: Box): UIElement
    props.dir = "col"
    props.gap = props.gap or 4
    props.padding = props.padding or 4
    props.auto_height = props.auto_height or true

    local self = Box.new(props) as StoryPage
    setmetatable(self, { __index = StoryPage })

	self.rendered_nodes = {}
    return self
end

function StoryPage:draw(state: UIContextManager, draw_target_manager: DrawTargetManager, ui_theme: UITheme)
    -- TODO: move to a pre-layout step?

    -- why is cast needed?
    local nodes: {RenderedStoryNode} = state.story_context.story_page.nodes as {RenderedStoryNode}

    local any_new_node = false
    for i,n in ipairs(nodes) do
        if self.rendered_nodes[i] ~= n then
            any_new_node = true
        end
    end
    if #nodes ~= #self.rendered_nodes or any_new_node then
        self.children = {}
        self.rendered_nodes = {}
        for _,n in ipairs(nodes) do
            pt.add(self.rendered_nodes, n)
            local child: UIElement
            if n is rendered_story_node.Text then
                child = TextNode.new({
                    text = {n.text},
					draw_properties = {
						-- wrap = "wrap"
					},
					flex_grow = 1,
                })
            elseif n is rendered_story_node.CharacterCustomization then
				child = Box.flex_row()

				child:add(VerticalMultiSelectMenu.new(
					"{label}: {value}",
					"{label}: "..pt.chr(139).."{value}"..pt.chr(145),
					function (state: UIContextManager): multiple_options_cursor.MultipleOptionsMenuCursor<StoryMenuContext>
						local cursor = state.story_context.menu_manager.menu_cursor
						assert(cursor is multiple_options_cursor.MultipleOptionsMenuCursor<StoryMenuContext>) 
						return cursor
					end,
					{flex_grow = 1} ))
            else
                error()
            end
            pt.add(self.children, child as Box)
        end
    end


    Box._draw(self, state, draw_target_manager, ui_theme)
end

return story_page_panel
