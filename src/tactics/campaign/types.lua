---@brief
--- Defines the data structures for stories and their component nodes,
--- such as text, battles, and jumps.

---@alias CampaignId string
---@alias NodeId string Identifies a node within a campaign's node table.

---@alias CampaignNodeType "chapter_header"|"text"|"roster_add"|"battle"|"set_memory"|"set_memory_list"|"jump"|"detour"|"new_page"|"advance"|"character_customizer"|"text_input"|"save_game"|"game_results"|"exit_campaign"|"delete_file"|"select_option"

---@class CampaignNode Abstract base for all campaign node variants.
---@field type CampaignNodeType

---@class NewPageNode : CampaignNode Advances to a new campaign page.
---@field type "new_page"

---@class AdvanceNode : CampaignNode Immediately advances to the next node.
---@field type "advance"

---@class ChapterHeader : CampaignNode Displays a chapter title card.
---@field type "chapter_header"
---@field text string The chapter title text.
---@field chapter_number integer The chapter number displayed on the title card.

---@class CampaignTextNode : CampaignNode Displays a line of campaign text.
---@field type "text"
---@field text string The text content to display.

---@class SetMemoryNode : CampaignNode Writes a value into campaign memory.
---@field type "set_memory"
---@field key string Campaign memory key to set.
---@field value string Value to store at the given key.

---@class SetMemoryListNode : CampaignNode Writes a list of values into campaign memory.
---@field type "set_memory_list"
---@field key string Campaign memory key to set.
---@field values string[] List of values to store at the given key.

---@class SaveGameNode : CampaignNode Triggers a save at this point in the campaign.
---@field type "save_game"

---@class DeleteFileNode : CampaignNode Deletes the current save file and advances.
---@field type "delete_file"

---@class ExitCampaignNode : CampaignNode Exits the current campaign.
---@field type "exit_campaign"

---@class RosterAddNode : CampaignNode Adds a character to the player's roster.
---@field type "roster_add"
---@field template string Character template ID used to generate the character.
---@field tags string[] Tags applied to the spawned character.

---@class BattleNode : CampaignNode Starts a battle and branches on the outcome.
---@field type "battle"
---@field battle_id BattleId ID of the battle definition to load.
---@field next_node_victory NodeId Node to jump to if the player wins.
---@field next_node_failure NodeId Node to jump to if the player loses.

---@class CharacterCustomizerNode : CampaignNode Lets the player customise a character; stores results in campaign memory.
---@field type "character_customizer"
---@field key string Campaign memory key where the selected character is stored.
---@field name_key? string Campaign memory key where the chosen character name is stored.

---@class GameResultsNode : CampaignNode Displays the end-of-game results screen.
---@field type "game_results"

---@class TextInputNode : CampaignNode Prompts the player to type a string and stores it in campaign memory.
---@field type "text_input"
---@field text string Prompt text shown above the input field.
---@field key string Campaign memory key where the entered text is stored.

---@class SelectOptionEntry A single selectable option presented to the player.
---@field id string Option identifier written to campaign memory when chosen.
---@field name string Display name shown in the option list.
---@field description string Description shown alongside the option name.

---@class SelectOptionNode : CampaignNode Presents a list of named options and stores the chosen ID in campaign memory.
---@field type "select_option"
---@field options SelectOptionEntry[] Ordered list of options to display.
---@field memory_key string Campaign memory key where the chosen option ID is stored.

---@class CampaignNodeHandler
---@field enter fun(campaign: Campaign, node: CampaignNode)
---@field exit? fun(campaign: Campaign, node: CampaignNode)
---@field update? fun(campaign: Campaign, input: InputContext)

-- TODO: conditional jumps
---@class JumpNode : CampaignNode Unconditionally jumps to another node.
---@field type "jump"
---@field next_node NodeId Node to jump to.

---@class DetourNode : CampaignNode Jumps to a named node, executes it fully, then returns to the step after the detour.
---@field type "detour"
---@field target NodeId Node to execute before returning.

---@class CampaignConfigDefinition
---@field options CampaignConfigDefinitionEntry[]
---@field presets? CampaignConfigPreset[]
---@field default_preset? string

---@class CampaignConfigPreset
---@field key string
---@field name string
---@field values table<string, string>

---@class CampaignConfigDefinitionEntry
---@field key string
---@field name string
---@field description? string
---@field options CampaignConfigOption[]

---@class CampaignConfigOption
---@field name string
---@field value string

---@class CampaignRngContext Runtime RNG instances threaded alongside CampaignConfig into factories.
---@field campaign_rng RngInstance Campaign-level RNG, persisted across saves.
---@field battle_rng RngInstance? Battle-level RNG, set fresh before each battle.

---@alias CampaignNodeFactory fun(config: CampaignConfig, rng: CampaignRngContext, state: table<string, string>): CampaignNode
---@alias CampaignNodeSource (CampaignNode | CampaignNodeFactory)[]

---@class CampaignDefinition
---@field config? CampaignConfigDefinition
---@field name? string
---@field description? string
---@field battle_config BattleConfig|fun(CampaignConfig, CampaignRngContext): BattleConfig
---@field nodes table<NodeId, CampaignNodeSource> Maps each node ID to a sequence of nodes played in order.
---@field starting_node NodeId ID of the first node played when the campaign begins.
