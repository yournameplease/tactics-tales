---@brief Decorative book-themed UI components: page dividers, section dividers, titles, and page containers.

local box = require("src.tactics.ui.box")

local book = {}

--- Return a vertical decorative spacer styled as the seam between book pages.
---@param width integer
---@return UIElement
function book.page_divider(width)
    return box.builder("page_divider")
    :layout{
        height = "fill",
        width = width,
    }
    :on_draw(function(self, _, _, ui_theme)
        local l = self.rect.x
        local r = self.rect.x + self.rect.w - 1
        local t = self.rect.y
        local b = self.rect.y + self.rect.h

        local w = ((self.rect.w + 1) >> 1) - 1
        for i = 0, w do
            local c_l = i & 1 == 0 and ui_theme.COLOR_DECORATION_PRIMARY or ui_theme.COLOR_DECORATION_HIGHLIGHT
            local c_r = i & 1 == 0 and ui_theme.COLOR_DECORATION_PRIMARY or ui_theme.COLOR_DECORATION_HIGHLIGHT

            pt.line(l + i, t + i, l + i, b, c_l)
            if i < w or w & 1 == 0 then
                pt.line(r - i, t + i, r - i, b, c_r)
            end
        end
    end)
    :build()
end

--- Return a horizontal decorative divider between sections.
---@param height integer
---@return UIElement
function book.section_divider(height)
    return box.builder("section_divider")
    :layout{
        height = height,
        width = "fill",
    }
    :on_draw(function(self, _, _, ui_theme)
        local l = self.rect.x
        local r = self.rect.x + self.rect.w - 1
        local t = self.rect.y
        local h = self.rect.h
        local c = ui_theme.COLOR_PAGE_DECOR

        for i = 0, h - 1 do
            pt.line(l + i, t + i, r - i, t + i, c)
        end
    end)
    :build()
end

--- Return a centered title element with a section divider beneath it.
---@param text_info TextInfoOptions
---@return UIElement
function book.title(text_info)
    text_info.draw_properties = text_info.draw_properties or {}
    text_info.draw_properties.justify = text_info.draw_properties.justify or "center"
    text_info.draw_properties.wrap = "no_wrap"
    text_info.rows = 1

    local self = box.builder("title_box")
        :direction("col")
        :container("block")
        :padding{
            t = 3,
            b = 2,
        }
        :build()

    self:add(
        box.builder("text")
        :text(text_info)
        :build()
    )
    self:add(
        book.section_divider(2)
    )
    return self
end

--- Return a centered title element whose text is computed each update from a state function.
---@param text_function fun(state: UIContextManager): string
---@param text_info TextInfoOptions
---@return UIElement
function book.dynamic_title(text_function, text_info)
    text_info.draw_properties = text_info.draw_properties or {}
    text_info.draw_properties.justify = text_info.draw_properties.justify or "center"
    text_info.draw_properties.wrap = "no_wrap"
    text_info.rows = 1

    local self = box.builder("title_box")
        :direction("col")
        :container("block")
        :padding{
            t = 3,
            b = 2,
        }
        :build()

    self:add(
        box.builder("text")
        :text(text_info)
        :on_update(function(elem, state)
            elem.text.content = { text_function(state) }
        end)
        :build()
    )
    self:add(
        book.section_divider(2)
    )
    return self
end

local TRIM_PADDING = 3

--- Return a decorative container styled as a book cover with a page-stack effect at the bottom.
---@param width integer
---@param height integer
---@param pages_height integer Height of the visible page-stack decoration at the bottom.
---@return UIElement
function book.book_box(width, height, pages_height)
    return box.builder("section_divider")
    :layout{
        dir = "col",
        width = width,
        height = height,
        padding = {
            t = TRIM_PADDING,
            b = TRIM_PADDING + pages_height + 1,
            l = TRIM_PADDING + 1,
            r = TRIM_PADDING,
        },
    }
    :on_draw(function(self, state, draw_target_manager, ui_theme)
        local l = self.rect.x
        local r = self.rect.x + self.rect.w - 1
        local t = self.rect.y
        local b = self.rect.y + self.rect.h - 1
        local p = pages_height

        pt.line(l, t + 1, l, b - 1, ui_theme.COLOR_DECORATION_SHADOW)
        pt.rectfill(l + 1, t + p, r, b, ui_theme.COLOR_DECORATION_SHADOW)

        local p_2 = ((p + 1) >> 1) - 1
        for i = 0, p_2 do
            local c = i & 1 == 0 and ui_theme.COLOR_DECORATION_HIGHLIGHT or ui_theme.COLOR_DECORATION_PRIMARY

            pt.line(l + 1 + i, b - 1 - i, r - 1, b - 1 - i, c)
            if i < p_2 or p_2 & 1 == 0 then
                pt.line(l + 1 + i, b - p + i, r - 1, b - p + i, c)
            end
        end

        pt.rectfill(l + 1, t, r, b - p - 1, ui_theme.COLOR_DECORATION_PRIMARY)
        pt.rect(l + 1 + 2, t + 2, r - 2, b - p - 1 - 2, ui_theme.COLOR_TRIM)

        for _, child in ipairs(self.children) do
            child:draw(state, draw_target_manager, ui_theme)
        end
    end)
    :build()
end

--- Return a full-screen row layout containing left and right pages with a page divider between them.
---@param left UIElement
---@param right UIElement
---@return UIElement
function book.split_pages(left, right)
    local root = box.builder("split_pages")
    :layout{
        dir = "row",
        width = 480,
        height = 270,
        padding = {
            t = 4,
        },
    }
    :build()
    root:add(left)
    root:add(book.page_divider(7))
    root:add(right)

    return root
end

--- Return a flex column page container styled as a panel with standard padding.
---@return UIElement
function book.flex_page()
    return box.builder("book_flex_page")
        :direction("col")
        :container("panel")
        :padding{
            t = 4,
            l = 2,
            r = 2,
            b = 2,
        }
        :style{
            solid = true,
        }
        :build()
end

--- Return a flex page whose title is drawn from `state.game_context.menu_title`, with content nested inside.
---@param content UIElement
---@return UIElement
function book.titled_page(content)
    local page = book.flex_page()

    page:add(book.dynamic_title(
        function(state)
            return state.game_context.menu_title
        end,
        {}
    ))
    local page_content = page:add(box.builder("title_" .. content.id)
        :direction("col")
        :container("panel")
        :padding{
            t = 2,
            l = 2,
            r = 2,
        }
        :build())
    page_content:add(content)

    return page
end

--- Return a strip column page container styled as a panel with standard padding.
---@return UIElement
function book.fit_page()
    return box.builder("book_fit_page")
        :direction("col")
        :container("strip")
        :padding{
            t = 4,
            l = 2,
            r = 2,
            b = 2,
        }
        :style{
            solid = true,
        }
        :build()
end

return book
