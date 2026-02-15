---@brief
--- Contains basic UI-related type definitions, such as UILayoutId.

local box = require("src.tactics.ui.box")

local record ModalLayout
    node: box.UIElement
end

local record UILayout
    root: box.UIElement
    modals: {ModalLayout}
end

local ui_types = {
    UILayout = UILayout,
    ModalLayout = ModalLayout,
}

return ui_types
