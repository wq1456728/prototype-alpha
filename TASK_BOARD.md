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

### TASK-011: Item System Skeleton

Status: done

Task agent status: done

Audit Status:

- 2026-05-16 added `data/items/item_definitions.json` with item types, equipment slots, and weapon definitions.
- Added `ItemDatabase` loader/lookup helpers for item definitions, equipment slots, and normalized `ItemInstance` dictionaries.
- Player inventory now stores item instances and equipment uses generic equipment slots with weapon active now.
- Equipped stats are applied through reusable `stat_modifiers.damage` while preserving current attack damage UI.
- Existing ground pickup, cursor item, equip, swap, and drop flows remain compatible.
- Runtime wrapper validation passed for `tools/smoke_combat_sandbox_structure.gd` and `tools/debug_combat_sandbox.gd`.

Goal:

Refactor the current loot/equipment prototype into a real minimal item-system skeleton. Content can stay tiny, but the architecture must be usable for later Diablo-like expansion.

Focus on:

- Use the name `Item System`, not `Equipment System`; equipment is only one item-system use case.
- Add data-driven item definitions from simple config files, preferably JSON under `data/items/`.
- Do not use SQL or an external database for this demo stage.
- Separate static `ItemDefinition` from dropped/owned `ItemInstance`.
- Add a small `ItemDatabase` loader/lookup layer.
- Add item categories/types that can grow later: weapon, armor, accessory, consumable, material, quest.
- Implement only weapon behavior now, but do not hardcode the system as weapon-only.
- Add equipment slot definitions that can grow later: weapon, chest, accessory. Only weapon must be active now.
- Add stat-modifier structure for item effects, starting with damage.
- Preserve current sandbox behavior where possible, but remove direct-stat pickup assumptions.
- Keep implementation local and simple; no save/load, stash, vendor, crafting, durability, sockets, sets, or legendary logic.

Acceptance:

- Item definitions are loaded from config, not only hardcoded in a pickup script.
- Dropped and inventory items are represented as item instances referencing definitions.
- Inventory can store item instances without knowing only about weapons.
- Equipment can equip a weapon item instance through a generic slot path.
- Equipped item stats affect player damage through a reusable stat application path.
- Skeleton has clear extension points for armor/accessory/consumable without rewriting the core.
- Completed task entry includes `Task agent status: done`.

## Backlog

### TASK-012: Item Drop Roll And Instance Data v1

Status: ready

Goal:

Make enemy drops use the item-system skeleton instead of fixed item results.

Focus on:

- Define a tiny item-definition table with a few weapon bases.
- Define rarity config: normal, magic, rare.
- Roll item instance rarity and stat values from config.
- Use Diablo-like principles at small scale: base item + rarity + rolled stats = concrete dropped item.
- Keep affixes simple; a single rolled damage modifier is enough for now.
- Keep drop tables small and readable, but make the shape expandable by enemy type or area later.
- World item display should use item name and rarity color.
- Do not build full prefix/suffix pools yet.

Acceptance:

- Enemy drops create rolled `ItemInstance` data.
- Same item definition can produce different concrete drops.
- Rarity changes item display and stat range.
- Drop logic can later add more item types without replacing the whole path.
- Completed task entry includes `Task agent status: done`.

### TASK-013: Inventory And Equipment UI v1

Status: blocked by TASK-011

Goal:

Make the item-system skeleton visible and usable through a small but real inventory/equipment UI.

Focus on:

- Press `B` to toggle inventory visibility.
- Inventory starts hidden by default.
- Show 8-12 bag slots backed by inventory item instances.
- Show equipment slots in a structure that can grow: weapon active now, chest/accessory can be disabled or placeholder.
- Support Diablo-like mouse item handling at minimum: click ground item, hold item on cursor, place in bag, equip, swap, and drop back to world.
- Cursor-held item should block combat input.
- Show selected/hovered item name, rarity, type, slot, and rolled stats.
- Show current attack damage and equipped weapon.
- Keep UI functional, not final art.
- Do not build stash, vendor, sorting, item comparison, or drag polish yet.

Implementation Notes:

- 2026-05-16 sandbox pre-work: player, enemies, and world loot were moved under one `WorldEntities` y-sort parent so item/equipment playtests use foot-position draw order instead of fixed player-over-monster layering.

Acceptance:

- Player can open/close inventory with `B`.
- Player can pick a world item into cursor/bag.
- Player can equip a weapon through the generic equipment slot path.
- Player can swap/drop items without item loss.
- UI proves the item system, not a weapon-only shortcut.
- Completed task entry includes `Task agent status: done`.

### TASK-014: Progression System Skeleton

Status: ready

Goal:

Refactor XP/level growth into a small progression-system skeleton that can later support skill points, stat points, and level-gated systems.

Focus on:

- Keep current XP gain and level-up behavior if it works.
- Separate progression state from direct combat code where practical.
- Track level, current XP, XP to next level, and available skill points.
- Use a small tunable progression config/table for XP curve and rewards.
- Level-up should award at least one future-use resource, such as skill point.
- A small base stat gain is acceptable, but avoid making level-up only a hardcoded damage bump.
- Show level, XP, and available skill points in the sandbox UI.
- Do not build full stat allocation yet.

Acceptance:

- Enemy kills grant XP through a reusable progression path.
- Player can level up.
- Level-up awards skill points or another explicit progression resource.
- Combat stats can still react to level if configured.
- System can feed the later skill tree without rewriting XP logic.
- Completed task entry includes `Task agent status: done`.

### TASK-015: Minimal Skill Tree Skeleton

Status: blocked by TASK-014

Goal:

Create a real minimal skill-tree structure with only a few low-tier nodes implemented or configured.

Focus on:

- Add data-driven skill definitions, preferably under `data/skills/`.
- Support skill id, name, description, skill type, required level, required skill ids, max rank, current rank, unlock cost, and active/passive flag.
- Create a tiny knight/paladin skill tree config with 1-2 low-tier skills and optional placeholder locked nodes.
- Implement only one actual new or gated ability if needed; structure matters more than content volume.
- Skill points from progression should unlock or rank up skills.
- UI can be minimal: a small panel/list/tree, not a final Diablo II-style visual tree yet.
- Do not build a full skill tree UI, respec system, class-wide tree library, or dozens of skills.

Acceptance:

- Skills are defined as data, not only `if level >= X`.
- Player can spend a skill point to unlock or rank up a configured skill.
- Skill prerequisites/level requirements exist in the structure.
- At least one unlocked skill changes combat behavior.
- Completed task entry includes `Task agent status: done`.

### TASK-016: Sandbox Objective Flow

Status: blocked by TASK-015

Goal:

Turn the sandbox into a short vertical-slice objective sequence using the real item and progression skeletons.

Focus on:

- Start with a clear objective.
- Require killing enemies.
- Require picking up and equipping a weapon.
- Require gaining XP and leveling up.
- Require unlocking or using the first skill-tree skill.
- End with defeating a stronger enemy or completing a simple objective.
- Keep it in the sandbox; do not build the outdoor map yet.

Acceptance:

- Sandbox has a beginning, middle, and completion state.
- The player experiences combat, item drop, inventory, equipment, XP, skill point, skill unlock, and completion in one flow.
- Completed task entry includes `Task agent status: done`.

### TASK-017: First Outdoor Greybox Plan

Status: blocked by TASK-016

Goal:

Plan the first outdoor map only after the vertical sandbox loop is proven.

Focus on:

- Translate the sandbox objective flow into a small outdoor route.
- Define spawn/camp, combat zones, first item drop moment, level-up moment, first skill unlock moment, and dungeon entrance.
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
