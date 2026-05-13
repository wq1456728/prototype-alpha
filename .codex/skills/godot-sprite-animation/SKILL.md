---
name: godot-sprite-animation
description: Use when importing, aligning, slicing, padding, or wiring 2D sprite sheets and Godot AnimatedSprite2D/SpriteFrames resources for this project. Trigger for animation stability, frame sizing, AtlasTexture margin, sprite sheet grids, hit-frame timing, feet alignment, or fixing visual jitter in Godot pixel-art character animations.
---

# Godot Sprite Animation Workflow

## Preferred Asset Shape

Prefer regular sprite sheets when possible:

- consistent frame size
- transparent PNG
- regular grid layout
- stable character position
- feet aligned across frames
- same camera angle and scale

Animation stability matters more than high-detail art in the demo stage.

## Import Strategy

For regular sprite sheets, prefer Godot-native resources:

- Use `SpriteFrames` for `AnimatedSprite2D`.
- Use `AtlasTexture.region` to reference each frame from a sheet.
- Use `AtlasTexture.margin` to add virtual transparent padding when the source frame is smaller than the project frame size.
- Avoid hand-cutting individual PNGs unless alignment or tooling requires it.

When an animation must match existing knight frames, compare against the project's current `96x84` frame convention and feet baseline before wiring it into gameplay.

## Alignment Rules

When a new animation looks offset:

1. Measure the source frame size and existing target frame size.
2. Measure the non-transparent pixel bounds.
3. Align feet/bottom baseline first.
4. Align body center second.
5. Only scale if the character body itself is genuinely a different size.

Do not fix padding problems by changing `AnimatedSprite2D.scale`; that usually causes animation swaps, hitboxes, and gameplay ranges to feel inconsistent.

## Timing Rules

For combat animations:

- Identify the active hit frames visually.
- Place hit detection on those frames, not at the start of the animation.
- If a key pose is too fast, prefer increasing that frame's `duration` or repeating the frame.
- Keep action lock time aligned with total animation time, or movement/idle animations may interrupt the action.

## Godot Runtime Wiring

When adding an animation to an existing runtime-built `SpriteFrames` object:

- Load the `.tres` `SpriteFrames` resource.
- Copy frames into the runtime `SpriteFrames` under the gameplay animation name.
- Preserve source animation speed, loop setting, texture, and per-frame duration.
- Keep the gameplay animation name short and stable, such as `shield_charge`.

## Validation

Before finalizing animation changes:

- Confirm frame count.
- Confirm final displayed frame size.
- Confirm feet baseline matches nearby animations.
- Confirm the hit timing matches visible impact frames.
- Confirm action lock time is not shorter than the animation.
