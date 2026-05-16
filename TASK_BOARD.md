# Task Board

This file is the handoff point for other conversations or agents. Read this first before doing project work.

## Source Of Truth

Current planning and implementation rules:

- [README.md](README.md)
- [docs/DEMO_SCOPE.md](docs/DEMO_SCOPE.md)
- [docs/CONTROL_AND_COMBAT.md](docs/CONTROL_AND_COMBAT.md)
- [docs/ART_PIPELINE.md](docs/ART_PIPELINE.md)
- [docs/PROJECT_PLAN.md](docs/PROJECT_PLAN.md)
- [ASSET_PROMPT_TEMPLATE.md](ASSET_PROMPT_TEMPLATE.md)

If older notes conflict with these files, the files above win.

## Current Phase

Combat sandbox and current-project audit.

## Current Goal

Build toward the first playable combat-growth loop:

```text
WASD movement
-> mouse-aim attack / cast
-> hit enemy
-> enemy reacts and dies
-> enemy drops loot
-> player equips or gains power
-> combat gets easier or changes
```

## Active Task

### TASK-001: Project Audit

Status: ready

Owner: unassigned

Instruction:

Scan the current Godot project. Do not edit files.

Focus on:

- Project structure.
- Player scenes and scripts.
- Enemy scenes and scripts.
- Current combat implementation.
- Animation resources and sprite assets.
- Existing input map assumptions.
- Any current demo or test scenes.

Expected output:

- Current project structure summary.
- Player system status.
- Enemy system status.
- Combat system status.
- Animation and asset status.
- Keep / redo recommendations.
- Suggested `CombatSandbox.tscn` plan.
- Risks or unclear decisions that need main-thread review.

## Backlog

### TASK-002: Combat Sandbox Plan

Status: blocked by TASK-001

Goal:

Define the first `CombatSandbox.tscn` setup after the audit.

Expected output:

- Scene node structure.
- Required player instance.
- Required enemy instances.
- Debug UI or labels.
- Test cases for movement, facing, attack, hit, death, and loot.

### TASK-003: Player Facing Prototype

Status: blocked by TASK-002

Goal:

Implement the frozen facing rules:

- Movement-facing when not attacking or casting.
- Mouse-facing during attack or cast.
- Return to movement-facing after recovery if movement is active.

### TASK-004: Basic Hit Loop

Status: blocked by TASK-003

Goal:

Implement one basic attack loop:

- Visible attack animation or placeholder.
- Active hit timing.
- Enemy damage.
- Enemy hit flash.
- Knockback or stagger.
- Enemy death.

### TASK-005: First Loot And Power Gain

Status: blocked by TASK-004

Goal:

Implement the smallest possible loot-growth proof:

- Enemy drops one item.
- Player can pick it up.
- Item increases damage or another visible stat.
- Player can feel the change in combat.

## Agent Rules

- Read this file first.
- Read `README.md` and the relevant frozen docs before acting.
- Do not make broad architecture rewrites.
- Do not replace the frozen design decisions without main-thread review.
- Do not touch unrelated files.
- Do not revert existing user or agent work unless explicitly instructed.
- Prefer small playable changes over future-proof systems.
- When editing, report every changed file.
- When blocked, report the blocker and the smallest useful next step.

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
