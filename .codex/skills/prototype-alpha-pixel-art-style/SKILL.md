---
name: prototype-alpha-pixel-art-style
description: Project art-direction rules for prototype-alpha 2D dark fantasy ARPG pixel assets. Use when Codex needs to rewrite prompts for character, enemy, skill effect, item, icon, or sprite-sheet generation; validate externally generated or downloaded assets; align animation frame specs; or prepare Godot-ready pixel art assets for this project.
---

# Prototype Alpha Pixel Art Style

## 职责边界

这个 skill 是项目像素美术风格的 operational source of truth。它负责：

- 重写素材 prompt
- 约束 visual style
- 检查 canvas / frame / transparency / silhouette
- 给 Godot-ready asset 做基础规格验证

它不负责提交 PixelLab job、poll UUID、select review frames、download output。那些操作使用 `pixellab-asset-generator`。

更完整的美术方向见 `docs/ART_PIPELINE.md`；如果两者冲突，以 `docs/ART_PIPELINE.md` 为准。

## Core Workflow

1. 把用户的素材需求改写成完整 English production prompt。
2. 应用下面的 global style rules 和对应 asset-specific rules。
3. 如果 asset 已存在，先验证 canvas size、visible bounds、feet baseline、frame count、transparency、style consistency，再接入 Godot。
4. 准备 sprite sheet 时，stable frame size 和 feet alignment 优先于细节。

## Global Style Rules

除非用户明确覆盖，所有 generated、edited、downloaded、imported assets 都遵守：

- 2D dark fantasy ARPG asset for Prototype Alpha。
- Chronicon-like retro 16-bit pixel art。
- Pseudo top-down / slightly angled side view。
- Crisp pixels。
- No anti-aliasing、no blur、no soft painterly shading、no realistic lighting。
- Clean 1px dark outline。
- Limited palette with high silhouette readability。
- Transparent PNG output。
- No background、reflection、watermark、preview text。
- Character body pixels should be fully opaque；no semi-transparent ghost body pixels。

## Humanoid Character Rules

- Canvas: 64x64 per frame。
- Actual visible character height: 44-50 px。
- Center horizontally。
- Feet aligned near bottom center。
- Pivot: bottom center between the feet。
- Compact body。
- Slightly oversized readable head is acceptable。
- Armor and weapon shapes must be readable in motion。
- Avoid thin unreadable details、realistic long legs、anime full-body proportions、inconsistent scale。

## Animation Rules

同一 animation set 必须保持相同 frame size、stable scale、feet aligned、no camera movement。

Default humanoid frame counts:

- idle: 4 frames
- walk: 6 frames
- attack: 6 frames
- hurt: 2 frames
- death: 6 frames

Combat animations 必须识别 visible active hit frame。Gameplay hit detection 应该对齐该帧，而不是 animation start。

## Prompt Rewrite Rule

生成或编辑任何图像 asset 前，先输出完整 English production prompt。

Prompt structure:

```text
Create a [asset type] for Prototype Alpha, a 2D dark fantasy ARPG. [Subject details]. Style: Chronicon-like retro 16-bit pixel art, crisp pixels, clean 1px dark outline, limited palette, high silhouette readability, pseudo top-down / slightly angled side view. Canvas/output: [size and frame layout], transparent PNG, no background, no shadow unless requested, no reflection, no watermark, no preview text. Character constraints: [height, feet baseline, pivot, proportions]. Animation constraints: [frame counts, stable scale, feet aligned, no camera movement]. Avoid: anti-aliasing, blur, soft painterly shading, realistic lighting, thin unreadable details, anime proportions, inconsistent frame sizes, semi-transparent body pixels.
```

如果用户中文描述素材，production prompt 仍然用英文；可以在 prompt 后附一句中文解释。

## Asset Validation Checklist

Review existing asset 时，报告 pass/fail：

- Canvas size and frame grid。
- Non-transparent pixel bounds。
- Character height in pixels。
- Feet baseline consistency across frames。
- Horizontal center and bottom-center pivot suitability。
- Frame count for each animation。
- Transparent background。
- Fully opaque body pixels。
- Style consistency with dark fantasy ARPG 16-bit pixel art。
- Godot import readiness for `SpriteFrames` / `AnimatedSprite2D`。

## Godot Preparation Boundary

本 skill 可以判断资产是否适合 Godot，但不负责具体 `SpriteFrames` wiring。

需要导入、切片、padding、baseline 修复、`AtlasTexture.margin`、hit-frame timing 时，使用 `godot-sprite-animation`。
