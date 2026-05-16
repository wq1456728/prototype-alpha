# Art Pipeline

This document freezes the visual direction and asset preparation rules. If older notes conflict with this file, this file wins.

## Visual Target

Prototype Alpha uses:

- 2D dark fantasy ARPG assets.
- Chronicon-like retro 16-bit pixel art.
- Pseudo top-down / slightly angled side-view characters.
- Mostly top-down map readability.
- Crisp pixels and clean silhouettes.
- Limited palette with strong contrast.

Do not use Diablo II-style 45-degree isometric art as the production target. It is too expensive for the current solo-development and AI-assisted pipeline.

## View Decision

The frozen view direction is:

```text
Chronicon-like pseudo top-down.
```

Practical meaning:

- Floors and walkable spaces read mostly top-down.
- Characters show enough front/side body to communicate class, weapon, armor, and enemy identity.
- Props use a top-down footprint with a small readable front face when useful.
- Skill effects prioritize readability over realistic perspective.

Avoid pure top-down for characters because it weakens equipment readability, melee poses, monster identity, and loot-driven power fantasy.

## Asset Source

Primary asset source:

- External AI image generation.

Codex responsibilities:

- Rewrite Chinese asset requests into complete English production prompts.
- Validate generated assets against this pipeline.
- Organize assets into the project.
- Wire accepted assets into Godot resources and scenes.
- Check animation frame counts, baselines, hit frames, and import readiness.

Codex should not assume generated assets are production-ready without validation.

## Global Pixel Rules

All generated or imported gameplay assets should follow:

- Transparent PNG.
- No background.
- No watermark.
- No preview text.
- No reflection.
- No blur.
- No anti-aliasing.
- No soft painterly shading.
- No realistic lighting.
- Clean 1px dark outline where suitable.
- Fully opaque body pixels for characters and enemies.
- No semi-transparent ghost body pixels.

## Character And Enemy Scale

Humanoid player and human-sized enemies:

- Canvas: 64x64 per frame.
- Visible body height: 44-50 px.
- Pivot: bottom center between the feet.
- Feet: aligned near bottom center.
- Body: compact, readable, slightly oversized head acceptable.
- Weapons: exaggerated enough to read in motion.

Large enemies:

- Canvas: 96x96 or 128x128 per frame.
- Feet or contact baseline must remain stable.
- Size must be gameplay-readable and not just visually large.

## Animation Frame Targets

Use consistent frame size within each animation set.

Default humanoid frame counts:

- idle: 4 frames.
- walk: 6 frames.
- attack: 6 frames.
- cast: 6 frames.
- hurt: 2 frames.
- death: 6 frames.

Combat animations must identify the visible active frame. Gameplay hit detection must align with that frame.

## Direction Strategy

The demo can phase direction complexity.

Phase 1:

- Player movement aims for 4 directions: down, up, side, mirrored side.
- Player attack and cast may start with side and down if asset production is constrained.
- Regular enemies may use simplified 2.5-direction animation.
- Projectiles and spell effects can rotate toward mouse aim to carry direction readability.

Phase 2:

- Important player class animations move toward full 4-direction support.
- Boss and signature enemies receive more complete directional animation.
- Key attacks get custom hit poses.

Do not block combat implementation on perfect direction coverage.

## Sprite Sheet Rules

Prefer regular sprite sheets:

- Consistent frame size.
- Transparent background.
- Regular grid layout.
- Stable character scale.
- Feet aligned across frames.
- No camera movement between frames.

For Godot:

- Prefer `SpriteFrames` and `AnimatedSprite2D`.
- Prefer `AtlasTexture.region` for regular sheets.
- Use `AtlasTexture.margin` for virtual transparent padding when needed.
- Do not fix padding or baseline problems by changing `AnimatedSprite2D.scale`.

## Naming Rules

Use clear asset names:

```text
class_paladin_idle_down.png
class_paladin_walk_side.png
class_mage_cast_down.png
enemy_fallen_walk_side.png
boss_crypt_knight_attack_down.png
skill_fireball_projectile.png
item_weapon_sword_rare_icon.png
```

Recommended directories:

```text
assets/raw/
assets/sprites/characters/
assets/sprites/enemies/
assets/sprites/bosses/
assets/sprites/effects/
assets/sprites/items/
assets/animations/
```

Keep raw AI outputs separate from accepted sprites.

## Prompt Template

Use this English structure for AI generation:

```text
Create a [asset type] for Prototype Alpha, a 2D dark fantasy ARPG. [Subject details]. Style: Chronicon-like retro 16-bit pixel art, crisp pixels, clean 1px dark outline, limited palette, high silhouette readability, pseudo top-down / slightly angled side view. Canvas/output: [size and frame layout], transparent PNG, no background, no shadow unless requested, no reflection, no watermark, no preview text. Character constraints: [height, feet baseline, pivot, proportions]. Animation constraints: [frame counts, stable scale, feet aligned, no camera movement]. Avoid: anti-aliasing, blur, soft painterly shading, realistic lighting, thin unreadable details, anime proportions, inconsistent frame sizes, semi-transparent body pixels.
```

## Validation Checklist

Before wiring an asset into gameplay, check:

- Canvas size and frame grid.
- Non-transparent pixel bounds.
- Character height in pixels.
- Feet baseline consistency.
- Horizontal center and bottom-center pivot suitability.
- Frame count per animation.
- Transparent background.
- Fully opaque body pixels.
- Style consistency with dark fantasy 16-bit pixel art.
- Godot `SpriteFrames` readiness.
- Active hit frame for combat animations.

Rejected assets should stay in `assets/raw/` or be replaced. Do not build gameplay around unstable animation alignment.
