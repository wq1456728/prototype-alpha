---
name: demo-stage-game-dev
description: Use for this Godot 2D ARPG prototype when making gameplay, combat, enemy, skill, progression, or demo-scope decisions. Prioritize a small playable demo, combat feel, readable action, animation stability, hit feedback, and fast iteration over large systems or future-proof architecture.
---

# Demo Stage Game Development

## Goal

Build a small but complete playable 2D pixel ARPG demo. The demo should make players understand the core loop quickly and feel that combat and short-term growth are worth continuing.

Core loop:

```text
move -> attack -> hit feedback -> defeat enemies -> gain power -> continue fighting
```

## Priorities

Prefer changes that improve:

- combat feel
- responsiveness
- readable gameplay
- stable animation
- satisfying hit feedback
- enemy pressure
- short-term power growth
- fast iteration

When tradeoffs conflict, choose the smaller playable implementation that improves combat feel now.

## Scope Control

Avoid expanding into large systems unless the user explicitly asks:

- full inventory systems
- complete itemization
- procedural generation
- multiplayer
- large UI frameworks
- save/load frameworks
- ECS migrations
- broad refactors

For oversized requests, reduce them to a demo-stage version. Example: implement one simple drop that proves power growth instead of a full loot system.

## Gameplay Implementation Guidance

Keep Godot code simple and local to the feature being changed.

Prefer:

- direct CharacterBody2D behavior for prototype combat
- clear constants for tuning timing, speed, damage, ranges, and cooldowns
- small reusable helpers only when they remove real duplication
- quick in-game testability over abstract system design

Avoid:

- unnecessary managers or singletons
- broad architecture rewrites
- speculative extension points
- changing unrelated systems while tuning feel

## Validation

For gameplay changes, check:

- Can the player understand the action within 30 seconds?
- Does the change make combat more responsive or readable?
- Are animation timing and hit timing aligned?
- Is the implementation small enough to iterate again quickly?
