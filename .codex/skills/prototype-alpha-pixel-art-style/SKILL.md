---
name: prototype-alpha-pixel-art-style
description: Project art-direction rules for prototype-alpha 2D dark fantasy ARPG pixel assets. Use when Codex needs to rewrite prompts for character, enemy, skill effect, item, icon, or sprite-sheet generation; validate externally generated or downloaded assets; align animation frame specs; or prepare Godot-ready pixel art assets for this project.
---

# prototype-alpha Pixel Art Style

## Overview

Use this skill to keep prototype-alpha 2D dark fantasy ARPG pixel assets visually consistent. Codex does not have to generate the final image asset; use this skill to rewrite prompts, validate outputs, and prepare assets for Godot.

## Core Workflow

1. Rewrite the user's asset request into a complete English production prompt before generating or editing any asset.
2. Apply the global style rules and the relevant asset-specific rules below.
3. If the asset already exists, validate it against canvas size, visible bounds, feet baseline, frame count, transparency, and style consistency before wiring it into Godot.
4. When preparing sprite sheets for Godot, prioritize stable frame size and feet alignment over detail.

## Global Style Rules

Use these rules for all generated, edited, downloaded, or imported assets unless the user explicitly overrides them:

- 2D dark fantasy ARPG asset for prototype-alpha.
- Chronicon-like retro 16-bit pixel art.
- Pseudo top-down / slightly angled side view.
- Crisp pixels, no anti-aliasing, no blur, no soft painterly shading, no realistic lighting.
- Clean 1px dark outline.
- Limited palette with high silhouette readability.
- Transparent PNG output.
- No background, reflection, watermark, preview text, semi-transparent overlay, or ghost transparency on the character body.

## Humanoid Character Rules

- Use a 64x64 canvas.
- Keep actual character height between 44 and 50 px.
- Center the sprite horizontally.
- Align feet near bottom center.
- Treat the pivot as the bottom center between the feet.
- Use a compact body, slightly oversized head, readable armor shapes, and exaggerated weapon size when applicable.
- Avoid thin unreadable details, realistic long legs, anime full-body illustration proportions, or inconsistent character scale.

## Animation Rules

Use the same canvas size for every frame in an animation set. Keep feet aligned, keep the character scale stable, and avoid camera movement.

- idle: 4 frames
- walk: 6 frames
- attack: 6 frames
- hurt: 2 frames
- death: 6 frames

For combat animations, identify the visible active hit frame and align gameplay hit detection to that frame instead of triggering damage at animation start.

## Prompt Rewrite Rule

Before generating or editing any image asset, rewrite the request into a full production prompt. Output the rewritten prompt first, then proceed with the requested generation, editing, or validation task.

Prompt structure:

```text
Create a [asset type] for prototype-alpha, a 2D dark fantasy ARPG. [Subject details]. Style: Chronicon-like retro 16-bit pixel art, crisp pixels, clean 1px dark outline, limited palette, high silhouette readability, pseudo top-down / slightly angled side view. Canvas/output: [size and frame layout], transparent PNG, no background, no shadow unless requested, no reflection, no watermark, no preview text. Character constraints: [height, feet baseline, pivot, proportions]. Animation constraints: [frame counts, stable scale, feet aligned, no camera movement]. Avoid: anti-aliasing, blur, soft painterly shading, realistic lighting, thin unreadable details, anime proportions, inconsistent frame sizes, semi-transparent body pixels.
```

If the user writes in Chinese, keep the production prompt in English for image-model reliability and optionally add a short Chinese explanation after it.

## Asset Validation Checklist

When reviewing an existing asset, report pass/fail for:

- Canvas size and frame grid.
- Non-transparent pixel bounds.
- Character height in pixels.
- Feet baseline consistency across frames.
- Horizontal center and bottom-center pivot suitability.
- Frame count for each animation.
- Transparent background with fully opaque body pixels.
- Style consistency with dark fantasy ARPG 16-bit pixel art.
- Godot import readiness for `SpriteFrames` / `AnimatedSprite2D`.

## Godot Preparation Guidance

Prefer regular sprite sheets:

- Consistent frame size.
- Transparent PNG.
- Regular grid layout.
- Stable character position.
- Feet aligned across frames.
- Same camera angle and scale.

Do not fix padding or baseline problems by changing `AnimatedSprite2D.scale`. Use frame padding, atlas margins, or corrected source sheets so gameplay hitboxes and animation swaps stay consistent.
