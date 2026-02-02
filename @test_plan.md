# Picotron Tactics Test Plan

This document outlines a testing strategy for the Picotron Tactics project. It covers major modules, suggesting testing approaches, and prioritizing efforts to ensure code quality and stability.

The project's tests should follow the conventions in `GEMINI.md`, using Teal for tests and leveraging the `picotron_shim.tl` where necessary.

## Prioritization Recommendations

Testing efforts should be prioritized as follows to maximize impact:

1.  **High Priority (Foundational Logic):**
    *   **All `util` modules:** These are the building blocks of the project. Their correctness is paramount.
    *   **Core battle logic:** `pathfinding`, `combat_calculator`, `battle_objective_service`. These define the core gameplay mechanics.
    *   **`character/items/object/item_inventory`:** A critical, isolated data structure managing character state.

2.  **Medium Priority (Core Systems & Integrations):**
    *   **Integration tests for `tactics_engine` and `ai_engine`:** Ensures the main battle loop and AI decisions work as expected.
    *   **`mods/mod_loader`:** Guarantees that custom game data loads correctly and safely.
    *   **`ui/box` layout logic:** Prevents widespread UI layout bugs.
    *   **`systems/event_bus` & `systems/tasks`:** Core infrastructure that should be reliable.
    *   **`animation` logic:** The state management portion of the animation system.

3.  **Low Priority (Complex & UI-Heavy Modules):**
    *   **`story` module:** Story flow is important but complex to test; can be addressed after core mechanics are stable.
    *   **Graphical rendering code (`character_renderer`, most UI components):** These are best tested visually and manually. Automated tests here provide low return on investment.

---

## Module-by-Module Test Strategy

### `src/tactics/util/`

*   **Files**: `lists.tl`, `maps.tl`, `point.tl`, `array_2d.tl`, `fp.tl`, `id_generator.tl`, `randomizer.tl`, `text.tl`, etc.
*   **Overview**: A collection of pure, stateless utility functions and data structures.
*   **Isolation**: Excellent. These modules have no dependencies on the game engine's state or Picotron libraries.
*   **Testing Approach**: **Unit Testing**. Each function should be tested thoroughly with various inputs, including edge cases (e.g., empty lists/tables, zero values).
*   **Benefit/Difficulty**: **High Benefit / Low Difficulty**. These are foundational to the entire project. They are simple to test and provide a strong base of stability.
*   **Priority**: **High**.

### `src/tactics/character/` and `src/tactics/character/items/`

*   **Files**: `character_generator.tl`, `character_manager.tl`, `items/item_generator.tl`, `items/object/item_inventory.tl`.
*   **Overview**: Manages character data, generation from templates, and inventory management.
*   **Isolation**:
    *   `item_inventory.tl` is a highly isolated data structure.
    *   `character_generator.tl` depends on game data definitions but its logic is testable.
*   **Testing Approach**:
    *   **`item_inventory.tl` (Unit Test):** Create an inventory and test all its methods: adding items that exceed capacity, equipping items with slot conflicts (e.g., equipping a two-handed weapon when single-handed ones are equipped), and removing items.
    *   **`character_generator.tl` (Unit Test):** Use mock game data (`characters`, `items`) to test character creation. The random nature can be handled by checking that generated attributes fall within the options defined in the template.
*   **Benefit/Difficulty**: High benefit for `item_inventory.tl` (low difficulty). Medium benefit for `character_generator.tl` (medium difficulty).
*   **Priority**: **High** for `item_inventory.tl`, **Medium** for `character_generator.tl`.

### `src/tactics/battle/`

*   **Files**: `pathfinding.tl`, `combat/combat_calculator.tl`, `battle_objective_service.tl`, `battle_map.tl`.
*   **Overview**: Contains the core, pure logic for battle mechanics.
*   **Isolation**: Generally well-isolated. These modules operate on data and can be tested without a full game loop.
*   **Testing Approach**: **Unit Testing**.
    *   **`pathfinding.tl`**: Create mock map data with varying terrain costs and test that `find_reachable_tiles` and `get_path_to_tile` return the correct results.
    *   **`combat_calculator.tl`**: Create mock `BattleUnit` objects with different stats, equipment, and terrain positions. Call `compute_combat` and assert that hit chance, damage, and combat outcomes are calculated correctly.
    *   **`battle_objective_service.tl`**: Set up a `BattleMap` in various states (e.g., no enemies left, a key unit defeated) and call `check_objectives` to verify that victory/failure conditions are triggered correctly.
*   **Benefit/Difficulty**: **High Benefit / Low-to-Medium Difficulty**. This is the heart of the gameplay.
*   **Priority**: **High**.

### `src/tactics/battle/tactics` and `src/tactics/battle/` (Engines)

*   **Files**: `tactics_engine.tl`, `ai_engine.tl`, `battle_manager.tl`.
*   **Overview**: These are the high-level orchestrators for battles, managing state, executing actions, and controlling AI.
*   **Isolation**: Poor. These modules are deeply integrated with each other and many other systems (`event_bus`, `animation_manager`, `task_manager`).
*   **Testing Approach**: **Integration Testing**. Create a test-specific mod that defines simple battle scenarios.
    *   **Scenario 1 (Movement):** A battle with one player unit. Send a "move" command via the `TacticsEngine` and assert that the unit's final position on the `BattleMap` is correct.
    *   **Scenario 2 (Combat):** A player unit next to an enemy unit. Trigger an attack and assert that HP values are updated correctly and that events like `TACTICS_UNIT_DEATH` are fired if applicable.
    *   **Scenario 3 (AI):** A battle with one AI unit and one player unit in range. Trigger the AI's turn and verify that it performs a sensible action (e.g., moves and attacks).
*   **Benefit/Difficulty**: **High Benefit / High Difficulty**. Testing these ensures the game works end-to-end.
*   **Priority**: **Medium**. Start with simple integration tests and expand coverage over time.

### `src/tactics/mods/`

*   **Files**: `mod_loader.tl`, `validator.tl`, `mod_schema.tl`.
*   **Overview**: Responsible for loading and validating all game data.
*   **Isolation**: Depends on Picotron's file system functions (`pt.include`, `pt.ls`).
*   **Testing Approach**: **Integration Testing**. Create a dedicated test mod directory (`src/spec/test_mods/`) containing:
    *   A valid mod with correct data structures.
    *   An invalid mod with schema errors (e.g., missing required fields, incorrect data types, broken references).
    *   Test that `mod_loader.load_mod_data` succeeds for the valid mod and that `mod_loader.validate_mods` passes.
    *   Test that `mod_loader.validate_mods` fails for the invalid mod and returns descriptive errors.
*   **Benefit/Difficulty**: **High Benefit / Medium Difficulty**. Ensures game data integrity and stability.
*   **Priority**: **Medium**.

### `src/tactics/ui/`

*   **Files**: `ui_manager.tl`, `box.tl`, and many component/panel/layout files.
*   **Overview**: A comprehensive declarative UI system. `box.tl` contains the core flexbox-like layout logic.
*   **Isolation**: The layout logic is pure, but the rendering is graphical and tied to Picotron.
*   **Testing Approach**:
    *   **`box.tl` (Unit Test):** This is the most critical piece of the UI to test. Create nested `box` instances with different properties (`flex_grow`, `auto_width`, `dir`, `padding`, etc.). Run the `measure` and `layout` passes, then assert that the calculated `x`, `y`, `w`, and `h` of each box are correct. This will prevent hard-to-debug layout regressions.
    *   **Other UI Files (Manual):** Most other components are primarily for rendering. These are best tested by running the game and visually inspecting the results.
*   **Benefit/Difficulty**: **High Benefit / Medium Difficulty** for `box.tl`. Low benefit/high difficulty for other components.
*   **Priority**: **Medium** for `box.tl` layout tests. **Low** for others.

### Other Modules

*   **`animation.tl`**: The state management logic (`tick`, `create_*_animation`) can be unit tested by checking the state of animation objects over time, without rendering them. **(Medium Priority)**
*   **`systems/event_bus.tl`**: Can be unit tested by subscribing to an event, emitting it, and asserting the callback was fired. **(Medium Priority)**
*   **`story/*`**: The story module is a high-level state machine. It is best tested via **integration tests** using a simple test story mod, asserting that memory is set correctly and that nodes (battles, text) are advanced as expected. **(Low Priority)**
*   **`*_renderer.tl`**: Any file ending in `_renderer` is primarily graphical. These should be excluded from automated testing in favor of manual visual checks. **(Low Priority)**
