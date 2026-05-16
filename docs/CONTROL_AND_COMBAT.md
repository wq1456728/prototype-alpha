# Control And Combat Rules

This document freezes player control, facing, and combat feel rules. If older notes conflict with this file, this file wins.

## Control Model

The demo uses:

- WASD movement.
- Mouse aim for attacks and skills.
- Mouse click or keyboard skill buttons for skill activation.
- Windows as the first target platform.

The intended feel is Diablo II-like loot pacing with Chronicon-like control clarity.

## Facing Rules

The character does not always face the mouse.

Frozen facing behavior:

- While not attacking or casting, the character faces the latest valid movement direction.
- While attacking or casting, the character faces the mouse aim direction.
- After attack or cast recovery, if movement is active, facing returns to movement direction.
- If movement is inactive after an attack or cast, the character keeps the last attack or cast direction.
- Dash without an attack faces and travels along movement direction.
- Dash attack or blink skill may face and travel toward mouse aim direction.

Recommended runtime variables:

```text
move_direction
aim_direction
facing_direction
action_direction
```

Use `move_direction` for locomotion, `aim_direction` for target selection, and `facing_direction` for animation. Do not let mouse aim permanently override movement-facing.

## Combat Pace

Combat should be slower and more deliberate than a high-speed action roguelite.

Prefer:

- Readable enemy approach.
- Clear attack startup.
- Hit frames aligned with animation.
- Short but noticeable recovery windows.
- Meaningful pressure from enemy positioning.
- Power jumps from skills and equipment.

Avoid:

- Constant screen-wide ability spam in the first demo.
- Excessively fast movement that erases positioning.
- Enemies that die before feedback can be read.
- Long crowd-control chains that remove player agency.

## Player Combat Foundation

Every class prototype needs:

- Basic attack.
- One mobility skill.
- One single-target or focused damage skill.
- One area or control skill.
- Hurt state.
- Death state.
- Hit feedback when damaging enemies.

For the first playable combat sandbox, implement these before adding more content:

- Damage application.
- Hitbox and hurtbox timing.
- One-hit-per-swing prevention.
- Enemy health and death.
- Knockback or hit push.
- Flash or tint feedback.
- Hit stop or brief impact pause.
- Damage numbers.
- Drop spawn on death.

## Hit Timing

Combat damage must be tied to visible active frames, not animation start.

Rules:

- Identify the visible hit frame for each attack or cast animation.
- Enable hitbox or projectile spawn on that frame.
- Keep action lock duration at least as long as the visible action.
- If a key pose is unreadable, extend that frame duration or repeat the frame.
- Do not let idle or walk animations interrupt active attacks.

## Class Combat Direction

### Paladin-Style Melee

Baseline combat:

- Short-range weapon arc.
- Slight movement slowdown or lock during attack.
- Dash strike or direct dash as mobility.
- Area shock, slam, or holy burst as first area skill.

Feel target:

- Durable and grounded.
- Hits should feel heavy.
- Enemy contact is risky but manageable.

### Mage-Style Ranged

Baseline combat:

- Basic magic projectile.
- Fireball-style aimed spell.
- Frost nova, lightning chain, or circular control spell.
- Blink-style mobility, sharing base mobility logic with dash.

Feel target:

- Safer at range but punished when surrounded.
- Spells should visibly scale through damage, radius, or cooldown.
- Projectiles and spell effects carry most directional readability.

## Enemy Combat Minimum

The first demo needs:

- Melee chaser.
- Ranged or caster enemy.
- Elite variant with higher pressure.
- Small boss with 2-3 readable attacks.

Enemy rules:

- Enemies must telegraph dangerous attacks.
- Regular enemies should die fast enough to support loot flow.
- Elites should force movement or skill use.
- Boss should test whether the player gained enough power.

## Feedback Rules

Minimum combat feedback:

- Enemy flash or tint on hit.
- Damage number.
- Sound for attack, hit, pickup, and death.
- Knockback or stagger on meaningful hits.
- Drop visibility through color, outline, or glow.
- Boss health bar.

Optional but useful:

- Light screen shake for heavy hits.
- Brief hit stop.
- Skill impact particles.
- Low-health player warning.

## Tuning Checks

Run these checks after combat changes:

- Can the player understand movement and attack in 30 seconds?
- Does the attack hit when the animation visually says it hits?
- Can the player kite, reposition, or recover from pressure?
- Does one equipment upgrade noticeably change time-to-kill?
- Does mobility solve danger without making positioning irrelevant?
- Does the boss punish underpowered play without feeling unfair?
