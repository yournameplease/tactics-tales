require("src/types")
require("src/util")

global record StoryPage
    text: {string}
end

function StoryPage.new(): StoryPage
    local self: StoryPage = setmetatable({}, { __index = StoryPage })
    self.text = {}
    return self
end

-- data access

function StoryPage:add_text_line(text: string)
    pt.add(self.text, text)
end

function StoryPage:clear_page()
    self.text = {}
end



return StoryPage
