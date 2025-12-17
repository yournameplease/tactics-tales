require("src/tactics/ui/box")

global record MenuValidator

end 

local function get_node_name(_node: UIElement, index: integer): string
    return ("child[" .. index .. "]")
end

--- Recursively validates a UI tree.
function MenuValidator.validate(node: UIElement, path: string)
    if not node then return end

    local is_col = (node.dir == "col")
    local is_row = (node.dir == "row")

    local children = node.children
    assert(children ~= nil)

    if node.auto_height then
        if is_col then
            assert(#children > 0, "LAYOUT ERROR: "..path.."\nMust have children to use auto_height.")
            for i, child in ipairs(children) do
                if (child.flex_grow or 0) > 0 then
                    error(
                            "LAYOUT ERROR: Circular Dependency.\nPath: "
                                    ..path.." > "..get_node_name(child, i)..
                                    "Parent is 'auto_height' (col), but child has to 'flex_grow'."
                    )
                end
            end
        end

        if is_row then
            for _, child in ipairs(children) do
                if child.cross_stretch and not child.h and not child.auto_height then
                    error( "Warning: "..path.."\nThis child effectively vanishes or relies on a sibling.")
                end
            end
        end
    end

    if node.auto_width then
        if is_row then
            assert(#children > 0, "LAYOUT ERROR: "..path.."\nMust have children to use auto_width.")
            for i, child in ipairs(children) do
                if (child.flex_grow or 0) > 0 then
                    error(string.format(
                            "LAYOUT ERROR: Circular Dependency.\nPath: %s > %s\nReason: Parent is 'auto_width' (row), but child tries to 'flex_grow'.",
                            path, get_node_name(child, i)
                    ))
                end
            end
        end

        if is_row then
            for _, child in ipairs(children) do
                if child.cross_stretch and not child.w and not child.auto_width then
                    error( "Warning: "..path.."\nThis child effectively vanishes or relies on a sibling.")
                end
            end
        end
    end

    for i, child in ipairs(children) do
        local child_path = path .. " > " .. get_node_name(child, i)
        MenuValidator.validate(child, child_path)
    end
end

return MenuValidator
