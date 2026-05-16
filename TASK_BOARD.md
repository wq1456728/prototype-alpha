# Task Board

This file is the handoff point for other conversations or agents. Read this first before doing project work.

## Source Of Truth

Current planning and implementation rules:

- [README.md](README.md)
- [docs/DEMO_SCOPE.md](docs/DEMO_SCOPE.md)
- [docs/CONTROL_AND_COMBAT.md](docs/CONTROL_AND_COMBAT.md)
- [docs/ART_PIPELINE.md](docs/ART_PIPELINE.md)
- [docs/PROJECT_PLAN.md](docs/PROJECT_PLAN.md)
- [docs/TASK_002_ASSET_INTEGRATION.md](docs/TASK_002_ASSET_INTEGRATION.md)
- [docs/TASK_003_COMBAT_SANDBOX_PLAN.md](docs/TASK_003_COMBAT_SANDBOX_PLAN.md)
- [ASSET_PROMPT_TEMPLATE.md](ASSET_PROMPT_TEMPLATE.md)

If older notes conflict with these files, the files above win.

## Current Phase

Vertical systems pass after the first combat sandbox loop.

## Current Goal

The first combat-growth loop is functionally present. The next goal is to build the smallest Diablo-like vertical progression chain before adding more classes, enemies, or skills:

```text
kill enemy
-> item drops
-> item goes into bag
-> player equips item
-> stats change
-> player kills faster
-> player gains XP
-> player levels up
-> player unlocks one new ability
-> sandbox objective completes
```

## Active Task

### TASK-012: Item Data And Drop Roll v1

Status: done

Task agent status: done

Audit Status:

- 2026-05-16 replaced the fixed weapon drop with generated item data.
- Weapon drops now roll name, rarity, damage bonus, icon, and rarity color.
- The small rarity set is `normal`, `magic`, and `rare`, with tunable drop chances and damage ranges.
- Drop roll validation sampled 13 names, 3 rarities, and 12 damage values with a fixed seed.
- Runtime wrapper validation passed for `tools/smoke_combat_sandbox_structure.gd`, `tools/debug_player_inputs.gd`, and `tools/debug_combat_sandbox.gd`.

Goal:

Replace fixed damage pickup behavior with simple generated weapon item data.

Focus on:

- Generate a weapon item when an enemy drops loot.
- Keep item data small: name, rarity, damage bonus, icon/color.
- Use a tiny rarity set: normal, magic, rare.
- Use simple damage ranges per rarity.
- Keep drop rates easy to tune.
- Do not build a full affix system yet.

Expected output:

- Item data shape.
- Drop roll behavior.
- Updated sandbox debug or UI display if needed.
- Runtime validation result.

Acceptance:

- Enemy drops produce item data, not only a fixed pickup.
- Different drops can have different names, rarity colors, and damage values.
- Implementation remains small and local to the current sandbox loop.
- Completed task entry includes `Task agent status: done`.

## Backlog

### TASK-013: Inventory UI Pass 1

Status: done

Task agent status: done

Audit Status:

- 2026-05-16 inventory now starts hidden and toggles with `B`.
- Bag UI shows 10 slots, current equipped weapon, current attack damage, and selected item details.
- Selecting a bag slot shows item name, rarity, and damage bonus.
- Selected weapon can be equipped from the UI through the Equip button; number-key equip still works.
- Runtime wrapper validation passed for `tools/smoke_combat_sandbox_structure.gd`, `tools/debug_player_inputs.gd`, and `tools/debug_combat_sandbox.gd`.
- 2026-05-16 follow-up requirement added: current implementation is not enough for Diablo II-like mouse item handling; TASK-013 should be extended before treating the inventory UI as final for the demo loop.
- 2026-05-16 follow-up completed: ground items now require left-click pickup, open inventory picks items onto the cursor, bag/equipment clicks support cursor-held swapping, cursor-held items block attacks, and cursor-held items can be dropped back into the world.
- Runtime wrapper validation passed again for `tools/smoke_combat_sandbox_structure.gd`, `tools/debug_player_inputs.gd`, and `tools/debug_combat_sandbox.gd`.

Goal:

Make the minimum bag/equipment flow visible and usable.

Focus on:

- Press `B` to toggle inventory visibility.
- Inventory starts hidden by default.
- Show 8-12 bag slots.
- Show one equipped weapon slot.
- Show selected item name, rarity, and damage bonus.
- Allow equipping a weapon from the bag through a simple click or key action.
- Show current attack damage.
- Keep UI functional, not final.
- Do not add drag-and-drop unless it is cheaper than the simpler interaction.

Follow-up Requirement: Diablo II-like Mouse Item Handling:

- Ground items are picked up with left mouse click, not by walking over them.
- If inventory is closed, left-clicking a ground item may pick it directly into the first valid bag slot if space exists.
- If inventory is open, left-clicking a ground item picks it onto the cursor instead of directly placing it into the bag.
- Left-clicking a bag item while inventory is open picks that item onto the cursor.
- Left-clicking the equipped weapon while inventory is open picks that item onto the cursor and clears the equipped slot.
- While an item is held on the cursor, player attack inputs are blocked.
- A held cursor item can be placed into an empty bag slot.
- A held weapon item can be placed into the weapon equipment slot.
- Placing a held item onto an occupied bag slot swaps the cursor item with the existing slot item.
- Placing a held weapon onto an occupied weapon equipment slot swaps the cursor item with the equipped weapon.
- Left-clicking empty world space while holding an item drops it back into the world at the clicked position.
- Dropped world items keep their full item data: name, rarity, damage bonus, icon, and color.
- Invalid placement keeps the item on the cursor and should provide simple feedback rather than deleting the item.
- Closing the inventory while holding an item should keep the item on the cursor or drop it intentionally; do not silently delete it.
- Death, scene reload, or full-bag edge cases must not lose held items silently.
- The cursor-held item should be visibly attached to the mouse, using the item icon.
- The UI should distinguish hover, selected, equipped, and cursor-held states clearly enough for playtesting.

Acceptance:

- Pressing `B` shows and hides the inventory.
- Player can see what is in the bag.
- Player can see equipped weapon.
- Player can equip a weapon and see damage update.
- Player must click ground items to pick them up.
- Player can hold an item on the cursor and cannot attack while holding it.
- Player can place, equip, swap, and drop cursor-held items without item loss.
- UI is small enough for the combat sandbox.
- Completed task entry includes `Task agent status: done`.

### TASK-014: XP And Level Growth v1

Status: ready

Goal:

Add the first non-item growth layer.

Focus on:

- Enemies grant XP on death.
- Player has level and current XP.
- Level up increases one useful stat, such as max HP or base damage.
- Show level and XP in simple sandbox UI.
- Keep XP curve tiny and tunable.

Acceptance:

- Player gains XP by killing enemies.
- Player can level up in the sandbox.
- Level up changes a visible stat.
- Completed task entry includes `Task agent status: done`.

### TASK-015: Skill Unlock v1

Status: blocked by TASK-014

Goal:

Unlock one new ability through vertical progression.

Focus on:

- Unlock one existing or simple new ability at a low level or sandbox objective.
- Prefer a knight ability already close to current code, such as shield charge, dash strike, or a small area slam.
- Show locked/unlocked state in simple UI.
- Do not build a skill tree.

Acceptance:

- Player starts without the ability or with it visibly locked.
- Progression unlocks the ability.
- The ability changes combat behavior.
- Completed task entry includes `Task agent status: done`.

### TASK-016: Sandbox Objective Flow

Status: blocked by TASK-015

Goal:

Turn the sandbox into a short vertical-slice objective sequence.

Focus on:

- Start with a clear objective.
- Require killing enemies.
- Require picking up and equipping a weapon.
- Require reaching a level or unlocking the first skill.
- End with defeating a stronger enemy or completing a simple objective.
- Keep it in the sandbox; do not build the outdoor map yet.

Acceptance:

- Sandbox has a beginning, middle, and completion state.
- The player experiences combat, loot, equipment, XP, and skill unlock in one flow.
- Completed task entry includes `Task agent status: done`.

### TASK-017: First Outdoor Greybox Plan

Status: blocked by TASK-016

Goal:

Plan the first outdoor map only after the vertical sandbox loop is proven.

Focus on:

- Translate the sandbox objective flow into a small outdoor route.
- Define spawn/camp, combat zones, first item drop moment, level-up moment, and dungeon entrance.
- Keep this as a plan before implementation.

Acceptance:

- Plan shows how the vertical loop becomes a 5-10 minute outdoor segment.
- Plan does not require adding a second class first.

## Later / Horizontal Expansion

These are intentionally delayed until the vertical loop works with one class.

### LATER-001: Mage Prototype Plan

Reason:

Second class work is horizontal expansion. Do it after inventory, equipment, XP, skill unlock, and a short objective flow work for the knight.

### LATER-002: Second Enemy Family

Reason:

Add more enemies after the current loop proves item and XP pacing.

### LATER-003: More Equipment Slots

Reason:

Add armor/accessory after the weapon slot proves the item loop.

### LATER-004: Dungeon Greybox

Reason:

Build the dungeon after the outdoor segment has a proven combat-growth route.

## Completed Task Archive

### TASK-001: Project Audit

Status: done

Task agent status: done

Audit Status:

- 2026-05-16 review completed.
- Runtime flow: `project.godot` -> `scenes/maps/combat_sandbox.tscn` -> `KnightPlayer` + spawned mummy enemies + loot/debug roots.

### TASK-002: Standard Asset Integration And Minimal Structure Stabilization

Status: done

Task agent status: done

Audit Status:

- 2026-05-16 review: functionally OK for current sandbox.
- Active accepted sprites are under `assets/sprites/characters/` and `assets/sprites/enemies/`.
- Some older task docs may be stale; prefer this board and active scene/script references.

### TASK-003: Combat Sandbox Plan

Status: done

Task agent status: done

Audit Status:

- 2026-05-16 review: implemented and active as main scene.
- Sandbox has player, enemy spawn markers, `Enemies`, `Loot`, and debug label showing enemy count, HP, damage, facing, and action.

### TASK-004: Player Facing Prototype

Status: done

Task agent status: done

Audit Status:

- 2026-05-16 review: OK.
- `KnightPlayer` has `move_direction`, `aim_direction`, `facing_direction`, and `action_direction`; mouse attacks face aim direction and return to movement-facing after action recovery.

### TASK-005: Basic Hit Loop

Status: done

Task agent status: done

Audit Status:

- 2026-05-16 review: OK.
- Player attacks use delayed hit timing and one-hit-per-swing prevention; mummy enemies take damage, flash, receive knockback/stagger, die, and clean up.

### TASK-006: First Loot And Power Gain

Status: done

Task agent status: done

Audit Status:

- 2026-05-16 review: OK.
- Mummy death drops `DamagePickup`; pickup calls `add_damage_bonus`, and sandbox debug damage display reflects the increased attack damage.

### TASK-007: Combat Sandbox Feel Pass 1

Status: done

Task agent status: done

Owner: task agent

Audit Status:

- 2026-05-16 feel pass completed.
- Runtime wrapper validation passed for `scenes/maps/combat_sandbox.tscn`.
- Player can kill a mummy, spawn damage loot, pick it up, and increase displayed attack damage.
- Light player hit timing and mummy attack timing were nudged later to better match visible active frames.
- Mummy attack lock now covers the full visible attack animation.

Goal:

Improve the current `CombatSandbox` from "functionally works" to "feels readable and worth iterating."

Acceptance:

- Sandbox loads without blocking runtime errors.
- Player can kill at least one enemy and pick up damage loot.
- Combat remains readable and not too fast.
- Any tuning changes are small and easy to revert.
- Completed task entry includes `Task agent status: done`.

### TASK-008: Runtime Smoke Test Script

Status: done

Task agent status: done

Audit Status:

- 2026-05-16 added a narrow CombatSandbox structure smoke test.
- Runtime wrapper validation passed for `tools/smoke_combat_sandbox_structure.gd`.

Goal:

Add or update a narrow Godot smoke test for the combat sandbox.

Acceptance:

- Test can be run through `tools/run_godot.ps1`.
- Test reports pass/fail with concise logs.
- No broad testing framework is introduced.

### TASK-009: Player Combat Feedback Pass

Status: done

Task agent status: done

Audit Status:

- 2026-05-16 added lightweight world-space floating feedback.
- Enemy hits now spawn damage numbers.
- Damage pickup now shows a short `Damage +N` pickup message.
- Runtime wrapper validation passed for the CombatSandbox debug script after feedback changes.
- 2026-05-16 audit confirmed: `debug_combat_sandbox.gd` passes; hit feedback spawns, loot pickup raises damage from 24 to 32.

Goal:

Improve player-facing combat feedback without adding large systems.

Acceptance:

- Player can tell when hits connect.
- Player can tell when loot increased damage.
- Feedback remains readable in the sandbox.

### TASK-010: First SFX Pass

Status: done

Task agent status: done

Audit Status:

- 2026-05-16 organized first accepted SFX into `assets/audio/sfx/`.
- Player attacks now play a swing placeholder.
- Enemy hit and death now play impact/death placeholders.
- Damage pickup now plays a quiet pickup placeholder.
- Runtime wrapper validation passed for the CombatSandbox debug and smoke scripts after SFX wiring.
- 2026-05-16 main-thread review: first wiring exists, but player attack sound mapping is too generic and must be corrected.
- 2026-05-16 revision completed: light attack, heavy attack, shield strike, enemy hit, enemy death, pickup, and movement footsteps now use separate accepted SFX names.

Goal:

Correct and complete sound effect mapping for the current simple combat sandbox.

Acceptance:

- Light attack and heavy attack are audibly different.
- Shield charge / shield strike uses a distinct shield sound.
- Enemy hit and enemy death are audibly different.
- Loot pickup has a simple pickup sound.
- Sound volume is not painful.
- Audio files are placed in a clear `assets/audio/sfx/` structure.
- Completed task entry includes `Task agent status: done`.

### TASK-011: Minimal Inventory And Equipment Proof

Status: done

Task agent status: done

Audit Status:

- 2026-05-16 implemented the first equipment loop.
- Enemy death now drops a visible weapon item instead of direct-stat damage pickup.
- Player pickup adds the weapon to a 10-slot bag and does not immediately change attack damage.
- Equipping the weapon from the bag updates attack damage from 24 to 32 in the sandbox validation.
- CombatSandbox now shows equipped weapon, current damage, and bag slots using accepted item/UI icons.
- Runtime wrapper validation previously passed for `tools/smoke_combat_sandbox_structure.gd`, `tools/debug_player_inputs.gd`, and `tools/debug_combat_sandbox.gd`.
- 2026-05-16 follow-up fixed the `current_scene` timing issue in smoke/debug scripts; runtime validation is reliable again.

Goal:

Replace the temporary direct-stat pickup with the smallest Diablo-like item loop: enemy drops an item, player picks it into a bag, player equips it, and combat stats change.

Acceptance:

- Enemy can drop a weapon item.
- Player can pick the weapon into a small bag.
- Player can equip the weapon.
- Equipped weapon changes attack damage.
- The current equipped weapon and damage value are visible.
- The implementation remains small enough to replace or extend later.
- Completed task entry includes `Task agent status: done`.

## Agent Rules

- Read this file first.
- Read `README.md` and the relevant frozen docs before acting.
- In this Windows workspace, bare `rg` may resolve to a bundled WindowsApps executable that fails with "Access denied"; use the project-local `tools/ripgrep/rg.exe` for ripgrep searches, or PowerShell `Get-ChildItem`, `Select-String`, and `Get-Content` as fallback.
- When running Godot CLI from Codex, use the project wrapper `powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 ...`; do not call Godot directly. The wrapper sets Codex-writable `LOCALAPPDATA`, `APPDATA`, `TEMP`, and `TMP` paths so headless/console runs do not crash.
- Use the project skill `godot-cli` for Godot CLI, headless, smoke test, script test, or automated validation tasks.
- Do not run Godot CLI by default for simple edits. Use it when runtime behavior matters: scene loading, null instances, input wiring, resource paths, AI movement, combat timing, or regressions that static inspection cannot verify.
- Keep validation output small: short smoke tests, narrow debug scripts, selected log lines, and file-specific diffs. Avoid full script dumps, full logs, and full repository diffs unless necessary.
- Do not make broad architecture rewrites.
- Do not replace the frozen design decisions without main-thread review.
- Do not touch unrelated files.
- Do not revert existing user or agent work unless explicitly instructed.
- Prefer small playable changes over future-proof systems.
- When editing, report every changed file.
- When blocked, report the blocker and the smallest useful next step.
- When a task is finished, update that task entry in this file with `Task agent status: done`.

## Reporting Format

When an agent finishes a task, report:

```text
Task:
Status:
Files read:
Files changed:
Summary:
Findings:
Risks:
Recommended next task:
```

Also update the completed task entry in this file:

```text
Task agent status: done
```
