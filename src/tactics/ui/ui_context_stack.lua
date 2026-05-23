---@brief
--- Engine-side UI context stack. Manages a set of registered UIContexts
--- keyed by their .type field, calls :enrich() on each per frame, and
--- selects an active layout from a game-provided priority list.
---
--- This module is intentionally game-agnostic: it does not require any
--- specific UIContext implementation. Games instantiate it with their own
--- priority list and register concrete contexts at runtime.

require("src.tactics.ui.ui_context")
require("src.tactics.ui.types")

---@class UIContextStack
---@field contexts table<string, UIContext>
---@field layout_priority string[] Context types in primary-selection order.
---@field default_layout UILayoutId Layout used when no registered context can provide one.
---@field layout UILayoutId
local UIContextStack = {}
UIContextStack.__index = UIContextStack

local ui_context_stack = {
    UIContextStack = UIContextStack,
}

---@class UIContextStackOpts
---@field layout_priority? string[] Context types in primary-selection order.
---@field default_layout? UILayoutId Fallback when no registered context provides a layout.

--- Create a new UIContextStack.
---@param opts? UIContextStackOpts
---@return UIContextStack
function ui_context_stack.new(opts)
    opts = opts or {}
    ---@type UIContextStack
    local self = setmetatable({}, UIContextStack)
    self.contexts = {}
    self.layout_priority = opts.layout_priority or {}
    self.default_layout = opts.default_layout or "NONE"
    self.layout = self.default_layout
    return self
end

--- Register a UI context. The context's .type field is used as its key.
--- The context is also mirrored as `self[type .. "_context"]` for typed
--- access from game-side glue. Errors if a context of that type is
--- already registered.
---@param ctx UIContext
function UIContextStack:register_ui_context(ctx)
    local key = ctx.type
    assert(self.contexts[key] == nil,
        "Attempt to register " .. key .. " context which was already registered!")
    self.contexts[key] = ctx
    self[key .. "_context"] = ctx
end

--- Unregister the UI context of the given type. Errors if not registered.
---@param ctx_type string
function UIContextStack:unregister_ui_context(ctx_type)
    assert(self.contexts[ctx_type] ~= nil,
        "Attempt to unregister " .. ctx_type .. " context which was not registered!")
    self.contexts[ctx_type] = nil
    self[ctx_type .. "_context"] = nil
end

--- Get the registered context of the given type, if any.
---@param ctx_type string
---@return UIContext?
function UIContextStack:get(ctx_type)
    return self.contexts[ctx_type]
end

--- Call :enrich() on every registered context, then set self.layout from
--- the first context in layout_priority that is currently registered.
--- Falls back to self.default_layout if none are present.
function UIContextStack:enrich()
    for _, ctx in pairs(self.contexts) do
        ---@cast ctx UIContext
        ctx:enrich()
    end

    self.layout = self.default_layout
    for _, t in ipairs(self.layout_priority) do
        local ctx = self.contexts[t]
        if ctx ~= nil then
            self.layout = ctx.layout
            return
        end
    end
end

return ui_context_stack
