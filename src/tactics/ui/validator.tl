---@brief
--- A utility to validate the structural integrity of UI layouts at startup,
--- checking for invalid property combinations.

local box = require("src.tactics.ui.box")

local menu_validator = {}

local function get_node_name(_node: box.UIElement, index: integer): string
    return ("child[" .. index .. "]")
end

--- Recursively validates a UI tree.
function menu_validator.validate(node: box.UIElement, path: string)
    if not node then return end

    local is_col = (node.layout.dir == "col")
    local is_row = (node.layout.dir == "row")

    local children = node.children
    assert(children ~= nil)

    if node.layout.height == "auto" then
        if is_col then
            for i, child in ipairs(children) do
                if (child.layout.flex_grow or 0) > 0 then
                    error(
                            "LAYOUT ERROR: Circular Dependency.\nPath: "
                                    ..path.." > "..get_node_name(child, i)..
                                    "Parent is 'auto_height' (col), but child has to 'flex_grow'."
                    )
                end
            end
        end
    end

    if node.layout.width == "auto" then
        if is_row then
            for i, child in ipairs(children) do
                if (child.layout.flex_grow or 0) > 0 then
                    error(string.format(
                            "LAYOUT ERROR: Circular Dependency.\nPath: %s > %s\nReason: Parent is 'auto_width' (row), but child tries to 'flex_grow'.",
                            path, get_node_name(child, i)
                    ))
                end
            end
        end
    end

    for i, child in ipairs(children) do
        local child_path = path .. " > " .. get_node_name(child, i)
        menu_validator.validate(child, child_path)
    end
end

return menu_validator
