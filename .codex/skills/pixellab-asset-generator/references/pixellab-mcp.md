# PixelLab MCP Compact Reference

PixelLab MCP tools are callable assistant tools, not REST endpoints. Creation tools are non-blocking and return IDs immediately; use the matching `get_*` tool to inspect progress and retrieve outputs.

## Common Tools

- `create_character`: humanoid or quadruped, 4 or 8 directions, standard or pro mode.
- `animate_character`: template animation by `template_animation_id`, or custom animation by `action_description`.
- `get_character`: rotations, animations, pending jobs, preview, ZIP download URL.
- `create_object`: static object, candidate pack, or 8-direction rotating object.
- `get_object`: object status, preview, frame/rotation URLs, animations.
- `create_map_object`: transparent map prop; can style-match a background image through inpainting.
- `create_topdown_tileset`: Wang/autotile terrain transitions for top-down maps.
- `create_sidescroller_tileset`: platformer terrain tiles with decorative top layer.
- `create_isometric_tile`: individual isometric blocks, terrain pieces, or items.
- `create_tiles_pro`: multiple tile variations from numbered descriptions.

## Project Defaults

- View: prefer `low top-down` for ARPG characters, enemies, props, and combat VFX unless the request is UI/icon-only.
- Outline: prefer `single color black outline` or `single color outline`.
- Shading: prefer `basic shading` or `medium shading`; avoid painterly/realistic lighting.
- Detail: prefer `medium detail` for gameplay readability.
- Character directions: use 4 directions for demo-scope movement unless the asset clearly needs diagonal views.
- Character size: start at 64px canvas for humanoid player/enemy sprites; ensure actual visible body remains compact.
- Object size: use 32px for small pickups/icons, 64px for readable gameplay props.
- Top-down tiles: use 16x16 or 32x32 according to the existing TileMap convention.

## Prompt Shape

Use English prompts. Include:

```text
Create a [asset type] for prototype-alpha, a 2D dark fantasy ARPG. [Subject details]. Style: Chronicon-like retro 16-bit pixel art, crisp pixels, clean 1px dark outline, limited palette, high silhouette readability, pseudo top-down / slightly angled side view. Output: transparent PNG, no background, no reflection, no watermark, no preview text. Avoid anti-aliasing, blur, soft painterly shading, realistic lighting, and thin unreadable details.
```

## Async Checklist

1. Submit creation tool.
2. Save the returned UUID.
3. Use the matching `get_*` tool until completed, review, or failed.
4. For review objects, keep selected indices with `select_object_frames`.
5. Import completed output into the appropriate `assets/` folder and validate Godot readiness.

## Extra MCP Resources

When detailed TileMap implementation is needed, inspect MCP resources if available:

- `pixellab://docs/godot/wang-tilesets`
- `pixellab://docs/godot/isometric-tiles`
- `pixellab://docs/godot/sidescroller-tilesets`
- `pixellab://docs/overview`
