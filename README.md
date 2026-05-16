# Prototype Alpha

Prototype Alpha is a Godot 4.6 2D dark fantasy ARPG demo.

The current target is a 15-20 minute Windows vertical slice with Diablo II-like loot and progression rhythm, Chronicon-like WASD controls, and a pseudo top-down pixel-art presentation.

## Frozen Planning Docs

These documents are the current source of truth:

- [Task Board](TASK_BOARD.md)
- [Demo Scope](docs/DEMO_SCOPE.md)
- [Control And Combat Rules](docs/CONTROL_AND_COMBAT.md)
- [Art Pipeline](docs/ART_PIPELINE.md)
- [Project Plan](docs/PROJECT_PLAN.md)
- [Project Overview](docs/project_overview.md)

If older notes conflict with these files, the frozen documents win.

## Current Demo Target

- One outdoor map.
- One enterable dungeon.
- One small boss.
- One light quest thread.
- Two class prototypes: paladin-style melee and mage-style ranged.
- WASD movement with mouse-aimed attacks and skills.
- Loot, equipment, level growth, skill unlocks, and enough UI to support the loop.

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

## Current Priorities

- Combat feel.
- Readable movement and facing.
- Stable sprite animation.
- Satisfying hit feedback.
- Enemy pressure.
- Short-term power growth.
- Loot clarity.
- Fast in-game iteration.

## Scope Control

Do not build these unless the demo is explicitly re-scoped:

- Multiplayer.
- Procedural dungeon generation.
- Full save/load architecture.
- Large skill trees.
- Rune systems.
- Crafting.
- Economy.
- Large UI frameworks.
- Broad architecture rewrites.

## Daily Check

Before adding a feature, ask:

- Does it improve combat?
- Does it improve loot?
- Does it improve growth?
- Can it be tested quickly in-game?
