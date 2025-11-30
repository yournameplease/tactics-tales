require("src/debug")
require("src/util")
require("src/character/animation_data")
require("src/character/weapons")
require("src/animation")

-- TODO: break "drawing" functionality into a CharacterRenderer

global record CharacterManager
    id_counter: IdCounter
    characters: { Character }
end

function CharacterManager.new(): CharacterManager
    local self: CharacterManager = setmetatable({}, { __index = CharacterManager})
    self.id_counter = IdCounter.new()
    self.characters = {}
    return self
end

global enum Sex
    "male"
    "female"
end 

global record CharacterAppearance
    sex: Sex
    hair: integer
    skin: integer
    hair_color: Color
    body: integer
    beard: integer
    beard_color: Color
end

global record CharacterStats
    hp_max: integer
    movement: integer
    def: integer
end

global record Character
    id: integer
    name: string
    appearance: CharacterAppearance
    stats: CharacterStats
    weapon: Weapon
    animation_data: AnimatedSpriteData
    animation_blocking: boolean
end

local HAIR_COLORS: { Color } = {
    4, 5, 6, 9, 10, 20, 21, 22, 24, 25, 31
}
-- todo: deduplicate this from renderer
local SKIN_COLORS: { { Color, Color } } = {
    {15, 31},
    {31, 4},
    {4, 20},
    {20, 21}
}


local function generate_appearance(): CharacterAppearance
    local appearance: CharacterAppearance = {}

    appearance.sex = choose_random_from_list({"male", "female"})
    appearance.hair = rndi(6)
    appearance.skin = rndi(#SKIN_COLORS)+1
    while appearance.hair_color == nil
            or appearance.hair_color == SKIN_COLORS[appearance.skin][1]
    do
        appearance.hair_color = choose_random_from_list(HAIR_COLORS)
    end

    if appearance.sex == "male" then 
        appearance.body = rndi(4)
        appearance.beard = rndi(7)
        if rnd(6) <= 1 then
            appearance.beard_color = choose_random_from_list(HAIR_COLORS)
        else
            appearance.beard_color = appearance.hair_color
        end
    else -- female
        appearance.body = rndi(4)
    end

    return appearance
end

function CharacterManager:generate_character(): Character
    local character: Character = {
        id = self.id_counter:get_id(),
        appearance = generate_appearance(),
        stats = {
            hp_max = 5,
            movement = 5,
            def = 0
        },
        weapon = choose_random_from_table(WEAPON_DATA)
    }
    character.name = character.appearance.sex == "male" and "Bob" or "Alice",

    setmetatable(character, { __index = Character })

    self.characters[character.id] = character

    return character
end


return CharacterManager
