# Asset Prompt Template

## 通用要求

```text
for Prototype Alpha, a 2D dark fantasy ARPG.

Chronicon-like retro 16-bit pixel art.
Pseudo top-down / slightly angled side view.
Crisp pixels.
Clean 1px dark outline.
Limited palette.
High silhouette readability.
Dark fantasy mood.
Readable gameplay silhouette.

Mostly top-down map readability,
but characters and enemies should show enough front/side body shape
to communicate class, weapon, armor, and monster identity.

Transparent PNG.
No background.
No reflection.
No watermark.
No preview text.
No UI frame unless requested.
No soft shadow unless requested.

Stable scale.
Stable camera angle.
Centered subject.
Clean silhouette.
Gameplay-readable shapes.

Avoid anti-aliasing.
Avoid blur.
Avoid soft painterly shading.
Avoid realistic lighting.
Avoid realistic anatomy.
Avoid anime proportions.
Avoid realistic long legs.
Avoid thin unreadable details.
Avoid noisy texture.
Avoid inconsistent scale.
Avoid inconsistent camera angle.
Avoid strong 45-degree isometric perspective.
Avoid semi-transparent body pixels.
Avoid ghost transparency.
Avoid background scenery.
Avoid cropped body parts.
```

## 角色 / 敌人 Sprite Sheet

```text
Create a [CHARACTER OR ENEMY] sprite sheet for Prototype Alpha, a 2D dark fantasy ARPG.

Subject: [SUBJECT].
Action/animation: [ACTION].
Direction: [DIRECTION].

Style:
Chronicon-like retro 16-bit pixel art.
Pseudo top-down / slightly angled side view.
Crisp pixels.
Clean 1px dark outline.
Limited palette.
High silhouette readability.
Dark fantasy mood.
Readable gameplay silhouette.

Mostly top-down map readability,
but the character should show enough front/side body shape
to communicate class, weapon, armor, and identity.

Canvas/output:
[64x64 pixels per frame for humanoids / 96x96 or 128x128 pixels per frame for large enemies].
[FRAME_LAYOUT].
Transparent PNG.
No background.
No reflection.
No watermark.
No preview text.
No UI frame.
No soft shadow.

Character constraints:
Actual humanoid character height 44-50 pixels on a 64x64 frame.
Centered horizontally.
Feet aligned near bottom center.
Bottom-center pivot between the feet.
Compact body.
Slightly oversized readable head.
Readable armor and weapon shapes.
Exaggerated weapon size when useful.

Animation constraints:
Stable scale.
Stable feet baseline.
No camera movement.
Same frame size for every frame.
Active combat pose clearly readable.

Avoid anti-aliasing.
Avoid blur.
Avoid soft painterly shading.
Avoid realistic lighting.
Avoid realistic anatomy.
Avoid anime proportions.
Avoid realistic long legs.
Avoid thin unreadable details.
Avoid noisy texture.
Avoid inconsistent frame sizes.
Avoid inconsistent character scale.
Avoid inconsistent camera angle.
Avoid strong 45-degree isometric perspective.
Avoid semi-transparent body pixels.
Avoid ghost transparency.
Avoid background scenery.
Avoid cropped body parts.
```

## 单个素材 / 图标 / 特效

```text
Create a [SINGLE ASSET TYPE] for Prototype Alpha, a 2D dark fantasy ARPG.

Subject: [SUBJECT].
Purpose: [PURPOSE].

Style:
Chronicon-like retro 16-bit pixel art.
Pseudo top-down / slightly angled side view when applicable.
Crisp pixels.
Clean 1px dark outline where suitable.
Limited palette.
High silhouette readability.
Dark fantasy mood.
Readable gameplay silhouette.

Canvas/output:
[SIZE].
Transparent PNG.
No background.
No reflection.
No watermark.
No preview text.
No UI frame unless requested.
No soft shadow unless requested.

Asset constraints:
Centered subject.
Clear readable shape.
Strong contrast against dark ground.
Consistent scale with 64x64 humanoid characters.
Suitable for Godot 2D gameplay.

Avoid anti-aliasing.
Avoid blur.
Avoid soft painterly shading.
Avoid realistic lighting.
Avoid realistic rendering.
Avoid anime proportions.
Avoid thin unreadable details.
Avoid noisy texture.
Avoid inconsistent scale.
Avoid inconsistent camera angle.
Avoid strong 45-degree isometric perspective.
Avoid huge soft gradients.
Avoid semi-transparent body pixels.
Avoid ghost transparency.
Avoid background scenery.
Avoid cropped asset.
Avoid text.
```
