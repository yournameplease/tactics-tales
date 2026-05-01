---@brief
--- Defines the data structures for stories and their component nodes,
--- such as text, battles, and jumps.

---@alias CampaignId string
---@alias NodeId string Identifies a node within a story's node table.

---@alias CampaignNodeType "chapter_header"|"text"|"roster_add"|"battle"|"set_memory"|"set_memory_list"|"jump"|"new_page"|"advance"|"character_customizer"|"text_input"|"save_game"|"game_results"|"exit_campaign"|"delete_file"|"select_option"

---@class StoryNode Abstract base for all story node variants.
---@field type CampaignNodeType

---@class NewPageNode : StoryNode Advances to a new story page.
---@field type "new_page"

---@class AdvanceNode : StoryNode Immediately advances to the next node.
---@field type "advance"

---@class ChapterHeader : StoryNode Displays a chapter title card.
---@field type "chapter_header"
---@field text string The chapter title text.
---@field chapter_number integer The chapter number displayed on the title card.

---@class StoryTextNode : StoryNode Displays a line of story text.
---@field type "text"
---@field text string The text content to display.

---@class SetMemoryNode : StoryNode Writes a value into story memory.
---@field type "set_memory"
---@field key string Story memory key to set.
---@field value string Value to store at the given key.

---@class SetMemoryListNode : StoryNode Writes a list of values into story memory.
---@field type "set_memory_list"
---@field key string Story memory key to set.
---@field values string[] List of values to store at the given key.

---@class SaveGameNode : StoryNode Triggers a save at this point in the story.
---@field type "save_game"

---@class DeleteFileNode : StoryNode Deletes the current save file and advances.
---@field type "delete_file"

---@class ExitStoryNode : StoryNode Exits the current story.
---@field type "exit_campaign"

---@class RosterAddNode : StoryNode Adds a character to the player's roster.
---@field type "roster_add"
---@field template string Character template ID used to generate the character.
---@field tags string[] Tags applied to the spawned character.

---@class BattleNode : StoryNode Starts a battle and branches on the outcome.
---@field type "battle"
---@field battle_id BattleId ID of the battle definition to load.
---@field next_node_victory NodeId Node to jump to if the player wins.
---@field next_node_failure NodeId Node to jump to if the player loses.

---@class CharacterCustomizerNode : StoryNode Lets the player customise a character; stores results in story memory.
---@field type "character_customizer"
---@field key string Story memory key where the selected character is stored.
---@field name_key? string Story memory key where the chosen character name is stored.

---@class GameResultsNode : StoryNode Displays the end-of-game results screen.
---@field type "game_results"

---@class TextInputNode : StoryNode Prompts the player to type a string and stores it in story memory.
---@field type "text_input"
---@field text string Prompt text shown above the input field.
---@field key string Story memory key where the entered text is stored.

---@class SelectOptionEntry A single selectable option presented to the player.
---@field id string Option identifier written to story memory when chosen.
---@field name string Display name shown in the option list.
---@field description string Description shown alongside the option name.

---@class SelectOptionNode : StoryNode Presents a list of named options and stores the chosen ID in story memory.
---@field type "select_option"
---@field options SelectOptionEntry[] Ordered list of options to display.
---@field memory_key string Story memory key where the chosen option ID is stored.

---@class StoryNodeHandler
---@field enter fun(story: Story, node: StoryNode)
---@field exit? fun(story: Story, node: StoryNode)
---@field update? fun(story: Story, input: InputContext)

-- TODO: conditional jumps
---@class JumpNode : StoryNode Unconditionally jumps to another node.
---@field type "jump"
---@field next_node NodeId Node to jump to.

---@class StoryConfigDefinition
---@field options StoryConfigDefinitionEntry[]
---@field presets? StoryConfigPreset[]
---@field default_preset? string

---@class StoryConfigPreset
---@field key string
---@field name string
---@field values table<string, string>

---@class StoryConfigDefinitionEntry
---@field key string
---@field name string
---@field description? string
---@field options StoryConfigOption[]

---@class StoryConfigOption
---@field name string
---@field value string

---@class StoryRngContext Runtime RNG instances threaded alongside StoryConfig into factories.
---@field story_rng RngInstance Story-level RNG, persisted across saves.
---@field battle_rng RngInstance? Battle-level RNG, set fresh before each battle.

---@alias StoryNodeFactory fun(config: StoryConfig, rng: StoryRngContext, state: table<string, string>): StoryNode
---@alias StoryNodeSource StoryNode | StoryNode[] | (fun(config: StoryConfig, rng: StoryRngContext, state: table<string, string>): StoryNodeSource)

---@class CampaignDefinition
---@field config? StoryConfigDefinition
---@field name? string
---@field description? string
---@field battle_config BattleConfig|fun(StoryConfig, StoryRngContext): BattleConfig
---@field nodes table<NodeId, StoryNodeSource> Maps each node ID to a sequence of nodes played in order.
---@field starting_node NodeId ID of the first node played when the story begins.
