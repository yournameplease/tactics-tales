
local box = require("src/tactics/ui/box")
local text_node = require("src/tactics/ui/components/text_node")
local portrait_box = require("src/tactics/ui/panels/portrait_box")
local UIContextManager = require("src/tactics/ui/ui_context_manager").UIContextManager
local StoryMenuContext = require("src/tactics/story/story_menu_context").StoryMenuContext
local story_page = require("src/tactics/story/story_page")
local rendered_story_node = story_page.rendered_story_node
local RenderedStoryNode = rendered_story_node.RenderedStoryNode
local multiple_options_cursor = require("src/tactics/menu/cursor/multiple_options_cursor")
local VerticalMultiSelectMenu = require("src/tactics/ui/panels/vertical_list_multi_select")
local DrawableCharacter = require("src/tactics/story/drawable_character").DrawableCharacter

local record StoryPagePanel
    is box.UIElement

    rendered_nodes: {rendered_story_node.RenderedStoryNode}
end

setmetatable(StoryPagePanel, { __index = box.Box })

local story_page_panel = {}

function story_page_panel.new(props: box.Box): box.UIElement
    props.dir = "col"
    props.gap = props.gap or 4
    props.padding = props.padding or 4
    props.auto_height = props.auto_height or true
    props.cross_stretch = true

    local self = box.new(props) as StoryPagePanel
    setmetatable(self, { __index = StoryPagePanel })

	self.rendered_nodes = {}
    return self
end

function StoryPagePanel:compute_children(state: UIContextManager)
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
            local child: box.UIElement
            if n is rendered_story_node.ChapterHeader then
                child = text_node.new({
                    text = {n.text},
					draw_properties = {
						wrap = "wrap"
					},
                    auto_height = true,
                })
				child = box.flex_col()
                if n.number ~= nil then
                    child:add(text_node.new( { text = {"Chapter "..n.number} } ))
                end
                child:add(text_node.title( { text = {n.text} } ))
            elseif n is rendered_story_node.Text then
                child = text_node.new({
                    text = {n.text},
					draw_properties = {
						wrap = "wrap"
					},
                    auto_height = true,
                })
            elseif n is rendered_story_node.CharacterCustomization then
				child = box.flex_row()

				local cursor = state.story_context.menu_manager.menu_cursor
                if cursor is multiple_options_cursor.MultipleOptionsMenuCursor<StoryMenuContext> then
    				child:add(VerticalMultiSelectMenu.new(
    					"{label}: {value}",
    					"{label}: "..pt.chr(139).."{value}"..pt.chr(145),
    					function (_: UIContextManager): multiple_options_cursor.MultipleOptionsMenuCursor<StoryMenuContext>
    						assert(cursor is multiple_options_cursor.MultipleOptionsMenuCursor<StoryMenuContext>) 
    						return cursor
    					end,
                        {auto_height = true, flex_grow = 1}
    					))
                end
                child:add(portrait_box.new(function(_: UIContextManager): DrawableCharacter
                    return n.character
                end, nil))
            else
                unexpected(n.type)
            end
            pt.add(self.children, child as box.Box)
        end
    end
end

return story_page_panel
