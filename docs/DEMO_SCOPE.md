# Prototype Alpha Demo Scope

This document freezes the current vertical-slice scope. If older notes conflict with this file, this file wins.

## Product Target

Prototype Alpha is a Godot 4.6 2D dark fantasy ARPG demo.

The target experience is:

- Diablo II-like loot and progression rhythm.
- Chronicon-like WASD control and pseudo top-down readability.
- Slower combat than modern high-speed action roguelites.
- Clear short-term power growth through equipment, levels, and skills.
- A playable 15-20 minute first-map demo for Windows.
- The first outdoor map uses controlled semi-procedural generation: fixed Diablo-like structure, seed-based layout variation, and guaranteed quest-critical anchors.

Resolution target:

- Primary target resolution: `1920x1080`.
- Minimum validation resolution: `1280x720`.
- UI must be designed for 1080p first, but still remain inside the visible screen at 720p.

## Demo Structure

The first demo contains one main playable region:

```text
spawn / camp
-> light quest prompt
-> outdoor field combat
-> first power gain
-> dungeon entrance
-> dungeon combat
-> small boss
-> reward / completion
```

Required content:

- One semi-procedural outdoor map.
- One enterable dungeon.
- One small boss.
- One light quest thread that guides the player through the demo.
- Two playable class prototypes: paladin-style melee and mage-style ranged.
- Basic loot, equipment, level growth, and skill unlocks.
- Complete enough UI to support the loop.

## Core Loop

```text
move
-> attack / cast
-> hit feedback
-> defeat enemies
-> gain experience and loot
-> equip or unlock power
-> push deeper
```

The demo must create at least two noticeable power jumps:

- First jump: early skill or level gain within about 3-5 minutes.
- Second jump: equipment or skill upgrade before the dungeon boss.

## Timeline Target

- 0-2 minutes: player learns movement, attack, loot, and quest direction.
- 2-5 minutes: first combat pressure and first power gain.
- 5-10 minutes: outdoor enemies and elite pressure become meaningful.
- 10-15 minutes: dungeon entry and tighter combat pacing.
- 15-20 minutes: small boss, reward, and demo completion.

## Classes

### Paladin-Style Melee

Purpose: durable close-range combat with readable hits.

Minimum kit:

- Basic melee attack.
- Dash or dash strike.
- Short-range area attack, such as holy shock or weapon slam.
- Simple defensive identity, such as armor, block, or minor sustain.

### Mage-Style Ranged

Purpose: ranged spell combat with clear visual scaling.

Minimum kit:

- Basic magic projectile.
- Fireball or similar direct damage spell.
- Area control spell, such as frost nova or lightning chain.
- Simple resource or cooldown identity.

## Mobility

The demo includes one shared mobility foundation:

- Paladin expression: dash or dash strike.
- Mage expression: blink or short teleport.

Default movement remains readable and slightly slower. Mobility should feel like a power tool, not constant high-speed movement.

## Equipment Scope

The first demo uses a small equipment model:

- Weapon.
- Armor.
- Accessory.

Allowed item qualities:

- Normal.
- Magic.
- Rare.

Allowed stat families:

- Damage.
- Attack or cast speed.
- Health.
- Defense or damage reduction.
- Movement speed.
- Cooldown reduction.
- Critical chance or simple proc chance.

Avoid for this demo:

- Full gear slots.
- Set items.
- Legendary items.
- Crafting.
- Economy.
- Large affix pools.
- Complex inventory management.

## Quest Scope

The first demo includes one light quest thread, not a full narrative system.

Acceptable quest goals:

- Clear enemies in the outdoor field.
- Find the dungeon entrance.
- Defeat the dungeon boss.
- Return or trigger a completion screen.

Avoid:

- Branching dialogue.
- Multiple quest chains.
- Reputation systems.
- Large story scenes.

## Out Of Scope

Do not build these unless explicitly re-scoped:

- Procedural dungeon generation.
- Fully freeform procedural overworld generation.
- Multiplayer.
- Full save/load architecture.
- Large skill trees.
- Rune systems.
- Crafting.
- Economy.
- Large UI frameworks.
- Broad ECS or architecture rewrites.
- Full commercial content planning.

## Acceptance Criteria

The demo scope is successful when:

- A new player understands the combat loop within 30 seconds.
- The player receives a clear power increase within 5 minutes.
- Loot creates at least one obvious "I am stronger" moment.
- The dungeon boss can block unprepared players but is beatable after growth.
- A full run from spawn to boss reward takes about 15-20 minutes.
- Combat, loot, and growth all feel worth continuing.
