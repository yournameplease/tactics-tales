---@brief
--- Contains basic UI-related type definitions, such as UILayoutId.

local enum UILayoutId
    "TITLE_SCREEN"
    "MAIN_MENU_PAGE"
    "CHAPTER_SELECT_PAGE"
    "OPTIONS_MENU_PAGE"

    "TACTICS"
    "COMBAT_PREVIEW"

    "STORY_PAGE"
end

local ui_types = {
    UILayoutId = UILayoutId
}

return ui_types
