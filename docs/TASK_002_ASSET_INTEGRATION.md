# TASK-002 Asset Integration Notes

This note records the current asset conventions and low-risk stabilization decisions made for TASK-002.

## Active Runtime Flow

- Main scene: `scenes/main.tscn`.
- Active player scene: `scenes/player/knight_player.tscn`.
- Active player script: `scripts/player/knight_player.gd`.
- Active enemy scene: `scenes/enemy/mummy_enemy.tscn`.
- Active enemy script: `scripts/enemy/mummy_enemy.gd`.
- Active animation resource exception: `assets/animations/knight_shield_charge_attack.tres`.

`warrior_player` and `samurai_women_player` remain inactive prototype scenes. They are not wired from `scenes/main.tscn`.

## Active Asset Folder Convention

Accepted gameplay sprites should live under:

- `assets/sprites/characters/<character>/`
- `assets/sprites/enemies/<enemy>/`
- `assets/sprites/bosses/`
- `assets/sprites/effects/`
- `assets/sprites/items/`
- `assets/animations/`

Raw or unvalidated source output should remain under:

- `assets/raw/`

Temporary processed intermediates should remain under:

- `assets/processed/`

Do not move imported resources during sandbox work unless references are checked first.

## Accepted Assets

- `assets/sprites/characters/knight/class_knight_*_side.png`
  - Current accepted active player sprites.
  - Sheet frame size: `128x112`.
  - Direction coverage: side only, mirrored by `AnimatedSprite2D.flip_h`.
  - Current animation counts in code: idle 7, walk 8, run 8, attack_1 6, attack_2 5, attack_3 6 with repeated frames, hurt 4, death 12.
- `assets/sprites/enemies/mummy/enemy_mummy_*_side.png`
  - Current accepted active enemy sprites.
  - Sheet frame size: `64x64`.
  - Current animation counts in code: idle 4, walk 6, attack 6, hurt 2, death 6.
- `assets/sprites/enemies/{deceased,hyena,scorpio,snake,vulture}/enemy_*_side.png`
  - Accepted as organized enemy sprite-sheet candidates.
  - Not active in the current runtime flow.

## Temporary Assets That Remain

- `assets/animations/knight_shield_charge_attack.tres`
  - Still references `assets/raw/Knight/without_outline/shield_charge_attack_sprite.png`.
  - Kept because it is already wired into `knight_player.gd` and preserves the current shield-charge test.
- `assets/processed/enemy/mummy/`
  - Treated as temporary processed output and alignment preview material.
  - Not used by the active runtime flow after TASK-002.
- `assets/raw/`
  - Kept as source material and rejected/unvalidated output.
  - Includes older Knight, Warrior, Samurai, Samurai_Women, and Enemy folders.

## Rejected Or Not Active For CombatSandbox

- Old script paths under `assets/sprites/Knight/`, `assets/sprites/Enemy/Mummy/`, `assets/sprites/Warrior/`, and `assets/sprites/Samurai_Women/` are not valid in the current project tree.
- `scenes/player/warrior_player.tscn` and `scripts/player/warrior_player.gd` reference missing `assets/sprites/Warrior/...` paths and should not be used for the next sandbox without a separate asset pass.
- `scenes/player/samurai_women_player.tscn`, `scripts/player/samurai_women_player.gd`, and `assets/animations/samurai_women_idle.tres` reference missing `assets/sprites/Samurai_Women/...` paths and should not be used for the next sandbox without a separate asset pass.

## Risks Before CombatSandbox

- Active knight and mummy sprites are side-direction only. This is acceptable for the next sandbox if mirrored side-facing is enough, but it does not satisfy final 4-direction player goals.
- Knight active sheets use `128x112` frames, larger than the current humanoid target of `64x64` in `docs/ART_PIPELINE.md`. They are accepted as temporary active sprites because they are already integrated and readable.
- Mummy enemy sheets use `64x64` frames and fit the current humanoid target better, but feet baseline and active hit frames still need visual verification in Godot.
- `knight_shield_charge_attack.tres` still depends on a raw sprite sheet. Replace or re-author it later if the shield charge becomes part of the stable paladin kit.
- The current active player attack logic still uses keyboard attacks (`J`, `K`, `L`) and side-facing attack ranges. Mouse-facing combat belongs to later tasks.

## Next Agent Guidance

For TASK-003, build `CombatSandbox.tscn` around:

- `scenes/player/knight_player.tscn`
- `scenes/enemy/mummy_enemy.tscn`
- `assets/sprites/characters/knight/`
- `assets/sprites/enemies/mummy/`

Avoid using inactive Warrior or Samurai player scenes until their resource paths and animation resources are repaired.
