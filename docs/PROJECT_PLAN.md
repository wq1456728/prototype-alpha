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

## Milestone 3: Vertical Item And Growth Loop

Goal:

Prove the smallest Diablo-like vertical progression chain with one class before expanding horizontally.

Tasks:

- Replace direct-stat pickup with item pickup into a small bag.
- Add one equipment slot first: weapon.
- Equip weapon to change attack damage.
- Add simple item data: name, rarity, damage bonus, icon/color.
- Add tiny drop roll logic for normal, magic, and rare weapons.
- Add functional inventory/equipment UI.
- Add XP and level growth.
- Add one progression-based skill unlock.
- Add a sandbox objective flow that uses combat, loot, equipment, XP, and skill unlock.

Acceptance:

- Enemy can drop weapon items.
- Player can pick items into a small bag.
- Player can equip a weapon.
- Equipped weapon changes combat stats.
- Player can gain XP and level up.
- Player can unlock one new ability.
- The sandbox has a short beginning-to-completion flow.

## Milestone 4: Outdoor Greybox

Goal:

Move the proven vertical sandbox loop into the first outdoor greybox.

Tasks:

- Create outdoor map layout.
- Add spawn / camp area.
- Add combat zones.
- Add first item drop moment.
- Add first level-up or skill-unlock moment.
- Add elite or tougher encounter.
- Add dungeon entrance.
- Add simple quest direction.

Acceptance:

- Player can move from spawn to dungeon entrance.
- Outdoor section supports about 5-10 minutes of play after tuning.
- Player receives at least one early power gain.
- Outdoor flow reuses the proven sandbox systems instead of inventing new ones.

## Milestone 5: Horizontal Prototype Expansion

Goal:

Expand content after the vertical loop works.

Tasks:

- Plan and implement mage prototype.
- Add second enemy family.
- Add more equipment slots only after weapon slot works.
- Add more skill variants.
- Add more item stat types.

Acceptance:

- New class or enemy content uses existing item, XP, skill, and combat systems.
- Horizontal additions do not force a rewrite of the vertical loop.

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
