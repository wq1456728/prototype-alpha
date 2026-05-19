---
name: godot-sprite-animation
description: Use when importing, aligning, slicing, padding, or wiring 2D sprite sheets and Godot AnimatedSprite2D/SpriteFrames resources for this project. Trigger for animation stability, frame sizing, AtlasTexture margin, sprite sheet grids, hit-frame timing, feet alignment, or fixing visual jitter in Godot pixel-art character animations.
---

# Godot Sprite Animation Workflow

## 职责边界

这个 skill 只管 Godot 里的 sprite animation 接入和稳定性：

- slicing
- padding
- `SpriteFrames`
- `AnimatedSprite2D`
- `AtlasTexture.region`
- `AtlasTexture.margin`
- feet baseline
- hit-frame timing
- visual jitter

它不负责定义项目美术风格。风格、prompt、canvas 目标、透明背景、像素规则以 `prototype-alpha-pixel-art-style` 和 `docs/ART_PIPELINE.md` 为准。

## Preferred Asset Shape

接入 Godot 时，优先使用 regular sprite sheet：

- consistent frame size
- transparent PNG
- regular grid layout
- stable character position
- feet aligned across frames
- same camera angle and scale

Demo 阶段 animation stability 比高细节更重要。

## Import Strategy

For regular sprite sheets:

- 使用 `SpriteFrames` 给 `AnimatedSprite2D`。
- 使用 `AtlasTexture.region` 从 sheet 引用每帧。
- 当源帧小于项目目标帧时，使用 `AtlasTexture.margin` 添加虚拟透明 padding。
- 不要手切一堆单独 PNG，除非 alignment 或工具链确实需要。

如果动画必须匹配现有 knight frames，先比较当前项目使用的 `96x84` frame convention 和 feet baseline，再接入 gameplay。

## Alignment Rules

当新动画看起来偏移：

1. 测量 source frame size 和 existing target frame size。
2. 测量 non-transparent pixel bounds。
3. 先对齐 feet/bottom baseline。
4. 再对齐 body center。
5. 只有角色身体本身尺寸真的不同，才考虑 scale。

不要通过改 `AnimatedSprite2D.scale` 修 padding 问题。这样通常会让 animation swap、hitbox 和 gameplay range 变得不一致。

## Timing Rules

Combat animations:

- 视觉上找 active hit frames。
- damage / hitbox / projectile spawn 放在那些帧，而不是 animation start。
- key pose 太快时，优先增加该帧 `duration` 或重复帧。
- action lock time 不能短于可见动作，否则 movement/idle 可能打断攻击。

## Runtime Wiring

给 runtime-built `SpriteFrames` 加动画时：

- Load `.tres` `SpriteFrames` resource。
- Copy frames into runtime `SpriteFrames` under gameplay animation name。
- Preserve source animation speed、loop setting、texture、per-frame duration。
- Gameplay animation name 保持短且稳定，例如 `shield_charge`。

## Validation

完成前检查：

- frame count
- final displayed frame size
- feet baseline 与附近动画一致
- hit timing 匹配 visible impact frames
- action lock time 不短于 animation
