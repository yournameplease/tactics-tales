---@brief
--- The main panel for rendering the content of a story page.

local box = require("src.tactics.ui.box")
local dialogue_node = require("src.tactics.ui.components.dialogue_node")
local character_ui = require("src.tactics.ui.panels.portrait_box")
local book = require("src.tactics.ui.decoration.book")
local menu_ui = require("src.tactics.ui.components.menu")

local story_page_ui = {}

--- Build the chapter title card panel for a chapter header node.
---@param node RenderedChapterHeader
---@return UIElement
local function chapter_header_page(node)
    local root = box.builder("chapter_title")
        :direction("col")
        :container("block")
        :build()
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
    root:add(book.title{
        content = {node.text},
        draw_properties = {
            wrap = "wrap"
        },
    })

    return root
end

--- Build the chapter results content block for one chapter page.
---@param chapter GameResultsChapterDisplay
---@return UIElement
local function chapter_results_section(chapter)
    local root = box.builder("chapter_results")
        :direction("col")
        :container("block")
        :build()

    root:add(book.title{content = {"Chapter "..chapter.chapter_number}})

    local result_label = chapter.result == "VICTORY" and "Victory" or "Defeat"
    root:add(box.builder("result_line")
        :text{
            content = {result_label.." in "..chapter.turns_taken.." turns"},
            draw_properties = {wrap = "wrap", justify = "left"},
        }
        :build())

    local lost_label = #chapter.units_lost_names > 0 and "Units Lost" or "No casualties"
    root:add(box.builder("units_lost_label")
        :text{
            content = {lost_label},
            draw_properties = {wrap = "wrap", justify = "left"},
        }
        :build())

    for _, name in ipairs(chapter.units_lost_names) do
        root:add(box.builder("unit_lost")
            :text{
                content = {name},
                draw_properties = {wrap = "wrap", justify = "left"},
            }
            :build())
    end

    return root
end

--- Build the unit results content block for one unit page.
---@param unit_display GameResultsUnitDisplay
---@return UIElement
local function unit_results_section(unit_display)
    local row = box.builder("unit_results")
        :direction("row")
        :container("strip")
        :padding(8)
        :style{
            decoration = "border",
            decoration_padding = 5,
        }
        :build()

    local drawable = unit_display.drawable

    local palette = "paper"
    row:add(character_ui.portrait_box(function(_) return drawable end, palette))

    local stats = box.builder("unit_stats")
        :direction("col")
        :container("block")
        :build()

    stats:add(book.title{content = {unit_display.name}})

    if unit_display.chapter_recruited ~= nil then
        stats:add(box.builder("unit_recruited")
            :text{
                content = {"Recruited: Ch. "..unit_display.chapter_recruited},
                draw_properties = {wrap = "wrap", justify = "left"},
            }
            :build())
    end

    stats:add(box.builder("unit_combats")
        :text{
            content = {"Combats: "..unit_display.combats},
            draw_properties = {wrap = "wrap", justify = "left"},
        }
        :build())

    stats:add(box.builder("unit_kills")
        :text{
            content = {"Kills: "..unit_display.kills},
            draw_properties = {wrap = "wrap", justify = "left"},
        }
        :build())

    row:add(stats)
    return row
end

--- Build the full page for a game results node.
---@param node RenderedGameResults
---@return UIElement
local function game_results_page(node)
    local page = box.builder("story_page")
        :direction("col")
        :container("panel")
        :build()

    local header_box = box.builder("story_page_header")
        :direction("col")
        :container("block")
        :build()
    header_box:add(box.builder("chapter_header_line")
        :text{
            content = {"|Results|"},
            text_color = "light",
            draw_properties = {align = true},
        }
        :build())
    header_box:add(book.section_divider(1))
    page:add(header_box)

    local content_box = box.builder("story_page_content")
        :direction("col")
        :container("block")
        :padding{t = 2, l = 2, r = 2}
        :build()

    if node.section == "chapters" then
        content_box:add(chapter_results_section(node.chapter_pages[node.page]))
    else
        content_box:add(unit_results_section(node.unit_pages[node.page]))
    end

    page:add(content_box)
    page:add(box.spacer(1))
    return page
end

--- Build a multi-line text panel for a text node.
---@param node RenderedText
---@return UIElement
local function story_text_page(node)
    return dialogue_node.multi_line(
        node.text,
        {
            draw_properties = {
                wrap = "wrap",
                justify = "left",
            }
        }
    )
end

--- Generate the list of child UI elements for the current story page state.
---@param state UIContextManager
---@return UIElement[]
local function compute_children(state)
    local rendered_page = state.story_context.story_page
    local nodes = rendered_page.nodes

    ---@type UIElement[]
    local content = {}

    local is_chapter_header_page = false

    for _, n in ipairs(nodes) do
        local child

        if n.type == "chapter_header" then
            ---@cast n RenderedChapterHeader
            child = chapter_header_page(n)
            is_chapter_header_page = true
        elseif n.type == "text" then
            ---@cast n RenderedText
            child = story_text_page(n)
        elseif n.type == "character_customization" then
            ---@cast n RenderedCharacterCustomization
            child = box.builder("character_customizer")
                :direction("row")
                :container("strip")
                :build()

            local root_node = state.story_context.menu_manager.menu_step.node
            if root_node.type == "list" then
                child:add(menu_ui.generic_menu_box(
                    function(_) return 1 end,
                    function(_) return root_node end
                ))
            end
            ---@type "default"|"paper"
            local palette = nil
            child:add(character_ui.portrait_box(function(_)
                return n.character
            end, palette))
        elseif n.type == "game_results" then
            ---@cast n RenderedGameResults
            return {game_results_page(n)}
        elseif n.type == "text_input" then
            local root_node = state.story_context.menu_manager.menu_step.node
            child = menu_ui.generic_menu_box(
                function(_) return 1 end,
                function(_) return root_node end
            )
        else
            unexpected(n.type)
        end

        table.insert(content, child)
    end

    if is_chapter_header_page then
        local page = box.builder("story_page")
            :direction("col")
            :container("panel")
            :build()
        page:add(box.spacer(1))
        local page_content_box = box.builder("story_page_header")
            :direction("col")
            :container("block")
            :build()
        for _, b in ipairs(content) do
            page_content_box:add(b)
        end
        page:add(page_content_box)
        page:add(box.spacer(1))

        return {page}
    else
        local page = box.builder("story_page")
            :direction("col")
            :container("panel")
            :build()
        if rendered_page.chapter_text ~= nil then
            local header_box = box.builder("story_page_header")
                :direction("col")
                :container("block")
                :build()
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
        local page_content_box = box.builder("story_page_content")
            :direction("col")
            :container("block")
            :padding{
                t = 2,
                l = 2,
                r = 2,
            }
            :build()

        for _, b in ipairs(content) do
            page_content_box:add(b)
        end

        page:add(page_content_box)
        page:add(box.spacer(1))

        return {page}
    end
end

--- Create the story content panel, which regenerates its children when the story revision changes.
---@return UIElement
function story_page_ui.new()
    local content = box.builder("story_content")
        :layout{
            width = "fill",
            height = "fill",
        }
        :child_generator{
            current_key = function(state)
                return state.story_context.story_page.story_revision
            end,
            generate_children = compute_children,
        }
        :build()

    return content
end

return story_page_ui
