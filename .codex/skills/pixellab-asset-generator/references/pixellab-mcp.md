# PixelLab MCP Compact Reference

这个 reference 只描述 PixelLab MCP tool 用法。项目视觉风格、prompt wording、canvas size、frame rules 和 validation 都使用 `prototype-alpha-pixel-art-style`。

PixelLab MCP tools 是 assistant tools，不是 REST endpoint。Creation tools 会立刻返回 ID；用对应 `get_*` tool 查询进度和结果。

## Common Tools

- `create_character`: humanoid 或 quadruped，4/8 directions，standard/pro mode。
- `animate_character`: template animation by `template_animation_id`，或 custom animation by `action_description`。
- `get_character`: rotations、animations、pending jobs、preview、ZIP download URL。
- `create_object`: static object、candidate pack、或 8-direction rotating object。
- `get_object`: object status、preview、frame/rotation URLs、animations。
- `create_map_object`: transparent map prop，可通过 inpainting style-match background。
- `create_topdown_tileset`: top-down Wang/autotile terrain transitions。
- `create_sidescroller_tileset`: platform terrain tiles。
- `create_isometric_tile`: individual isometric blocks、terrain pieces、items。
- `create_tiles_pro`: multiple tile variations from numbered descriptions。

## Async Checklist

1. Submit creation tool。
2. Save returned UUID。
3. Use matching `get_*` tool until completed、review、or failed。
4. For review objects, keep selected indices with `select_object_frames`。
5. Import completed output into appropriate `assets/` folder。
6. Validate style and Godot readiness with the style/import skills before wiring gameplay。

## Extra MCP Resources

需要更详细 TileMap 实现时，优先查 MCP resources：

- `pixellab://docs/godot/wang-tilesets`
- `pixellab://docs/godot/isometric-tiles`
- `pixellab://docs/godot/sidescroller-tilesets`
- `pixellab://docs/overview`
