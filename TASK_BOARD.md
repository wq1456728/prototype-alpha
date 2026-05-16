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

Combat sandbox feel pass and next playable-loop expansion.

## Current Goal

The first combat-growth loop is functionally present. The next goal is to make the sandbox feel better, verify it through Godot runtime checks, and prepare the next prototype slice:

```text
WASD movement
-> mouse-aim attack / cast
-> hit enemy
-> enemy reacts and dies
-> enemy drops loot
-> player equips or gains power
-> combat gets easier or changes
-> combat feel is tuned enough to support class and map work
```

## Active Task

### TASK-007: Combat Sandbox Feel Pass 1

Status: done

Task agent status: done

Owner: task agent

Audit:

- 2026-05-16 feel pass completed.
- Runtime wrapper validation passed for `scenes/maps/combat_sandbox.tscn`.
- Player can kill a mummy, spawn damage loot, pick it up, and increase displayed attack damage.
- Light player hit timing and mummy attack timing were nudged later to better match visible active frames.
- Mummy attack lock now covers the full visible attack animation.

Goal:

Improve the current `CombatSandbox` from "functionally works" to "feels readable and worth iterating."

Focus on:

- Verify the sandbox launches through the project Godot wrapper.
- Check player movement speed, run speed, attack lock times, and recovery.
- Check enemy approach speed, attack range, attack cooldown, and soft collision.
- Check attack hit timing against visible frames.
- Check hit feedback: flash, knockback, death cleanup, damage growth visibility.
- Keep changes small and parameter-focused where possible.

Expected output:

- Runtime validation result.
- Tuning changes made.
- Before / after feel summary.
- Remaining combat feel issues.
- Recommended next task.

Acceptance:

- Sandbox loads without blocking runtime errors.
- Player can kill at least one enemy and pick up damage loot.
- Combat remains readable and not too fast.
- Any tuning changes are small and easy to revert.
- Completed task entry includes `Task agent status: done`.

## Backlog

### TASK-008: Runtime Smoke Test Script

Status: done

Task agent status: done

Audit:

- 2026-05-16 added a narrow CombatSandbox structure smoke test.
- Runtime wrapper validation passed for `tools/smoke_combat_sandbox_structure.gd`.

Goal:

Add or update a narrow Godot smoke test for the combat sandbox.

Focus on:

- Launch `scenes/maps/combat_sandbox.tscn`.
- Confirm player exists.
- Confirm enemies spawn.
- Confirm debug label exists.
- Confirm loot root exists.
- Keep output short.

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

Focus on:

- Clearer hit impact feedback.
- Damage number or simple impact text if not already present.
- Pickup feedback when damage bonus increases.
- Light screen shake or hit stop only if it improves readability.
- Avoid complex UI or audio pipelines.

Acceptance:

- Player can tell when hits connect.
- Player can tell when loot increased damage.
- Feedback remains readable in the sandbox.

### TASK-010: First SFX Pass

Status: done

Task agent status: done

Audit:

- 2026-05-16 organized first accepted SFX into `assets/audio/sfx/`.
- Player attacks now play a swing placeholder.
- Enemy hit and death now play impact/death placeholders.
- Damage pickup now plays a quiet pickup placeholder.
- Runtime wrapper validation passed for the CombatSandbox debug and smoke scripts after SFX wiring.
- 2026-05-16 main-thread review: first wiring exists, but player attack sound mapping is too generic and must be corrected.
- 2026-05-16 revision completed: light attack, heavy attack, shield strike, enemy hit, enemy death, pickup, and movement footsteps now use separate accepted SFX names.

Goal:

Correct and complete sound effect mapping for the current simple combat sandbox.

Focus on:

- Player light attack must use a lighter slash sound.
- Player heavy attack must use a different, heavier slash sound.
- Player shield charge / shield strike must use a separate crisp shield-impact sound.
- If two downloaded slash sounds are available, assign the lighter/brighter one to light attack and the heavier/deeper one to heavy attack.
- Enemy hit must have its own enemy-hit impact sound.
- Enemy death must have its own enemy-death sound.
- Loot pickup sound can remain simple, but should not be confused with combat hit sounds.
- Running footsteps should play during normal movement and stop during idle or attack locks.
- Check that the current assigned sounds match the action that triggered them.
- Keep audio wiring local and simple.
- Keep volume balanced and not painful.
- Do not introduce a large audio manager yet.

Acceptance:

- Light attack and heavy attack are audibly different.
- Shield charge / shield strike uses a distinct shield sound.
- Enemy hit and enemy death are audibly different.
- Loot pickup has a simple pickup sound.
- Sound volume is not painful.
- Audio files are placed in a clear `assets/audio/sfx/` structure.
- Completed task entry includes `Task agent status: done`.

### TASK-011: Enemy Pressure Pass 1

Status: ready

Goal:

Make the current mummy enemies create basic pressure without overwhelming the player.

Focus on:

- Dummy enemy remains useful for testing.
- Grunt enemy pressures the player.
- Brute enemy is slower but more threatening.
- Tune enemy HP, speed, cooldown, and attack ranges.
- Preserve simple AI.

Acceptance:

- Player can kite and reposition.
- Enemies do not clump into unreadable overlap.
- Brute is meaningfully different from grunt.

### TASK-012: Loot Feedback And Minimal Item Variety

Status: ready

Goal:

Expand the current damage pickup into a slightly clearer demo-stage loot proof.

Focus on:

- Keep pickup logic simple.
- Add visible pickup label, color, or icon if useful.
- Consider one additional stat pickup only if it is cheap: health restore, cooldown, or movement.
- Do not build inventory yet.

Acceptance:

- Loot is visible.
- Pickup effect is obvious.
- No inventory or large item framework is introduced.

### TASK-013: Mage Prototype Plan

Status: blocked by TASK-007

Goal:

Plan the ranged class prototype before implementation.

Focus on:

- Reuse current player movement/facing rules.
- Define basic projectile attack.
- Define one mobility expression, likely blink.
- Define one simple area spell.
- List required placeholder assets.
- Keep implementation scope similar to the current knight sandbox.

Expected output:

- Mage scene/script strategy.
- Required assets.
- Minimal test plan.
- Risks before implementation.

Acceptance:

- Plan is concrete enough for a worker to implement without re-deciding class direction.

## Completed Task Archive

### TASK-001: Project Audit

Status: done

Task agent status: done

Audit:

- 2026-05-16 review completed.
- Runtime flow: `project.godot` -> `scenes/maps/combat_sandbox.tscn` -> `KnightPlayer` + spawned mummy enemies + loot/debug roots.

### TASK-002: Standard Asset Integration And Minimal Structure Stabilization

Status: done

Task agent status: done

Audit:

- 2026-05-16 review: functionally OK for current sandbox.
- Active accepted sprites are under `assets/sprites/characters/` and `assets/sprites/enemies/`.
- Some older task docs may be stale; prefer this board and active scene/script references.

### TASK-003: Combat Sandbox Plan

Status: done

Task agent status: done

Audit:

- 2026-05-16 review: implemented and active as main scene.
- Sandbox has player, enemy spawn markers, `Enemies`, `Loot`, and debug label showing enemy count, HP, damage, facing, and action.

### TASK-004: Player Facing Prototype

Status: done

Task agent status: done

Audit:

- 2026-05-16 review: OK.
- `KnightPlayer` has `move_direction`, `aim_direction`, `facing_direction`, and `action_direction`; mouse attacks face aim direction and return to movement-facing after action recovery.

### TASK-005: Basic Hit Loop

Status: done

Task agent status: done

Audit:

- 2026-05-16 review: OK.
- Player attacks use delayed hit timing and one-hit-per-swing prevention; mummy enemies take damage, flash, receive knockback/stagger, die, and clean up.

### TASK-006: First Loot And Power Gain

Status: done

Task agent status: done

Audit:

- 2026-05-16 review: OK.
- Mummy death drops `DamagePickup`; pickup calls `add_damage_bonus`, and sandbox debug damage display reflects the increased attack damage.

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
