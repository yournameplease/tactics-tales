---@brief
--- The core UI element, implementing a flexbox-like layout system for arranging
--- child elements in rows or columns.

local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
require("src.tactics.ui.theme")
local colors = require("src.tactics.colors")
local MenuMouseSelection = require("src.tactics.menu.menu_cursor").mouse_selection.MenuMouseSelection
local DrawTargetManager = require("src.tactics.draw.draw_target_manager").DrawTargetManager
local text = require("src.tactics.util.text")

-- Note: this class is a bit of a mess with inheritence
-- as I wrote it before fully understanding how to do classes well.
-- may rewrite sometime

-- eventually come from font configuration
local TEXT_HEIGHT = 8
local TEXT_WIDTH = 5
local TEXT_ROW_HEIGHT = TEXT_HEIGHT + 2

local record Padding
    t: integer
    b: integer
    l: integer
    r: integer
end

local enum UIDirection
    "col"
    "row"
end

local enum DecorationStyle
    "embossed"
    "recessed"
    "border"
end

local enum UITextColor
    "dark"
    "trim"
    "strong"
    "light"
end

---@desc
--- Draw style for a UI element
local record Style
    decoration_padding: integer
    decoration: DecorationStyle
    transparent: boolean
end

---@desc
--- Computed layout for a UI element
local record ComputedRectangle
    -- content x/y/w/h in case of padding
    x: integer
    y: integer
    w: integer
    h: integer
    -- content x/y/w/h in case of padding
    c_x: integer
    c_y: integer
    c_w: integer
    c_h: integer
    depth: integer -- more for debug drawing
end

local enum DimensionSpec
    "auto"
    "fill"
end

---@desc
--- Layout specification for a UI element
local record Layout
    -- Dimensions
    width: integer | DimensionSpec
    height: integer | DimensionSpec

    -- Flex
    dir: UIDirection
    flex_grow: integer

    -- Spacing
    gap: integer
    padding: Padding
end

local layout = {
    Layout = Layout,
}

---@desc
--- Mouse-menu interaction handlers for a UI element
local record MenuHandling
    -- if present, return this instead of calling the handler
    hover_event: MenuMouseSelection
    -- nillable
    get_selection_at: function(self, lx: number, ly: number): MenuMouseSelection
end

local record SpriteInfo
    s: integer
    ox: integer
    oy: integer
end

local record TextInfo
    draw_properties: text.DrawProperties
    text_color: UITextColor
    rows: integer

    content: {string}
    -- if non-nil, use to limit the text, for dialogue boxes
    line_counts: {integer}
    -- if non-nil, only draw the line with the given index
    drawn_line: integer

    -- caching
    text_object: text.Text
end

local text_info = {
    TextInfo = TextInfo
}

local record CacheInfo
    draw_target: Userdata | nil

    last_key: any
    current_key: function(self: UIElement, ctx: UIContextManager): any
    update_cached: function(self: UIElement, ctx: UIContextManager): any

    dirty_layout: boolean
    dirty_draw: boolean
end

local record ChildrenInfo
    last_key: any
    current_key: function(ctx: UIContextManager): any
    generate_children: function(ctx: UIContextManager): { UIElement }
end


local interface UIElement
    -- Not necessarily unique.  For debug help.
    id: string
    
    rect: ComputedRectangle
    layout: Layout
    style: Style
    menu_handling: MenuHandling
    sprite: SpriteInfo
    text: TextInfo
    child_generator: ChildrenInfo
    cacheable: CacheInfo
    -- custom data for complex elements.  Passed to some handlers
    data: any

    -- nillable, for dynamic children
    compute_children: function(self, UIContextManager)

    children: { UIElement }
    add: function(self, UIElement): UIElement

    on_update: function(self: UIElement, UIContextManager)
    custom_draw: function(self: UIElement, UIContextManager, DrawTargetManager, UITheme)
    draw: function(self, UIContextManager, DrawTargetManager, UITheme)
    recalculate: function(self, depth: integer, x: integer, y: integer, state: UIContextManager) 
end

local record Box
    is UIElement
end

local box = {
    Padding = Padding,
    UIDirection = UIDirection,
    DecorationStyle = DecorationStyle,
    UIElement = UIElement,
    Box = Box,
    layout = layout,
    text_info = text_info,
}

local record UIBuilder
    def: UIElement
end

function box.builder(id: string): UIBuilder
    -- validate
    
    local self: UIBuilder = setmetatable({}, { __index = UIBuilder})
    self.def = {
        id = id,
        layout = {},
        style = {},
        children = {},
    }
    return self
end

function UIBuilder:build(): UIElement
    assert(not (self.def.layout.flex_grow > 0  and (self.def.layout.width == "auto" and self.def.layout.height == "auto")), "Cannot flex grow with auto_width and auto_height")
    assert(
        self.def.style.decoration_padding == 0
        or
        (
            self.def.style.decoration_padding < self.def.layout.padding.t and
            self.def.style.decoration_padding < self.def.layout.padding.b and
            self.def.style.decoration_padding < self.def.layout.padding.l and
            self.def.style.decoration_padding < self.def.layout.padding.r
        )
    )

    if self.def.layout.width == "auto"
        and (self.def.text and self.def.text.draw_properties.wrap ~= "no_wrap") then
        error("auto_width must use no_wrap")
    end

    if self.def.text.rows and self.def.layout.height == nil then
        self.def.layout.height = (self.def.text.rows) * (TEXT_HEIGHT + 2)
    end

    return setmetatable(self.def, {
        __index = Box
    })
end

function UIBuilder:layout(box_layout: Layout): UIBuilder
    self.def.layout = box_layout
    return self
end

function UIBuilder:style(style: Style): UIBuilder
    self.def.style = style
    return self
end

function UIBuilder:menu_handling(menu_handling: MenuHandling): UIBuilder
    self.def.menu_handling = menu_handling
    return self
end

function UIBuilder:sprite(sprite_props: SpriteInfo): UIBuilder
    self.def.sprite = {
        s = sprite_props.s,
        ox = sprite_props.ox or 0,
        oy = sprite_props.oy or 0,
    }
    return self
end

function UIBuilder:data(data: any): UIBuilder
    self.def.data = data
    return self
end

function UIBuilder:text(text_props: TextInfo): UIBuilder
    local draw_properties = text_props.draw_properties or {}
    draw_properties.justify = draw_properties.justify or "left"
    draw_properties.direction = draw_properties.direction or "down"
    draw_properties.align = draw_properties.align or false
    draw_properties.wrap = draw_properties.wrap or
        (draw_properties.align and "no_wrap" or "ellipsis")
    
    self.def.text = {
        draw_properties = draw_properties
    }
    self.def.text.text_color = text_props.text_color or "dark"
    return self
end

function UIBuilder:cacheable(cache_info: CacheInfo): UIBuilder
    self.def.cacheable = cache_info
    return self
end

function UIBuilder:child_generator(child_generator: ChildrenInfo): UIBuilder
    self.def.child_generator = child_generator
    return self
end

function UIBuilder:on_draw(
    draw: function(self: UIElement, UIContextManager, DrawTargetManager, UITheme)
): UIBuilder
    self.def.custom_draw = draw
    return self
end

function UIBuilder:on_update(
    on_update: function(UIElement, UIContextManager)
): UIBuilder
    self.def.on_update = on_update
    return self
end

-- utility constructors

function layout.padding(p: integer): Padding
    return {
        l = p,
        r = p,
        t = p,
        b = p,
    }
end

function box.floating(node: UIElement, x: integer, y: integer): UIElement
    return box.builder(node.id.."_float_container")
    :layout{
        dir = "row", -- row helps with bounding box... somehow.  remove when fixed
        padding = { t = y, l = x},
        height = "auto",
        width = "auto",
    }
    :style{
        transparent = true,
        
    }
    :build()
    :add(node)
end

function layout.col_fill(gap?: integer, padding?: Padding): Layout
    return {
        dir = "col",
        width = "auto",
        height = "fill",
        gap = gap,
        padding = padding,
    }
end

function box.col_fill(gap?: integer, padding?: Padding): UIElement
    return box.builder("col_fill")
        :layout(layout.col_fill(gap, padding))
        :build()
end

function layout.col_fit(gap?: integer, padding?: Padding): Layout
    return {
        dir = "col",
        width = "auto",
        height = "auto",
        gap = gap,
        padding = padding,
    }
end

function box.col_fit(gap?: integer, padding?: Padding): UIElement
    return box.builder("col_fit")
        :layout(layout.col_fit(gap, padding))
        :build()
end

function layout.row_fill(gap?: integer, padding?: Padding): Layout
    return {
        dir = "row",
        width = "fill",
        height = "auto",
        gap = gap,
        padding = padding,
    }
end

function box.row_fill(gap?: integer, padding?: Padding): UIElement
    return box.builder("row_fill")
        :layout(layout.row_fill(gap, padding))
        :build()
end

function layout.row_fit(gap?: integer, padding?: Padding): Layout
    return {
        dir = "row",
        width = "auto",
        height = "auto",
        gap = gap,
        padding = padding,
    }
end

function box.row_fit(gap?: integer, padding?: Padding): UIElement
    return box.builder("row_fit")
        :layout(layout.row_fit(gap, padding))
        :build()
end

-- good for lazy justification
function box.spacer(grow?: integer): UIElement
    return box.builder("spacer")
    :layout{flex_grow = grow or 1}
    :style{transparent = true}
    :build()
end

function Box:add(child: UIElement): UIElement
    pt.add(self.children, child as Box) -- Note: casting
    return child -- Return child for chaining
end

---@desc
--- The first pass of the layout system. It calculates the
--- intrinsic size of this element. If the element's size is set to 'auto',
--- it will first measure its children to determine its own content-based size.
function Box:measure(depth: integer)
    self.rect.depth = depth

    local width = self.layout.width
    local height = self.layout.height
    -- is fixed size
    if width is integer and height is integer then
        self.rect.w = width
        self.rect.h = height
        self.rect.c_w = width - self.layout.padding.l - self.layout.padding.r
        self.rect.c_h = height - self.layout.padding.t - self.layout.padding.b
        -- We still measure children so they know their own size
        for _, c in ipairs(self.children) do
            local child = c as Box
            child:measure(depth+1)
        end
        return
    end

    -- Measure Children to determine our own size
    local content_w, content_h = 0, 0
    local is_row = (self.layout.dir == "row")

    for i, c in ipairs(self.children) do
        local child = c as Box
        child:measure(depth+1)

        local child_outer_w = child.rect.w 
        local child_outer_h = child.rect.h 

        if is_row then
            content_w = content_w + child_outer_w
            content_h = pt.max(content_h, child_outer_h)
            if i > 1 then content_w = content_w + self.layout.gap end
        else
            content_w = pt.max(content_w, child_outer_w)
            content_h = content_h + child_outer_h
            if i > 1 then content_h = content_h + self.layout.gap end
        end
    end

    local text_width = 0
    local text_height = 0
    if self.text and self.text.content then
        local text_object = self.text.text_object
        if self.layout.height == "auto" then
            local rows = text_object:get_wrapped_rows()
            text_height = rows * TEXT_ROW_HEIGHT
        end
        if self.layout.width == "auto" then
            local paragraphs = text_object:get_lines()

            local max_width = 0
            for _,p in ipairs(paragraphs) do
                for _,l in ipairs(p) do
                    if #l > max_width then
                        max_width = #l -- todo: expose width in pixels
                    end
                end
            end
            text_width = max_width * TEXT_WIDTH
        end
    end

    content_w = pt.max(content_w, text_width)
    content_h = pt.max(content_h, text_height)
    
    local w = self.layout.width
    if w == "auto" then
        self.rect.w = content_w + self.layout.padding.l + self.layout.padding.r
    elseif w is integer then
        self.rect.w = w
    end
    local h = self.layout.height
    if h == "auto" then
        self.rect.h = content_h + self.layout.padding.t + self.layout.padding.b
    elseif h is integer then
        self.rect.h = h
    end
end

---@desc
--- The second pass of the layout system. It arranges the
--- element's children within its own bounds, distributing available space
--- according to each child's flex properties and alignment settings.
function Box:apply_layout(parent_x: integer, parent_y: integer)
    -- Use calculated sizes if available, otherwise fixed
    local my_w = self.rect.c_w
    local my_h = self.rect.c_h

    -- Apply our own position (usually passed from parent)
    -- If no parent (root), use self.rect.x/y
    self.rect.x = parent_x
    self.rect.y = parent_y

    local is_row = (self.layout.dir == "row")

    -- 1. Calculate Free Space for Flex
    local used_space = 0
    local total_flex = 0

    -- We assume margins were accounted for in the Measure pass size

    for i, c in ipairs(self.children) do
        local child = c as Box
        -- Add Gap
        if i > 1 then used_space = used_space + self.layout.gap end

        -- Add Child Fixed Size (Size + Margin)
        -- Important: If child is flex_grow > 0 but we are auto_size,
        -- flex is effectively disabled for that axis.
        if child.layout.flex_grow > 0
            and not (is_row and self.layout.width == "auto")
            and not (not is_row and self.layout.height == "auto")
        then
            total_flex = total_flex + child.layout.flex_grow
            -- Don't add to used_space yet, flex takes remainder
        else
            local child_w = child.rect.w
            local child_h = child.rect.h

            if is_row then
                used_space = used_space + child_w
            else
                used_space = used_space + child_h
            end
        end
    end

    -- 2. Distribute Children
    local cx = self.rect.x + self.layout.padding.l
    local cy = self.rect.y + self.layout.padding.t
    local total_size = is_row and my_w or my_h
    local remaining = pt.max(0, total_size - used_space)
    local px_per_flex = (total_flex > 0) and (remaining / total_flex) or 0

    for _, c in ipairs(self.children) do
        local child = c as Box
        -- Calculate Final Child Size
        local child_w = child.rect.w
        local child_h = child.rect.h

        -- Handle Flex
        if child.layout.flex_grow > 0 and total_flex > 0 then
            local added = pt.flr(child.layout.flex_grow * px_per_flex)
            if is_row then child_w = added
            else child_h = added end
        end

        if child.layout.height == "fill" then
            child_h = self.rect.c_h
        end
        if child.layout.width == "fill" then
            child_w = self.rect.c_w
        end
        -- Recurse Layout
        if child.layout then
            child.rect.w, child.rect.h = child_w, child_h
            child:apply_layout(cx, cy)
        end

        -- Advance Cursor
        if is_row then
            cx = cx + child_w + self.layout.gap
            cy = cy
        else
            cy = cy + child_h + self.layout.gap
            cx = cx
        end
    end
end

function Box:draw_shaded(color_ne: Color, color_sw: Color, color_interior: Color)
    -- TODO: 45 degree slant (draw lines in loop)
    local x = self.rect.c_x
    local y = self.rect.c_y
    local w = self.rect.c_w
    local h = self.rect.c_h
    local pad = self.style.decoration_padding
    if pad ~= 0 then
        pt.rectfill(
                x,
                y+pad-1,
                x+pad-1,
                y+h-1,
                color_sw
        )
        pt.rectfill(
                x,
                y+h-1,
                x+w-1,
                y+h-1,
                color_sw
        )
        pt.rectfill(
                x,
                y,
                x+w-1,
                y+pad-1,
                color_ne
        )
        pt.rectfill(
                x+w-pad,
                y,
                x+w-1,
                y+h-1-pad,
                color_ne
        )
    end
    pt.rectfill(
            x+pad,
            y+pad,
            x+w-1-pad,
            y+h-1-pad,
            color_interior
    )
end

function Box:draw_shaded_dividers(color_ne: Color, color_sw: Color, color_interior: Color)
    -- TODO: 45 degree slant (draw lines in loop)
    local x = self.rect.c_x
    local y = self.rect.c_y
    local w = self.rect.c_w
    local h = self.rect.c_h
    local pad = self.style.decoration_padding

    if #self.children > 1 and self.layout.gap > 2 * self.style.decoration_padding then
        for i = 2, #self.children do
            --if self.layout.dir == "col" then
            --    local child = self.children[i]
            --    local c_y = child.y + child.layout.padding.t
            --    local gap_h = self.layout.gap
            --    pt.rectfill(
            --            x,
            --            c_y - gap_h + pad,
            --            x + w -1,
            --            c_y - pad,
            --            color_interior
            --    )
            --    pt.rectfill(
            --        x,
            --        c_y - pad + 1,
            --        x + w -1,
            --        c_y,
            --        color_ne
            --    )
            --    pt.rectfill(
            --        x,
            --        c_y - gap_h,
            --        x + w -1,
            --        c_y - gap_h + pad - 1,
            --        color_sw
            --    )
            --
            --    end
            if self.layout.dir == "col" then
                local child = self.children[i]
                local c_y = child.rect.c_y
                local gap_h = self.layout.gap
                pt.rectfill(
                        x,
                        c_y - gap_h + pad,
                        x + w -1,
                        c_y - pad,
                        color_interior
                )
                pt.rectfill(
                    x,
                    c_y - gap_h,
                    x + w -1,
                    c_y - gap_h + pad - 1,
                    color_sw
                )
                pt.rectfill(
                    x,
                    c_y - pad + 1,
                    x + w -1,
                    c_y,
                    color_ne
                )
            elseif self.layout.dir == "row" then
                local prev_child = self.children[i]
                local next_child = self.children[i]
                local c_x = next_child.rect.c_x
                local gap_w = self.layout.gap
                local y_prev = prev_child.rect.c_y
                local h_prev = prev_child.rect.h
                local y_next = next_child.rect.c_y
                local h_next = next_child.rect.h
                pt.rectfill(
                        c_x - gap_w + pad,
                        y,
                        c_x - pad,
                        y + h -1,
                        color_interior
                )
                pt.rectfill(
                    c_x - gap_w,
                    y_prev,
                    c_x - gap_w + pad - 1,
                    h_prev + h_prev -1,
                    color_sw
                )
                pt.rectfill(
                    c_x - pad + 1,
                    y_next,
                    c_x,
                    y_next + h_next -1,
                    color_ne
                )
            end
        end
    end
end

function Box:draw_embossed(ui_theme: UITheme)
    self:draw_shaded(ui_theme.COLOR_DECORATION_HIGHLIGHT, ui_theme.COLOR_DECORATION_SHADOW, ui_theme.COLOR_DECORATION_PRIMARY)
end

function Box:draw_recessed(ui_theme: UITheme)
    self:draw_shaded(ui_theme.COLOR_DECORATION_SHADOW, ui_theme.COLOR_DECORATION_HIGHLIGHT, ui_theme.COLOR_INTERIOR)
    self:draw_shaded_dividers(ui_theme.COLOR_DECORATION_SHADOW, ui_theme.COLOR_DECORATION_HIGHLIGHT, ui_theme.COLOR_DECORATION_PRIMARY)
end

function Box:draw_border(ui_theme: UITheme)
    local d_pad = self.style.decoration_padding
    local x = self.rect.c_x - d_pad
    local y = self.rect.c_y - d_pad
    local w = self.rect.c_w + 2*d_pad
    local h = self.rect.c_h + 2*d_pad
    local r = pt.max(0, d_pad-1)
    pt.rrect(x, y, w, h, r, ui_theme.COLOR_PAGE_DECOR)
end

function Box:draw_solid(ui_theme: UITheme)
    local x = self.rect.x
    local y = self.rect.y
    local w = self.rect.w
    local h = self.rect.h
    pt.rrectfill(x, y, w, h, 0, ui_theme.COLOR_INTERIOR)
end

function Box:draw_background(ui_theme: UITheme)
    local element = self as Box -- Cast!  All classes inherit from box though

    if not element.style.transparent then
        element:draw_solid(ui_theme)
    end
    
    if element.style.decoration == 'embossed' then
        element:draw_embossed(ui_theme)
    elseif element.style.decoration == 'recessed' then
        element:draw_recessed(ui_theme)
    elseif element.style.decoration == 'border' then
        element:draw_border(ui_theme)
    end
end

function Box:draw_text(ui_theme: UITheme)
    local text_colors <total>: {UITextColor: Color} = {
        dark = ui_theme.COLOR_INTERIOR_TEXT,
        trim = ui_theme.COLOR_TRIM,
        strong = ui_theme.COLOR_PAGE_DECOR,
        light = ui_theme.COLOR_DECORATION_SHADOW,
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

-- assumes layout has already been called
function box.find_topmost_selection(elem: UIElement, mx: number, my: number): MenuMouseSelection 
    for _,child in ipairs(elem.children) do
        local c_l = child.rect.c_x
        local c_r = child.rect.c_x+child.rect.c_w
        local c_t = child.rect.c_y
        local c_b = child.rect.c_y+child.rect.c_h
        
        if c_l <= mx and mx < c_r
            and c_t <= my and my < c_b
        then
            log.trace("checking child box for selection", child.id, c_l, c_r, c_t, c_b)
            local child_selection = box.find_topmost_selection(child, mx, my)
            if child_selection ~= nil then
                log.trace("returning hovered selection", child_selection.type)
                return child_selection
            end
        end
    end
    if elem.menu_handling.hover_event then
        return elem.menu_handling.hover_event
    elseif elem.menu_handling.get_selection_at ~= nil then
        log.trace("checking box for selection", elem.id)
        return elem.menu_handling:get_selection_at(mx - elem.rect.c_x, my - elem.rect.c_y)
    end
    return nil
end

function Box:update(state: UIContextManager)
    if self.on_update then
        self:on_update(state)
    end

    for _,c in ipairs(self.children) do
        local child = c as Box
        child:update(state)
    end
end

function Box:compute_children(state: UIContextManager)
    if self.child_generator ~= nil then
        local current_key = self.child_generator.current_key(state)
        if current_key ~= self.child_generator.last_key then
            self.children = self.child_generator.generate_children(state)
            self.child_generator.last_key = current_key
        end
    end

    for _,c in ipairs(self.children) do
        local child = c as Box
        child:compute_children(state)
    end
end

function Box:compute_text()
    -- compute text as a "child", so it may be measured
    -- in the same frame
    local lines = self.text.content

    if self.text.rows then
        assert(
                #lines ==
                self.text.rows, "`func` should return expected number of rows"
        )
    end

    local text_obj = self.text.text_object
    text_obj:set_width(self.rect.c_w)
    text_obj:set_height(self.rect.c_h)
    text_obj:set_lines(lines)
    text_obj:calculate_wrapping()
end


function Box:recalculate(depth: integer, x: integer, y: integer, state: UIContextManager) 
    self:compute_children(state)
    self:update(state)
    self:compute_text()
    self:measure(depth)
    self:apply_layout(x, y)
end

function Box:draw(state: UIContextManager, draw_target_manager: DrawTargetManager, ui_theme: UITheme)
    if self.custom_draw then
        self:custom_draw(state, draw_target_manager, ui_theme)
    else
        Box:draw_background(ui_theme)

        if DYNAMIC_CONFIG.draw_flexbox_debug then
    		local color = colors.rainbow(self.rect.depth-1)	
            pt.rrect(
                    self.rect.x,
                    self.rect.y,
                    self.rect.w,
                    self.rect.h,
                    0, color[2])
             pt.rrect(
                    self.rect.c_x,
                    self.rect.c_y,
                    self.rect.c_w,
                    self.rect.c_h,
                     0, color[1])
        end

        if self.text and self.text.content then
            Box:draw_text(ui_theme)
        end

        if self.sprite and self.sprite.s then
            pt.spr(
                self.sprite.s,
                self.rect.c_x + self.sprite.ox,
                self.rect.c_y + self.sprite.oy
            )
        end
    end

    for _, child in ipairs(self.children) do
        child:draw(state, draw_target_manager, ui_theme)
    end
end

return box
