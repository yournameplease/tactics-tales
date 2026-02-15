---@brief
--- The main panel for rendering the content of a story page.

local box = require("src.tactics.ui.box")
local text_node = require("src.tactics.ui.components.text_node")
local dialogue_node = require("src.tactics.ui.components.dialogue_node")
local character_ui = require("src.tactics.ui.panels.portrait_box")
local book = require("src.tactics.ui.decoration.book")
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
local nested_list = require("src.tactics.menu.cursor.nested.list")
local story_page = require("src.tactics.story.story_page")
local rendered_story_node = story_page.rendered_story_node
local RenderedStoryNode = rendered_story_node.RenderedStoryNode
local menu_ui = require("src.tactics.ui.components.menu")
local menu_cursor = require("src.tactics.menu.menu_cursor")
local MenuNode = menu_cursor.MenuNode
local DrawableCharacter = require("src.tactics.story.drawable_character").DrawableCharacter

local story_page = {}

local function chapter_header_page(node: rendered_story_node.ChapterHeader): box.UIElement
	local root = box.col_fill()
    if node.number ~= nil then

        root:add(box.builder("chapter_number")
            :layout{
                height = "fit_content"
            }
            :text{
                content = {"Chapter "..node.number},
                text_color = "light",
    			draw_properties = {
    			    justify = "center",
    				wrap = "wrap",
    			},
			}
			:build())
    end
    root:add(text_node.title{
        content = {node.text},
		draw_properties = {
			wrap = "wrap"
		},
    })

    return root
end

local function story_text_page(node: rendered_story_node.Text): box.UIElement
    return dialogue_node.multi_line(
        node.text,
    	{
    	    draw_properties = {
        		wrap = "wrap",
        	}
    	}
    )
end

local function compute_children(state: UIContextManager): {box.UIElement}
    -- why is cast needed?
    local rendered_page = state.story_context.story_page
    local nodes: {RenderedStoryNode} = rendered_page.nodes as {RenderedStoryNode}

    local content: {box.UIElement} = {}

    local is_chapter_header_page = false
    for _,n in ipairs(nodes) do
        local child: box.UIElement

        if n is rendered_story_node.ChapterHeader then
            child = chapter_header_page(n)
        elseif n is rendered_story_node.Text then
            child = story_text_page(n)
        elseif n is rendered_story_node.CharacterCustomization then
			child = box.row_fill()

			local root_node = state.story_context.menu_manager.menu_step.node
            if root_node is nested_list.NestedMenuNode then
                child:add(menu_ui.generic_menu_box(
                	function (_: UIContextManager): integer return 1 end,
                	function (_: UIContextManager): MenuNode
                		local node = root_node
                		return node
                	end
                ))
            end
            child:add(character_ui.portrait_box(function(_: UIContextManager): DrawableCharacter
                return n.character
            end, nil))
        else
            unexpected(n.type)
        end

        pt.add(content, child)
    end

    if is_chapter_header_page then
		local page = box.col_fill()
        page:add(box.spacer(1))
        local page_content_box = box.col_fit()
        for _,b in ipairs(content) do
            page_content_box:add(b)
        end
        page:add(page_content_box)
        page:add(box.spacer(1))
        
        return {page}
    else
        local page = box.col_fill()
        if rendered_page.chapter_text ~= nil then
            local header_box = box.col_fit()
            local num_text = rendered_page.chapter_number
                and tostring(rendered_page.chapter_number)
                or ""
            local chapter_text = rendered_page.chapter_text
            header_box:add(box.builder("chapter_header_line")
                :text{
                    content = {num_text.."|"..chapter_text.."|"},
                    text_color = "light",
        			draw_properties = {
                        align = true
        			},
                }
                :build())
            header_box:add(book.section_divider(1))
            page:add(header_box)
        end
        local page_content_box = box.col_fit()

        for _,b in ipairs(content) do
            page_content_box:add(b)
        end

        page:add(page_content_box)
        page:add(box.spacer(1))
        
        return {page}
    end
end

function story_page.new(): box.UIElement
    local content = box.builder("story_content")
        :layout{
            width = "fill",
            height = "fill",
        }
        :child_generator{
            current_key = function(state: UIContextManager): integer
                return state.story_context.story_page.story_revision
            end,
            generate_children = compute_children,
        }
        :build()

    return content
end

return story_page
