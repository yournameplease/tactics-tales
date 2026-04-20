---@brief
--- The core UI element, implementing a flexbox-like layout system for arranging
--- child elements in rows or columns.

local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
require("src.tactics.ui.theme")
local colors = require("src.tactics.colors")
local MenuMouseSelection = require("src.tactics.menu.menu_cursor").mouse_selection.MenuMouseSelection
local DrawTargetManager = require("src.tactics.draw.draw_target_manager").DrawTargetManager
local text = require("src.tactics.util.text")

-- Note: this class is a bit of a mess with inheritance
-- as I wrote it before fully understanding how to do classes well.
-- may rewrite sometime

-- eventually come from font configuration
local TEXT_HEIGHT = 8
local TEXT_WIDTH = 5
local TEXT_ROW_HEIGHT = TEXT_HEIGHT + 2

---@alias UIDirection "col"|"row"
---@alias DecorationStyle "embossed"|"recessed"|"border"
---@alias UITextColor "dark"|"trim"|"strong"|"light"
---@alias DimensionSpec "fit_content"|"fill"

---@class Padding
---@field t integer
---@field b integer
---@field l integer
---@field r integer

---@class PaddingOptions
---@field t? integer
---@field b? integer
---@field l? integer
---@field r? integer

---@class Style
---@field decoration_padding integer
---@field decoration? DecorationStyle
---@field solid boolean

---@class ComputedRectangle
---@field x integer
---@field y integer
---@field w integer
---@field h integer
---@field c_x integer Content x with padding applied.
---@field c_y integer Content y with padding applied.
---@field c_w integer Content width with padding applied.
---@field c_h integer Content height with padding applied.
---@field depth integer Layout depth, used for debug drawing.

---@class Layout
---@field width integer|DimensionSpec
---@field height integer|DimensionSpec
---@field dir UIDirection
---@field flex_grow integer
---@field gap integer
---@field padding Padding

---@class MenuHandling
---@field hover_event? MenuMouseSelection Return this event directly instead of calling get_selection_at.
---@field get_selection_at? fun(self: UIElement, lx: number, ly: number): MenuMouseSelection

---@class SpriteInfo
---@field s integer Sprite index.
---@field ox integer
---@field oy integer

---@class TextInfo
---@field draw_properties DrawPropertiesOptions
---@field text_color UITextColor
---@field rows integer Fixed row count; height is derived from this if set.
---@field content string[]
---@field line_counts integer[] Per-paragraph line limits for dialogue boxes.
---@field drawn_line integer If set, only this line index is drawn.
---@field text_object Text Cached text layout object.

---@class CacheInfo
---@field draw_target? userdata
---@field static_layout boolean
---@field last_key any
---@field current_key fun(ctx: UIContextManager): any
---@field update_cached fun(self: UIElement, ctx: UIContextManager)
---@field dirty_layout boolean
---@field dirty_draw boolean

---@class ChildrenInfo
---@field last_key any
---@field current_key fun(ctx: UIContextManager): any
---@field generate_children fun(ctx: UIContextManager): UIElement[]

---@class Anchor
---@field target string ID of the anchor node in the UI tree.
---@field ox integer
---@field oy integer

---@class ModalInfo
---@field current_key fun(ctx: UIContextManager): any
---@field compute fun(ctx: UIContextManager): UIElement, Anchor
---@field priorities CardinalDirection[]
---@field anchor_margin integer
---@field screen_padding integer
---@field screen_x number
---@field screen_y number
---@field screen_w number
---@field screen_h number
---@field last_key any
---@field active boolean
---@field anchor Anchor
---@field anchor_node? UIElement Cached anchor node to avoid repeated tree searches.

---@class UIElement
---@field id string Not necessarily unique; for debug help.
---@field rect ComputedRectangle
---@field layout Layout
---@field style Style
---@field menu_handling MenuHandling
---@field sprite SpriteInfo
---@field text TextInfo
---@field child_generator ChildrenInfo
---@field cacheable CacheInfo
---@field modal ModalInfo
---@field data any Custom data for complex elements.
---@field children UIElement[]
---@field add fun(self: UIElement, child: UIElement): UIElement
---@field on_update fun(self: UIElement, ctx: UIContextManager)
---@field find_node_by_id fun(self: UIElement, id: string): UIElement?
---@field custom_draw fun(self: UIElement, ctx: UIContextManager, dtm: DrawTargetManager, theme: UITheme)
---@field draw fun(self: UIElement, ctx: UIContextManager, dtm: DrawTargetManager, theme: UITheme)
---@field draw_modal fun(self: UIElement, ctx: UIContextManager, dtm: DrawTargetManager, theme: UITheme)
---@field recalculate fun(self: UIElement, depth: integer, x: integer, y: integer, w: integer, h: integer, state: UIContextManager, is_dirty: boolean)
---@field recalculate_modal fun(self: UIElement, state: UIContextManager, root: UIElement)
---@field measure fun(self: UIElement, depth: integer, is_dirty: boolean)
---@field apply_layout fun(self: UIElement, parent_x: integer, parent_y: integer, max_w: integer, max_h: integer, is_dirty: boolean)
---@field post_layout fun(self: UIElement)
---@field update fun(self: UIElement, ctx: UIContextManager)
---@field compute_caching fun(self: UIElement, ctx: UIContextManager)
---@field compute_children fun(self: UIElement, ctx: UIContextManager)
---@field compute_text fun(self: UIElement)

---@class Box: UIElement
local Box = {}
Box.__index = Box

local layout = {}

--- Create uniform padding on all sides.
---@param p integer
---@return PaddingOptions
function layout.padding(p)
    return { l = p, r = p, t = p, b = p }
end

local text_info = {}
local anchor = {}

---@alias ContainerPreset "block"|"panel"|"strip"|"modal"

local box = {}

---@class UIElementDef
---@field id string
---@field layout LayoutOptions
---@field style StyleOptions
---@field menu_handling? MenuHandlingOptions
---@field sprite? SpriteInfoOptions
---@field text? TextInfoOptions
---@field child_generator? ChildrenInfo
---@field cacheable? CacheInfo
---@field modal? ModalInfoOptions
---@field rect? ComputedRectangle
---@field data? any
---@field children UIElement[]
---@field on_update? fun(self: UIElement, ctx: UIContextManager)
---@field custom_draw? fun(self: UIElement, ctx: UIContextManager, dtm: DrawTargetManager, theme: UITheme)

---@class UIBuilder
---@field def UIElementDef
local UIBuilder = {}
UIBuilder.__index = UIBuilder

--- Create a new UIBuilder for an element with the given ID.
---@param id string
---@return UIBuilder
function box.builder(id)
    local self = setmetatable({}, UIBuilder)
    self.def = {
        id = id,
        layout = {},
        style = {},
        children = {},
    }
    return self
end

--- Build and return the configured UIElement.
---@return UIElement
function UIBuilder:build()
    ---@diagnostic disable-next-line: missing-fields
    self.def.rect = {}

    if self.def.layout.width == nil then
        self.def.layout.width = "fill"
    end
    if self.def.layout.height == nil then
        self.def.layout.height = "fit_content"
    end
    if self.def.layout.width == "fill" or self.def.layout.height == "fill" then
        self.def.layout.flex_grow = self.def.layout.flex_grow or 1
    end
    self.def.layout.flex_grow = self.def.layout.flex_grow or 0
    self.def.layout.dir = self.def.layout.dir or "col"
    self.def.layout.gap = self.def.layout.gap or 0
    self.def.layout.padding = self.def.layout.padding or {}
    self.def.layout.padding.t = self.def.layout.padding.t or 0
    self.def.layout.padding.b = self.def.layout.padding.b or 0
    self.def.layout.padding.l = self.def.layout.padding.l or 0
    self.def.layout.padding.r = self.def.layout.padding.r or 0

    self.def.style.decoration_padding = self.def.style.decoration_padding or 0

    self.def.cacheable = self.def.cacheable or {}
    self.def.cacheable.dirty_draw = true
    self.def.cacheable.dirty_layout = true

    assert(not (self.def.layout.flex_grow > 0
        and (self.def.layout.width == "fit_content" and self.def.layout.height == "fit_content")),
        "Cannot flex grow with auto_width and auto_height")
    assert(
        self.def.style.decoration_padding == 0
        or (
            self.def.style.decoration_padding <= self.def.layout.padding.t and
            self.def.style.decoration_padding <= self.def.layout.padding.b and
            self.def.style.decoration_padding <= self.def.layout.padding.l and
            self.def.style.decoration_padding <= self.def.layout.padding.r
        )
    )

    if self.def.layout.width == "fit_content"
        and (self.def.text and self.def.text.draw_properties.wrap ~= "no_wrap") then
        error("auto_width must use no_wrap")
    end

    if self.def.text then
        if self.def.text.rows then
            self.def.layout.height = (self.def.text.rows) * (TEXT_HEIGHT + 2)
        end
        self.def.text.content = self.def.text.content or {}

        self.def.text.text_object = text.new(
            self.def.text.content,
            self.def.text.draw_properties,
            0,
            0
        )
    end

    return setmetatable(self.def, { __index = Box }) --[[@as UIElement]]
end

--- Set the flex direction.
---@param dir UIDirection
---@return UIBuilder
function UIBuilder:direction(dir)
    self.def.layout.dir = dir
    return self
end

--- Apply a container dimension preset based on the current flex direction.
---@param preset ContainerPreset
---@return UIBuilder
function UIBuilder:container(preset)
    local dimensions_by_preset = {
        ["block"] = { "fit_content", "fill" },
        ["panel"] = { "fill", "fill" },
        ["strip"] = { "fill", "fit_content" },
        ["modal"] = { "fit_content", "fit_content" },
    }

    local dimensions = dimensions_by_preset[preset]
    if self.def.layout.dir == "row" then
        self.def.layout.width = dimensions[1]
        self.def.layout.height = dimensions[2]
    elseif self.def.layout.dir == "col" then
        self.def.layout.height = dimensions[1]
        self.def.layout.width = dimensions[2]
    else
        error("Should specify direction before using a preset")
    end
    return self
end

--- Set padding. Accepts a uniform integer or a Padding table.
---@param padding integer|PaddingOptions
---@return UIBuilder
function UIBuilder:padding(padding)
    if type(padding) == "number" then
        self.def.layout.padding = layout.padding(padding)
    else
        ---@cast padding PaddingOptions
        self.def.layout.padding = padding
    end
    return self
end

---@class LayoutOptions
---@field width? integer|DimensionSpec
---@field height? integer|DimensionSpec
---@field dir? UIDirection
---@field flex_grow? integer
---@field gap? integer
---@field padding? PaddingOptions

--- Set the full layout spec directly.
---@param box_layout LayoutOptions
---@return UIBuilder
function UIBuilder:layout(box_layout)
    self.def.layout = box_layout
    return self
end

---@class StyleOptions
---@field decoration_padding? integer
---@field decoration? DecorationStyle
---@field solid? boolean

--- Set the draw style.
---@param style StyleOptions
---@return UIBuilder
function UIBuilder:style(style)
    self.def.style = style
    return self
end

---@class MenuHandlingOptions
---@field hover_event? MenuMouseSelection Return this event directly instead of calling get_selection_at.
---@field get_selection_at? fun(self: UIElement, lx: number, ly: number): MenuMouseSelection

--- Set mouse menu interaction handlers.
---@param menu_handling MenuHandlingOptions
---@return UIBuilder
function UIBuilder:menu_handling(menu_handling)
    self.def.menu_handling = menu_handling
    return self
end

---@class SpriteInfoOptions
---@field s? integer The sprite index to display
---@field ox? integer The sprite offset from the content left
---@field oy? integer The sprite offset from the content top

--- Set a sprite to render inside the element.
---@param sprite_props SpriteInfoOptions
---@return UIBuilder
function UIBuilder:sprite(sprite_props)
    self.def.sprite = {
        s = sprite_props.s,
        ox = sprite_props.ox or 0,
        oy = sprite_props.oy or 0,
    }
    return self
end

--- Attach arbitrary custom data to the element.
---@param data any
---@return UIBuilder
function UIBuilder:data(data)
    self.def.data = data
    return self
end

---@class TextInfoOptions
---@field draw_properties? DrawPropertiesOptions
---@field text_color? UITextColor
---@field rows? integer Fixed row count; height is derived from this if set.
---@field content? string[]
---@field line_counts? integer[] Per-paragraph line limits for dialogue boxes.
---@field drawn_line? integer If set, only this line index is drawn.
---@field text_object? Text Cached text layout object.

--- Configure text rendering for the element.
---@param text_props TextInfoOptions
---@return UIBuilder
function UIBuilder:text(text_props)
    self.def.text = text_props or {}

    local draw_properties = self.def.text.draw_properties or {}
    draw_properties.justify = draw_properties.justify or "left"
    draw_properties.direction = draw_properties.direction or "down"
    draw_properties.align = draw_properties.align or false
    draw_properties.wrap = draw_properties.wrap or
        (draw_properties.align and "no_wrap" or "ellipsis")

    self.def.text.draw_properties = draw_properties
    self.def.text.text_color = text_props.text_color or "dark"
    self.def.text.content = text_props.content

    return self
end

--- Enable cached rendering for this element.
---@param cache_info CacheInfo
---@return UIBuilder
function UIBuilder:cacheable(cache_info)
    self.def.cacheable = cache_info
    return self
end

--- Attach a dynamic child generator that rebuilds children when a key changes.
---@param child_generator ChildrenInfo
---@return UIBuilder
function UIBuilder:child_generator(child_generator)
    self.def.child_generator = child_generator
    return self
end

---@class ModalInfoOptions
---@field current_key? fun(ctx: UIContextManager): any
---@field compute? fun(ctx: UIContextManager): UIElement, Anchor
---@field priorities? CardinalDirection[]
---@field anchor_margin? integer
---@field screen_padding? integer
---@field screen_x? number
---@field screen_y? number
---@field screen_w? number
---@field screen_h? number
---@field last_key? any
---@field active? boolean
---@field anchor? Anchor
---@field anchor_node? UIElement Cached anchor node to avoid repeated tree searches.

--- Configure modal positioning for the element.
---@param modal ModalInfoOptions
---@return UIBuilder
function UIBuilder:modal(modal)
    self.def.modal = modal
    return self
end

--- Set a custom draw callback invoked after background and text drawing.
---@param draw fun(self: UIElement, ctx: UIContextManager, dtm: DrawTargetManager, theme: UITheme)
---@return UIBuilder
function UIBuilder:on_draw(draw)
    self.def.custom_draw = draw
    return self
end

--- Set a callback invoked on every update/recalculate pass.
---@param on_update fun(self: UIElement, ctx: UIContextManager)
---@return UIBuilder
function UIBuilder:on_update(on_update)
    self.def.on_update = on_update
    return self
end

-- ---------------------------------------------------------------------------
-- Utility constructors
-- ---------------------------------------------------------------------------

--- Wrap a node in a floating container positioned at (x, y) via padding.
---@param node UIElement
---@param x integer
---@param y integer
---@return UIElement
function box.floating(node, x, y)
    return box.builder(node.id .. "_float_container")
        :layout({
            dir = "row",
            padding = { t = y, l = x },
            height = "fit_content",
            width = "fit_content",
        })
        :build()
        :add(node)
end

--- Create a spacer element that absorbs free space in flex layouts.
---@param grow integer? Defaults to 1.
---@return UIElement
function box.spacer(grow)
    return box.builder("spacer")
        :layout({
            flex_grow = grow or 1,
            width = "fill",
            height = "fill",
        })
        :build()
end

-- ---------------------------------------------------------------------------
-- Box methods
-- ---------------------------------------------------------------------------

--- Add a child element and return it for chaining.
---@param child UIElement
---@return UIElement
function Box:add(child)
    table.insert(self.children, child)
    return child
end

--- The first pass of the layout system. It calculates the
--- intrinsic size of this element. If the element's size is set to 'auto',
--- it will first measure its children to determine its own content-based size.
---@param depth integer
---@param is_dirty boolean
function Box:measure(depth, is_dirty)
    if not is_dirty and not self.cacheable.dirty_layout then
        for _, child in ipairs(self.children) do
            child:measure(depth + 1, false)
        end
        return
    end

    self.rect.depth = depth

    local width = self.layout.width
    local height = self.layout.height
    -- Fixed size: skip child-based measurement but still recurse so children know their size
    if type(width) == "number" and type(height) == "number" then
        self.rect.w = width
        self.rect.h = height
        self.rect.c_w = width - self.layout.padding.l - self.layout.padding.r
        self.rect.c_h = height - self.layout.padding.t - self.layout.padding.b
        for _, child in ipairs(self.children) do
            child:measure(depth + 1, is_dirty or self.cacheable.dirty_layout)
        end
        return
    end

    -- Measure children to determine our own content-driven size
    local content_w, content_h = 0, 0
    local is_row = (self.layout.dir == "row")

    for i, child in ipairs(self.children) do
        child:measure(depth + 1, is_dirty or self.cacheable.dirty_layout)

        -- these could be 0 in case of a "fill" dimension
        local child_outer_w = child.rect.w or 0
        local child_outer_h = child.rect.h or 0

        if is_row then
            content_w = content_w + child_outer_w
            content_h = math.max(content_h, child_outer_h)
            if i > 1 then content_w = content_w + self.layout.gap end
        else
            content_w = math.max(content_w, child_outer_w)
            content_h = content_h + child_outer_h
            if i > 1 then content_h = content_h + self.layout.gap end
        end
    end

    local text_width = 0
    local text_height = 0
    if self.text and self.text.content then
        local text_object = self.text.text_object
        if self.layout.height == "fit_content" then
            local rows = text_object:get_wrapped_rows()
            text_height = rows * TEXT_ROW_HEIGHT
        end
        if self.layout.width == "fit_content" then
            local paragraphs = text_object:get_lines()
            local max_width = 0
            for _, p in ipairs(paragraphs) do
                for _, l in ipairs(p) do
                    if #l > max_width then
                        max_width = #l -- todo: expose width in pixels
                    end
                end
            end
            text_width = max_width * TEXT_WIDTH
        end
    end

    content_w = math.max(content_w, text_width)
    content_h = math.max(content_h, text_height)

    local w = self.layout.width
    if w == "fit_content" then
        self.rect.w = content_w + self.layout.padding.l + self.layout.padding.r
    elseif w == "fill" then
        self.rect.w = nil
    elseif type(w) == "number" then
        self.rect.w = w
    end
    local h = self.layout.height
    if h == "fit_content" then
        self.rect.h = content_h + self.layout.padding.t + self.layout.padding.b
    elseif h == "fill" then
        self.rect.h = nil
    elseif type(h) == "number" then
        self.rect.h = h
    end
end

--- The second pass of the layout system. It arranges the
--- element's children within its own bounds, distributing available space
--- according to each child's flex properties and alignment settings.
---@param parent_x integer
---@param parent_y integer
---@param max_w integer
---@param max_h integer
---@param is_dirty boolean
function Box:apply_layout(parent_x, parent_y, max_w, max_h, is_dirty)
    if not is_dirty and not self.cacheable.dirty_layout then
        for _, child in ipairs(self.children) do
            child:apply_layout(
                self.rect.c_x,
                self.rect.c_y,
                self.rect.c_w,
                self.rect.c_h,
                false
            )
        end
        return
    end

    if self.layout.width == "fill" then
        self.rect.w = max_w
    end
    if self.layout.height == "fill" then
        self.rect.h = max_h
    end
    self.rect.c_h = self.rect.h - self.layout.padding.t - self.layout.padding.b
    self.rect.c_w = self.rect.w - self.layout.padding.l - self.layout.padding.r

    local my_w = self.rect.c_w
    local my_h = self.rect.c_h

    -- Apply our own position (usually passed from parent)
    -- If no parent (root), use self.rect.x/y
    self.rect.x = parent_x
    self.rect.y = parent_y
    self.rect.c_x = parent_x + self.layout.padding.l
    self.rect.c_y = parent_y + self.layout.padding.t

    local is_row = (self.layout.dir == "row")

    -- 1. Calculate free space for flex
    local used_space = 0
    local total_flex = 0

    for i, child in ipairs(self.children) do
        if i > 1 then used_space = used_space + self.layout.gap end

        -- A child flexes if it fills along the main axis and has flex_grow > 0
        local child_should_flex = ((is_row and child.layout.width == "fill")
            or (not is_row and child.layout.height == "fill"))
            and child.layout.flex_grow

        if child_should_flex then
            total_flex = total_flex + child.layout.flex_grow
        else
            if is_row then
                used_space = used_space + child.rect.w
            else
                used_space = used_space + child.rect.h
            end
        end
    end

    -- 2. Distribute children
    local cx = self.rect.x + self.layout.padding.l
    local cy = self.rect.y + self.layout.padding.t
    local total_size = is_row and my_w or my_h
    local remaining = math.max(0, total_size - used_space)
    local px_per_flex = (total_flex > 0) and (remaining / total_flex) or 0

    for _, child in ipairs(self.children) do
        local child_w = child.rect.w
        local child_h = child.rect.h

        local child_should_flex = ((is_row and child.layout.width == "fill")
            or (not is_row and child.layout.height == "fill"))
            and child.layout.flex_grow

        if child_should_flex and total_flex > 0 then
            local added = math.floor(child.layout.flex_grow * px_per_flex)
            if is_row then
                child_w = added
            else
                child_h = added
            end
        end

        if child.layout.height == "fill" then
            if is_row then
                child_h = self.rect.c_h
            end
        end
        if child.layout.width == "fill" then
            if not is_row then
                child_w = self.rect.c_w
            end
        end

        if child.layout then
            child:apply_layout(cx, cy, child_w, child_h, is_dirty or self.cacheable.dirty_layout)
        end

        if is_row then
            cx = cx + child_w + self.layout.gap
        else
            cy = cy + child_h + self.layout.gap
        end
    end
end

--- Mark layout as clean after a full layout pass.
function Box:post_layout()
    self.cacheable.dirty_layout = false
    for _, child in ipairs(self.children) do
        child:post_layout()
    end
end

---@param color_ne Color
---@param color_sw Color
---@param color_interior Color
function Box:draw_shaded(color_ne, color_sw, color_interior)
    local x = self.rect.c_x
    local y = self.rect.c_y
    local w = self.rect.c_w
    local h = self.rect.c_h
    local pad = self.style.decoration_padding
    if pad ~= 0 then
        rectfill(x,           y + pad - 1, x + pad - 1,     y + h - 1,         color_sw)
        rectfill(x,           y + h - 1,   x + w - 1,       y + h - 1,         color_sw)
        rectfill(x,           y,           x + w - 1,       y + pad - 1,       color_ne)
        rectfill(x + w - pad, y,           x + w - 1,       y + h - 1 - pad,   color_ne)
    end
    rectfill(x + pad, y + pad, x + w - 1 - pad, y + h - 1 - pad, color_interior)
end

---@param color_ne Color
---@param color_sw Color
---@param color_interior Color
function Box:draw_shaded_dividers(color_ne, color_sw, color_interior)
    local x = self.rect.c_x
    local y = self.rect.c_y
    local w = self.rect.c_w
    local h = self.rect.c_h
    local pad = self.style.decoration_padding

    if #self.children > 1 and self.layout.gap > 2 * self.style.decoration_padding then
        for i = 2, #self.children do
            if self.layout.dir == "col" then
                local child = self.children[i]
                local c_y = child.rect.c_y
                local gap_h = self.layout.gap
                rectfill(x, c_y - gap_h + pad,     x + w - 1, c_y - pad,             color_interior)
                rectfill(x, c_y - gap_h,           x + w - 1, c_y - gap_h + pad - 1, color_sw)
                rectfill(x, c_y - pad + 1,         x + w - 1, c_y,                   color_ne)
            elseif self.layout.dir == "row" then
                local prev_child = self.children[i]
                local next_child = self.children[i]
                local c_x = next_child.rect.c_x
                local gap_w = self.layout.gap
                local y_prev = prev_child.rect.c_y
                local h_prev = prev_child.rect.h
                local y_next = next_child.rect.c_y
                local h_next = next_child.rect.h
                rectfill(c_x - gap_w + pad, y,      c_x - pad,             y + h - 1,          color_interior)
                rectfill(c_x - gap_w,       y_prev, c_x - gap_w + pad - 1, h_prev + h_prev - 1, color_sw)
                rectfill(c_x - pad + 1,     y_next, c_x,                   y_next + h_next - 1, color_ne)
            end
        end
    end
end

---@param ui_theme UITheme
function Box:draw_embossed(ui_theme)
    self:draw_shaded(ui_theme.COLOR_DECORATION_HIGHLIGHT, ui_theme.COLOR_DECORATION_SHADOW, ui_theme.COLOR_DECORATION_PRIMARY)
end

---@param ui_theme UITheme
function Box:draw_recessed(ui_theme)
    self:draw_shaded(ui_theme.COLOR_DECORATION_SHADOW, ui_theme.COLOR_DECORATION_HIGHLIGHT, ui_theme.COLOR_INTERIOR)
    self:draw_shaded_dividers(ui_theme.COLOR_DECORATION_SHADOW, ui_theme.COLOR_DECORATION_HIGHLIGHT, ui_theme.COLOR_DECORATION_PRIMARY)
end

---@param ui_theme UITheme
function Box:draw_border(ui_theme)
    local d_pad = self.style.decoration_padding
    local x = self.rect.c_x - d_pad
    local y = self.rect.c_y - d_pad
    local w = self.rect.c_w + 2 * d_pad
    local h = self.rect.c_h + 2 * d_pad
    local r = math.max(0, d_pad - 1)
    rrect(x, y, w, h, r, ui_theme.COLOR_PAGE_DECOR)
end

---@param ui_theme UITheme
function Box:draw_solid(ui_theme)
    rrectfill(self.rect.x, self.rect.y, self.rect.w, self.rect.h, 0, ui_theme.COLOR_INTERIOR)
end

--- Draw the background decoration for this element.
---@param ui_theme UITheme
function Box:draw_background(ui_theme)
    if self.style.solid then
        self:draw_solid(ui_theme)
    end
    if self.style.decoration == "embossed" then
        self:draw_embossed(ui_theme)
    elseif self.style.decoration == "recessed" then
        self:draw_recessed(ui_theme)
    elseif self.style.decoration == "border" then
        self:draw_border(ui_theme)
    end
end

--- Draw the text content of this element.
---@param ui_theme UITheme
function Box:draw_text(ui_theme)
    local text_colors = {
        dark   = ui_theme.COLOR_INTERIOR_TEXT,
        trim   = ui_theme.COLOR_TRIM,
        strong = ui_theme.COLOR_PAGE_DECOR,
        light  = ui_theme.COLOR_DECORATION_SHADOW,
    }

    local text_obj = self.text.text_object
    if self.text.drawn_line then
        text_obj:draw_one(
            self.text.drawn_line,
            self.rect.c_x,
            self.rect.c_y,
            text_colors[self.text.text_color],
            self.text.line_counts[self.text.drawn_line]
        )
    else
        text_obj:draw(
            self.rect.c_x,
            self.rect.c_y,
            text_colors[self.text.text_color],
            self.text.line_counts
        )
    end
end

--- Find the topmost UI element whose menu_handling covers the given screen coordinates.
---@param elem UIElement
---@param mx number
---@param my number
---@return MenuMouseSelection?
function box.find_topmost_selection(elem, mx, my)
    for _, child in ipairs(elem.children) do
        local l = child.rect.x
        local r = child.rect.x + child.rect.w
        local t = child.rect.y
        local b = child.rect.y + child.rect.h

        if l <= mx and mx < r and t <= my and my < b then
            log.trace("checking child box for selection", child.id,
                child.rect.c_x, child.rect.c_x + child.rect.c_w,
                child.rect.c_y, child.rect.c_y + child.rect.c_h)
            local child_selection = box.find_topmost_selection(child, mx, my)
            if child_selection ~= nil then
                log.trace("returning hovered selection", child_selection.type)
                return child_selection
            end
        end
    end
    if elem.menu_handling then
        if elem.menu_handling.hover_event then
            return elem.menu_handling.hover_event
        elseif elem.menu_handling.get_selection_at ~= nil then
            log.trace("checking box for selection", elem.id)
            return elem.menu_handling.get_selection_at(elem, mx - elem.rect.c_x, my - elem.rect.c_y)
        end
    end
    return nil
end

--- Find a node in this element's subtree by ID.
---@param id string
---@return UIElement?
function Box:find_node_by_id(id)
    if self.id == id then
        return self
    end
    for _, child in ipairs(self.children) do
        local result = child:find_node_by_id(id)
        if result ~= nil then
            return result
        end
    end
    return nil
end

--- Call on_update callbacks recursively through the element tree.
---@param state UIContextManager
function Box:update(state)
    if self.on_update then
        self:on_update(state)
    end
    for _, child in ipairs(self.children) do
        child:update(state)
    end
end

--- Update any cached subtrees when their key has changed.
---@param state UIContextManager
function Box:compute_caching(state)
    if self.cacheable.update_cached ~= nil then
        local current_key = self.cacheable.current_key(state)
        if current_key ~= self.cacheable.last_key then
            self.cacheable.update_cached(self, state)
            self.cacheable.last_key = current_key
        end
    end
    for _, child in ipairs(self.children) do
        child:compute_caching(state)
    end
end

--- Regenerate dynamic children if the generator key has changed.
---@param state UIContextManager
function Box:compute_children(state)
    if self.child_generator ~= nil then
        local current_key = self.child_generator.current_key(state)
        if current_key ~= self.child_generator.last_key then
            self.children = self.child_generator.generate_children(state)
            self.child_generator.last_key = current_key
            self.cacheable.dirty_layout = true
        end
    end
    for _, child in ipairs(self.children) do
        child:compute_children(state)
    end
end

--- Update the text layout object with current content and available bounds.
function Box:compute_text()
    if self.text ~= nil then
        local lines = self.text.content
        if self.text.rows then
            assert(
                #lines == self.text.rows,
                self.id .. ": `func` should return expected number of rows"
            )
        end
        local text_obj = self.text.text_object
        text_obj:set_width(self.rect.c_w)
        text_obj:set_height(self.rect.c_h)
        text_obj:set_lines(lines)
        text_obj:calculate_wrapping()
    end
    for _, child in ipairs(self.children) do
        child:compute_text()
    end
end

--- Run a full layout recalculation: update → text → measure → apply_layout (twice for text reflow).
---@param depth integer
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param state UIContextManager
---@param is_dirty boolean
function Box:recalculate(depth, x, y, w, h, state, is_dirty)
    if is_dirty then
        log.debug("Dirty layout, recalculating")
    end

    self:compute_caching(state)
    self:compute_children(state)

    self:update(state)
    self:compute_text()
    self:measure(depth, is_dirty)
    self:apply_layout(x, y, w, h, is_dirty)

    self:update(state)
    self:compute_text()
    self:measure(depth, is_dirty)
    self:apply_layout(x, y, w, h, is_dirty)

    if not is_dirty then
        self:post_layout()
    end
end

--- Resolve the modal's position relative to its anchor node using priority-ordered placement.
function Box:resolve_modal_position()
    local priorities = self.modal.priorities or {}

    local r_w = self.rect.w
    local r_h = self.rect.h

    local a_x = self.modal.anchor_node.rect.c_x + self.modal.anchor.ox
    local a_y = self.modal.anchor_node.rect.c_y + self.modal.anchor.oy

    local s_x = self.modal.anchor_node.rect.c_x
    local s_y = self.modal.anchor_node.rect.c_y
    local s_w = self.modal.anchor_node.rect.c_w
    local s_h = self.modal.anchor_node.rect.c_h

    local anchor_margin = self.modal.anchor_margin or 0
    local screen_padding = self.modal.screen_padding or 0
    local total_margin = anchor_margin + screen_padding

    local d_x = 0
    local d_y = 0

    for _, p in ipairs(priorities) do
        if p == "left" then
            if a_x - s_x >= r_w + total_margin then
                d_x = a_x - anchor_margin - r_w
                d_y = a_y - (r_h >> 1)
                break
            end
        elseif p == "right" then
            if s_x + s_w - a_x >= r_w + total_margin then
                d_x = a_x + anchor_margin
                d_y = a_y - (r_h >> 1)
                break
            end
        elseif p == "up" then
            if a_y - s_y >= r_h + total_margin then
                d_x = a_x - (r_w >> 1)
                d_y = a_y - anchor_margin - r_h
                break
            end
        elseif p == "down" then
            if s_y + s_h - a_y >= r_h + total_margin then
                d_x = a_x - (r_w >> 1)
                d_y = a_y + anchor_margin
                break
            end
        end
    end

    d_x = math.max(s_x + screen_padding, d_x)
    d_x = math.min(d_x, s_x + s_w - r_w - screen_padding)
    d_y = math.max(s_y + screen_padding, d_y)
    d_y = math.min(d_y, s_y + s_h - r_h - screen_padding)

    self:apply_layout(d_x, d_y, s_w, s_h, true)
end

--- Recalculate a modal element: recompute its content and reposition relative to its anchor.
---@param state UIContextManager
---@param root UIElement
function Box:recalculate_modal(state, root)
    assert(self.modal ~= nil, "Got a non-modal in the modals! " .. self.id)

    local current_key = self.modal.current_key(state)
    if current_key ~= self.modal.last_key then
        local node, new_anchor = self.modal.compute(state)

        if node == nil then
            self.modal.active = false
        else
            self.modal.active = true
            self.children = { node }
            self.modal.anchor = new_anchor
            self.modal.anchor_node = root:find_node_by_id(new_anchor.target)
        end
        self.modal.last_key = current_key
    end

    if self.modal.active then
        self:compute_children(state)
        self:update(state)
        self:compute_text()
        self:measure(1, true)
        self:resolve_modal_position()
    end
end

--- Draw this element and all children.
---@param state UIContextManager
---@param draw_target_manager DrawTargetManager
---@param ui_theme UITheme
function Box:draw(state, draw_target_manager, ui_theme)
    self:draw_background(ui_theme)
    if self.custom_draw then
        self:custom_draw(state, draw_target_manager, ui_theme)
    end
    if self.text and self.text.content then
        self:draw_text(ui_theme)
    end

    if self.sprite and self.sprite.s then
        spr(
            self.sprite.s,
            self.rect.c_x + self.sprite.ox,
            self.rect.c_y + self.sprite.oy
        )
    end

    if DYNAMIC_CONFIG.draw_flexbox_debug then
        local color = colors.rainbow(self.rect.depth - 1)
        rrect(self.rect.x,   self.rect.y,   self.rect.w,   self.rect.h,   0, color[2])
        rrect(self.rect.c_x, self.rect.c_y, self.rect.c_w, self.rect.c_h, 0, color[1])
    end

    for _, child in ipairs(self.children) do
        child:draw(state, draw_target_manager, ui_theme)
    end
end

--- Draw this element as a modal (only if active).
---@param state UIContextManager
---@param draw_target_manager DrawTargetManager
---@param ui_theme UITheme
function Box:draw_modal(state, draw_target_manager, ui_theme)
    assert(self.modal ~= nil, "Got modal without modal info!" .. self.id)
    if self.modal.active then
        self:draw(state, draw_target_manager, ui_theme)
    end
end

return {
    layout    = layout,
    anchor    = anchor,
    text_info = text_info,
    builder                = box.builder,
    floating               = box.floating,
    spacer                 = box.spacer,
    find_topmost_selection = box.find_topmost_selection,
}
