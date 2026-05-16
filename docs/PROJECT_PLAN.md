# Project Plan

This is the long-term plan for the Prototype Alpha vertical slice.

The current source-of-truth scope is:

- 15-20 minute Windows demo.
- Godot 4.6.
- 2D dark fantasy ARPG.
- Diablo II-like loot and progression rhythm.
- Chronicon-like WASD control and pseudo top-down presentation.
- One outdoor map.
- One enterable dungeon.
- One small boss.
- One light quest thread.
- Two class prototypes: paladin-style melee and mage-style ranged.

## Milestone 0: Project Audit And Rules

Goal:

Understand what already exists and align all future work with the frozen design docs.

Tasks:

- Audit current scenes, scripts, assets, animations, and input setup.
- Decide which current player and enemy code can be kept.
- Decide which temporary assets should be replaced.
- Confirm folder conventions for scenes, scripts, sprites, animation resources, and raw AI outputs.
- Do a small structure stabilization pass before building the combat sandbox.
- Separate raw AI output from accepted gameplay sprites.
- Identify the active player scene, enemy scene, sprite assets, and animation resources.
- Mark temporary assets clearly instead of trying to solve all art quality now.
- Keep `TASK_BOARD.md` updated with the next active task.

Acceptance:

- Project structure is understood.
- Keep / redo list exists.
- Active project conventions are clear enough for another agent to continue.
- Obvious folder and resource confusion is reduced without broad refactoring.
- First `CombatSandbox.tscn` plan is clear.

Do not turn this milestone into a full architecture cleanup. The goal is to reduce confusion before combat work, not to perfect the whole codebase.

## Milestone 1: Combat Sandbox

Goal:

Create a small scene where movement, facing, attacks, hit feedback, enemy death, and loot can be tested quickly.

Tasks:

- Create or identify `CombatSandbox.tscn`.
- Add player spawn.
- Add dummy enemy.
- Add melee chaser enemy.
- Add simple debug labels if useful.
- Verify WASD movement.
- Verify mouse aim direction.
- Verify frozen facing rules.
- Verify one basic attack loop.

Acceptance:

- Player can move with WASD.
- Player faces movement direction while moving normally.
- Player faces mouse direction during attack or cast.
- Player can damage and kill an enemy.
- Combat changes can be tested without using the full map.

## Milestone 2: First Combat Feel Pass

Goal:

Make the minimum attack loop feel readable and satisfying.

Tasks:

- Align hit detection to visible active frames.
- Add enemy hit flash.
- Add enemy knockback or stagger.
- Add damage numbers.
- Add basic hit sound placeholders if available.
- Add short hit stop for meaningful hits.
- Tune movement speed, attack range, attack recovery, and enemy health.

Acceptance:

- Hits are visually readable.
- Player understands when an attack connects.
- Enemy death is clear.
- Combat remains slow enough for Diablo II-like pacing.

## Milestone 3: First Loot And Growth Loop

Goal:

Prove the smallest loot-driven power increase.

Tasks:

- Add one item drop from enemy death.
- Add pickup behavior.
- Add a simple equipment or stat application path.
- Add one visible stat change, such as damage.
- Add a simple UI readout or combat-visible effect.

Acceptance:

- Enemy can drop an item.
- Player can pick it up.
- Player becomes stronger in a visible way.
- Time-to-kill changes after the upgrade.

## Milestone 4: Class Prototype Split

Goal:

Split the player into two playable class prototypes without building a full class framework.

Tasks:

- Paladin-style melee basic attack.
- Paladin mobility skill: dash or dash strike.
- Paladin area skill: holy shock, slam, or burst.
- Mage basic projectile.
- Mage mobility skill: blink.
- Mage area or control skill: fireball, frost nova, or lightning chain.
- Minimal class selection or test spawning.

Acceptance:

- Both classes can complete the combat sandbox loop.
- Paladin and mage feel meaningfully different.
- Shared systems are reused only where they reduce real duplication.

## Milestone 5: Outdoor Map Greybox

Goal:

Build the first outdoor region in greybox form before final art.

Tasks:

- Create outdoor map layout.
- Add spawn / camp area.
- Add combat zones.
- Add enemy groups.
- Add elite or tougher encounter.
- Add dungeon entrance.
- Add simple quest direction.

Acceptance:

- Player can move from spawn to dungeon entrance.
- Outdoor section supports about 5-10 minutes of play after tuning.
- Player receives at least one early power gain.

## Milestone 6: Dungeon And Small Boss

Goal:

Create the second half of the demo: dungeon pressure and a small boss.

Tasks:

- Create dungeon greybox.
- Add entry and exit flow.
- Add dungeon enemy groups.
- Add one small boss arena.
- Add boss with 2-3 readable attacks.
- Add boss health bar.
- Add boss reward.

Acceptance:

- Player can enter the dungeon.
- Dungeon has stronger pressure than the outdoor map.
- Boss blocks underpowered play but is beatable after growth.
- Boss kill completes the demo loop.

## Milestone 7: UI And Quest Pass

Goal:

Add enough UI to make the vertical slice understandable.

Tasks:

- Player health display.
- Skill cooldown display.
- Experience or level display.
- Loot pickup feedback.
- Simple equipment comparison or stat display.
- Quest objective text.
- Boss health bar.
- Death and completion screens.

Acceptance:

- Player understands health, skills, loot, and current objective.
- UI is functional and not larger than the demo needs.

## Milestone 8: Art Replacement And Animation Stability

Goal:

Replace temporary visuals with consistent AI-assisted pixel art.

Tasks:

- Generate or select player class sprites.
- Generate or select enemy sprites.
- Generate or select boss sprites.
- Generate skill effects.
- Generate item icons.
- Validate canvas size, frame counts, transparency, feet baselines, and style consistency.
- Wire accepted assets into Godot `SpriteFrames`.

Acceptance:

- Player and enemies share a consistent visual style.
- Animation swaps do not jitter.
- Hit timing matches visible frames.
- Temporary assets are clearly marked or removed from active scenes.

## Milestone 9: Full 15-20 Minute Run

Goal:

Tune the full demo from spawn to boss reward.

Tasks:

- Tune enemy density.
- Tune enemy health and damage.
- Tune experience curve.
- Tune drop rates.
- Tune item stat ranges.
- Tune skill cooldowns.
- Tune boss difficulty.
- Run repeated full demo passes.

Acceptance:

- Full run takes about 15-20 minutes.
- Player gets at least two noticeable power jumps.
- Combat, loot, and growth all support the same loop.

## Milestone 10: Demo Polish And Export

Goal:

Prepare a playable Windows demo build.

Tasks:

- Add missing sound placeholders or final sounds.
- Add final hit, pickup, and boss feedback.
- Fix blocking bugs.
- Check performance.
- Check input defaults.
- Check window and resolution behavior.
- Export Windows build.

Acceptance:

- Demo can be played from start to finish.
- Windows export runs.
- Known issues are documented.
