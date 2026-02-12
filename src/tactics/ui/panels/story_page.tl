---@brief
--- The main panel for rendering the content of a story page.

local box = require("src.tactics.ui.box")
local text_node = require("src.tactics.ui.components.text_node")
local dialogue_node = require("src.tactics.ui.components.dialogue_node")
local portrait_box = require("src.tactics.ui.panels.portrait_box")
local section_divider = require("src.tactics.ui.decoration.section_divider")
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
local nested_list = require("src.tactics.menu.cursor.nested.list")
local story_page = require("src.tactics.story.story_page")
local rendered_story_node = story_page.rendered_story_node
local RenderedStoryNode = rendered_story_node.RenderedStoryNode
local DrawableCharacter = require("src.tactics.story.drawable_character").DrawableCharacter

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
    local rendered_page = state.story_context.story_page
    local nodes: {RenderedStoryNode} = rendered_page.nodes as {RenderedStoryNode}

    local any_new_node = false
    for i,n in ipairs(nodes) do
        if self.rendered_nodes[i] ~= n then
            any_new_node = true
        end
    end
    if #nodes ~= #self.rendered_nodes or any_new_node then
        self.rendered_nodes = {}
        self.children = {}
        local page_contents: {box.UIElement} = {}

        local is_chapter_header_page = false
        for _,n in ipairs(nodes) do
            pt.add(self.rendered_nodes, n)
            local child: box.UIElement
            if n is rendered_story_node.ChapterHeader then
                is_chapter_header_page = true
				child = box.flex_col()
                if n.number ~= nil then
                    child:add(text_node.new( {
                        text = {"Chapter "..n.number},
                        text_color = "light",
    					draw_properties = {
    						wrap = "wrap"
    					},
                        auto_height = true,
                    } ))
                end
                child:add(text_node.title( {
                    text = {n.text},
					draw_properties = {
						wrap = "wrap"
					},
                    auto_height = true,
                } ))
            elseif n is rendered_story_node.Text then
                child = dialogue_node.new({
                    dialogue = n.text,
					draw_properties = {
						wrap = "wrap"
					},
                    auto_height = true,
                })
            elseif n is rendered_story_node.CharacterCustomization then
				child = box.flex_row()

				local root_node = state.story_context.menu_manager.menu_step.node
                if root_node is nested_list.NestedMenuNode then
    				-- child:add(VerticalMultiSelectMenu.new(
    				-- 	"{label}: {value}",
    				-- 	"{label}: "..pt.chr(139).."{value}"..pt.chr(145),
    				-- 	function (_: UIContextManager): nested_list.NestedMenuNode
        --             		local node = root_node
        --             		assert(node is nested_list.NestedMenuNode) 
        --             		return node
    				-- 	end,
        --                 {auto_height = true, flex_grow = 1}
    				-- 	))
                end
                child:add(portrait_box.new(function(_: UIContextManager): DrawableCharacter
                    return n.character
                end, nil))
            else
                unexpected(n.type)
            end
            pt.add(page_contents, child as box.Box)
        end

        if is_chapter_header_page then
			local page = box.flex_col()
            page:add(box.spacer(1))
            local page_content_box = box.flex_col()
            for _,b in ipairs(page_contents) do
                page_content_box:add(b)
            end
            page:add(page_content_box)
            page:add(box.spacer(1))
            
            self.children = {page}
        else
            local page = box.flex_col()
            if rendered_page.chapter_text ~= nil then
                local num_text = rendered_page.chapter_number
                    and tostring(rendered_page.chapter_number)
                    or ""
                local chapter_text = rendered_page.chapter_text
                page:add(text_node.new( {
                    text = {num_text.."|"..chapter_text.."|"},
                    text_color = "light",
					draw_properties = {
                        align = true
					},
                    auto_height = true,
                }))
                page:add(section_divider.new(1))
            end
            local page_content_box = box.flex_col()

            for _,b in ipairs(page_contents) do
                page_content_box:add(b)
            end

            page:add(page_content_box)
            page:add(box.spacer(1))
            
            self.children = {page}
        end
    end
end

return story_page_panel
