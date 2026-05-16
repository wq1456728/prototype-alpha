# TASK-003 Combat Sandbox Plan

This note defines the first `CombatSandbox.tscn` setup for fast combat-loop testing.

## Scene Location

- Scene: `scenes/maps/combat_sandbox.tscn`
- Script: `scripts/maps/combat_sandbox.gd`
- Active player instance: `scenes/player/knight_player.tscn`
- Active enemy instance: `scenes/enemy/mummy_enemy.tscn`

Keep `scenes/main.tscn` as the old smoke-test scene until the sandbox fully replaces it.

## Node Structure

```text
CombatSandbox (Node2D)
├── Background (ColorRect)
├── Ground (ColorRect)
├── ArenaPathHorizontal (ColorRect)
├── ArenaPathVertical (ColorRect)
├── PlayerSpawn (Marker2D)
├── EnemySpawns (Node2D)
│   ├── DummySpawn (Marker2D)
│   ├── GruntSpawn (Marker2D)
│   └── BruteSpawn (Marker2D)
├── KnightPlayer (instance)
├── Enemies (Node2D)
├── Loot (Node2D)
└── DebugCanvas (CanvasLayer)
    └── DebugLabel (Label)
```

## Required Player Setup

- Use `KnightPlayer` as the only active player for now.
- The player should remain in group `player`.
- TASK-004 should add frozen facing variables to the Knight script:
  - `move_direction`
  - `aim_direction`
  - `facing_direction`
  - `action_direction`
- Keyboard movement remains WASD.
- Basic attack can keep keyboard activation for now, but attack direction must come from mouse aim once TASK-004 is complete.

## Required Enemy Setup

Use three mummy instances:

- `MummyDummy`
  - Low HP.
  - Slow or idle-like pressure.
  - Purpose: hit timing and death checks.
- `MummyGrunt`
  - Baseline chaser.
  - Purpose: movement, pressure, attack exchange.
- `MummyBrute`
  - Higher HP, slower speed, larger display scale.
  - Purpose: repeated hits, loot drop readability, tuning.

All enemies stay in group `enemy`.

## Debug UI

The first debug label should show:

- Enemy count.
- Player HP.
- Current player damage if exposed by TASK-006.
- Facing direction.
- Action direction.
- Last loot or pickup message if practical.

Debug UI is allowed to be plain text. It should not become a full UI framework.

## Test Cases

### Movement

- WASD moves the player in all eight normalized directions.
- Shift still switches to run if retained.
- Player remains readable against the arena background.

### Facing

- While moving and not attacking, the player faces the latest valid movement direction.
- During attack, the player faces the mouse aim direction.
- After recovery, moving returns facing to movement direction.
- After recovery without movement, the player keeps the last attack direction.

### Attack And Hit

- A visible attack starts on input.
- Damage applies on a delayed active frame, not at input time.
- One enemy cannot be hit twice by the same swing unless a multi-hit attack explicitly schedules it.

### Enemy Reaction And Death

- Enemy HP decreases.
- Enemy visibly flashes or tints on hit.
- Enemy receives a small knockback or stagger.
- Enemy plays death and is removed after cleanup.

### Loot And Power

- At least one enemy drops a simple placeholder item.
- The item is visible as a colored square or simple shape.
- Player can pick it up.
- Pickup increases damage or another visible stat.
- Time-to-kill should change after pickup.

## Implementation Order

1. TASK-004: Add player facing variables and mouse-directed attacks.
2. TASK-005: Improve hit feedback, hit timing visibility, enemy knockback/stagger, and death readability.
3. TASK-006: Add a placeholder loot pickup that increases player damage.

## Risks

- Active Knight sprites are side-only, so up/down facing will be represented by side flip or retained side pose until directional art exists.
- Hitboxes are still script-calculated ranges, not visible Area2D hitboxes. This is acceptable for the first sandbox but should get debug drawing later.
- Godot CLI is not available in the current shell, so validation may need manual editor playtesting.
