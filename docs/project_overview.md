# Project Overview

Prototype Alpha is a Godot 4.6 2D dark fantasy ARPG demo.

The project is not trying to clone Diablo II's 45-degree isometric presentation. The design target is Diablo II-like loot pacing and long-term motivation, combined with Chronicon-like WASD control and pseudo top-down pixel-art readability.

## Current Stage

The project is in the demo / vertical-slice stage.

The current goal is a 15-20 minute first-map demo for Windows:

- One outdoor area.
- One enterable dungeon.
- One small boss.
- One light quest thread.
- Two class prototypes: paladin-style melee and mage-style ranged.
- Equipment, loot, level growth, and skill unlocks.
- Enough UI to make the loop understandable.

## Experience Target

The player should feel this loop quickly:

```text
move
-> attack / cast
-> hit feedback
-> defeat enemies
-> gain experience and loot
-> equip or unlock power
-> continue fighting
```

The demo should create two clear power jumps:

- An early skill or level gain.
- A later equipment or skill upgrade before the boss.

## Frozen Decisions

- Engine: Godot 4.6.
- Platform: Windows first.
- Movement: WASD.
- Aim: mouse direction for attacks and skills.
- Default facing: movement direction.
- Action facing: mouse direction during attack or cast.
- View: Chronicon-like pseudo top-down, not Diablo II 45-degree isometric.
- Art source: mainly external AI generation, validated before import.
- Combat rhythm: slower and more deliberate than high-speed action roguelites.

## Source Of Truth

Use these documents for current planning:

- [Demo Scope](DEMO_SCOPE.md)
- [Control And Combat Rules](CONTROL_AND_COMBAT.md)
- [Art Pipeline](ART_PIPELINE.md)

If older notes conflict with these documents, the frozen documents win.

## Design Principles

- Build a playable loop before expanding systems.
- Prefer combat feel, readable feedback, and short-term growth over large architecture.
- Keep the demo small enough for fast solo iteration.
- Use equipment and skill gains to create real power jumps.
- Avoid large systems until the core loop proves itself in a playable build.
