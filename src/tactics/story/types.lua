---@brief
--- Defines the data structures for stories and their component nodes,
--- such as text, battles, and jumps.

---@alias StoryId string
---@alias NodeId string Identifies a node within a story's node table.

---@alias StoryNodeType "chapter_header"|"text"|"roster_add"|"battle"|"set_memory"|"jump"|"new_page"|"character_customizer"|"text_input"|"save_game"|"game_results"|"exit_story"

---@class StoryNode Abstract base for all story node variants.
---@field type StoryNodeType
local StoryNode = {}

---@class NewPageNode : StoryNode Advances to a new story page.
---@field type "new_page"
local NewPageNode = {}

---@class ChapterHeader : StoryNode Displays a chapter title card.
---@field type "chapter_header"
---@field text string The chapter title text.
---@field chapter_number integer The chapter number displayed on the title card.
local ChapterHeader = {}

---@class StoryTextNode : StoryNode Displays a line of story text.
---@field type "text"
---@field text string The text content to display.
local StoryTextNode = {}

---@class SetMemoryNode : StoryNode Writes a value into story memory.
---@field type "set_memory"
---@field key string Story memory key to set.
---@field value string Value to store at the given key.
local SetMemoryNode = {}

---@class SaveGameNode : StoryNode Triggers a save at this point in the story.
---@field type "save_game"
local SaveGameNode = {}

---@class ExitStoryNode : StoryNode Exits the current story.
---@field type "exit_story"
local ExitStoryNode = {}

---@class RosterAddNode : StoryNode Adds a character to the player's roster.
---@field type "roster_add"
---@field template string Character template ID used to generate the character.
---@field tags string[] Tags applied to the spawned character.
local RosterAddNode = {}

---@class BattleNode : StoryNode Starts a battle and branches on the outcome.
---@field type "battle"
---@field battle_id BattleId ID of the battle definition to load.
---@field next_node_victory NodeId Node to jump to if the player wins.
---@field next_node_failure NodeId Node to jump to if the player loses.
local BattleNode = {}

---@class CharacterCustomizerNode : StoryNode Lets the player customise a character; stores results in story memory.
---@field type "character_customizer"
---@field key string Story memory key where the selected character is stored.
---@field name_key string Story memory key where the chosen character name is stored.
local CharacterCustomizerNode = {}

---@class GameResultsNode : StoryNode Displays the end-of-game results screen.
---@field type "game_results"
local GameResultsNode = {}

---@class TextInputNode : StoryNode Prompts the player to type a string and stores it in story memory.
---@field type "text_input"
---@field text string Prompt text shown above the input field.
---@field key string Story memory key where the entered text is stored.
local TextInputNode = {}

-- TODO: conditional jumps
---@class JumpNode : StoryNode Unconditionally jumps to another node.
---@field type "jump"
---@field next_node NodeId Node to jump to.
local JumpNode = {}

---@alias StoryConfigDefinition table<string, StoryConfigDefinitionEntry>
 
---@class StoryConfigDefinitionEntry
---@field name string 
---@field description string 
---@field options StoryConfigOption[]

---@class StoryConfigOption
---@field name string
---@field value string

---@alias StoryNodeFactory fun(StoryConfig): StoryNode

---@class StoryDefinition
---@field config? StoryConfigDefinition
---@field nodes table<NodeId, (StoryNode|StoryNodeFactory)[]> Maps each node ID to a sequence of nodes played in order.
---@field starting_node NodeId ID of the first node played when the story begins.
local StoryDefinition = {}

local story_node = {
    StoryNode = StoryNode,
    StoryTextNode = StoryTextNode,
    SaveGameNode = SaveGameNode,
    ExitStoryNode = ExitStoryNode,
    ChapterHeader = ChapterHeader,
    BattleNode = BattleNode,
    SetMemoryNode = SetMemoryNode,
    GameResultsNode = GameResultsNode,
    JumpNode = JumpNode,
    NewPageNode = NewPageNode,
    RosterAddNode = RosterAddNode,
    CharacterCustomizerNode = CharacterCustomizerNode,
    TextInputNode = TextInputNode,
}

return {
    StoryDefinition = StoryDefinition,
    story_node = story_node,
}
