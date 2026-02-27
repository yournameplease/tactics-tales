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

    local _is_col = (node.layout.dir == "col")
    local _is_row = (node.layout.dir == "row")

    local children = node.children
    assert(children ~= nil)

    if node.layout.height == "fit_content" then
        local fill_child: box.UIElement = nil
        local non_fill_child = false
        for _, child in ipairs(children) do
            if child.layout.height == "fill" then
                fill_child = child
            else
                non_fill_child = true
            end
        end
        if fill_child and not non_fill_child then
            error(
                    "LAYOUT ERROR: Circular Dependency.\nPath: "
                            ..path.." > "..fill_child.id..
                            "Parent is 'fit_content' height, but child has to 'fill' height."
            )
        end
    end

    if node.layout.width == "fit_content" then
        local fill_child: box.UIElement = nil
        local non_fill_child = false
        for _, child in ipairs(children) do
            if child.layout.width == "fill" then
                fill_child = child
            else
                non_fill_child = true
            end
        end
        if fill_child and not non_fill_child then
            error(string.format(
                    "LAYOUT ERROR: Circular Dependency.\nPath: %s > %s\nReason: Parent is 'auto_width', but child tries to 'flex_grow'.",
                    path, fill_child.id
            ))
        end
    end

    for i, child in ipairs(children) do
        local child_path = path .. " > " .. get_node_name(child, i)
        menu_validator.validate(child, child_path)
    end
end

return menu_validator
