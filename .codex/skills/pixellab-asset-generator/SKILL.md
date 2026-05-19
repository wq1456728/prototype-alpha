---
name: pixellab-asset-generator
description: Generate, inspect, animate, and prepare game-ready pixel art assets through the configured PixelLab MCP server. Use when Codex needs to create characters, enemies, props, weapons, icons, skill effects, map objects, top-down/Wang tilesets, sidescroller tilesets, isometric tiles, object variants, or PixelLab animations for this Godot prototype; also use when checking PixelLab job status or downloading/importing generated assets.
---

# PixelLab Asset Generator

## 职责边界

这个 skill 只管 PixelLab MCP 工具流程：

- 选择 PixelLab tool
- 创建 generation job
- 保存 UUID
- 查询 job status
- 处理 review frames
- 获取 PNG/ZIP 输出
- 导入到项目资产目录

它不定义项目美术风格。视觉风格、prompt 文字、canvas 规则、sprite validation 以 `prototype-alpha-pixel-art-style` 为准。

PixelLab MCP creation tools 是异步的：提交 job 后保存返回 UUID，再用对应 `get_*` tool 查询完成状态。

## First Rules

- 使用 PixelLab MCP tools，不要用 REST/curl 访问 `/mcp`。
- 如果 PixelLab tools 不可用，直接告诉用户 MCP 没有加载，不要尝试绕过。
- 生成本项目视觉资产前，搭配 `prototype-alpha-pixel-art-style`。
- 导入、切片、对齐、接入 character sprite sheet 时，搭配 `godot-sprite-animation`。
- 不要把 API token 写入文件、日志或最终回复。
- `delete_object`、`delete_character` 等 destructive PixelLab actions 必须用户明确要求才执行。

## Workflow

1. 判断 asset type：character、animation、object、map object、top-down tileset、sidescroller tileset、isometric tile、tile variations。
2. 通过 `prototype-alpha-pixel-art-style` 得到最终 visual prompt，除非用户已经给了严格 final prompt。
3. 选择最小合适 PixelLab tool。Icon/prop 优先一方向 static object；只有 gameplay 需要旋转时才用 multi-direction。
4. 提交 PixelLab MCP job，并记录返回 UUID。
5. 用户要求查状态、需要导入 Godot、或等待足够时间后，用对应 `get_*` tool poll。
6. 完成后获取 PNG/ZIP URL，并按用途放入现有 asset tree，例如 `assets/raw`、`assets/processed`、`assets/sprites`、`assets/animations`、`assets/vfx`、`assets/ui`。
7. 接入 gameplay 前，用 `prototype-alpha-pixel-art-style` 和必要的 `godot-sprite-animation` 做 style / Godot-readiness validation。

## Tool Selection

- Characters: `create_character`, `get_character`, `animate_character`, `create_character_state`, `list_characters`
- Static props / weapons / pickups / icons / object rotations: `create_object`, `get_object`, `create_object_state`, `animate_object`, `list_objects`
- In-map decorations: `create_map_object`, `get_map_object`
- Top-down terrain transitions: `create_topdown_tileset`, `get_topdown_tileset`, `list_topdown_tilesets`
- Sidescroller platform terrain: `create_sidescroller_tileset`, `get_sidescroller_tileset`
- Isometric blocks/items: `create_isometric_tile`, `get_isometric_tile`
- Multiple shaped tile variations: `create_tiles_pro`, `get_tiles_pro`

更细的参数提示见 `references/pixellab-mcp.md`。

## PixelLab Job Handling

- Creation tools 立即返回；不要假设 asset 已完成。
- 只有对应 `get_*` result 显示 completed 并提供 image/download URL 时，才算完成。
- Character 创建后，如果已有 character ID，可以继续 queue template animation。
- Custom character animation 没有 `template_animation_id` 时，第一次不要设置 `confirm_cost=true`。先查看 generation cost，告诉用户成本和更便宜的 template animation 选项，用户明确同意后才能确认。
- `create_object` 使用 `directions=1` 且 `n_frames > 1` 时，可能进入 review status。用 `get_object` 查看 candidates，再用 `select_object_frames` 保留，或 `dismiss_review` 放弃。
- Download URL 使用 UUID 作为 access key。可以用于下载，但不要把不必要的链接写进代码或文档。

## Godot Import Guidance

- 原始输出和 processed Godot-ready 文件分开。
- 使用现有目录，不要无理由创建新 asset hierarchy。
- Pixel style、canvas size、frame grid、pivot rules 交给 `prototype-alpha-pixel-art-style`。
- Terrain seamless TileMap transition 优先考虑 PixelLab Wang/top-down tilesets。
- 接入 scene/script 前，先确认项目已有命名和 loader/resource 约定。

## Status Response Pattern

报告 PixelLab generation 结果时包含：

- Asset type 和 prompt summary。
- PixelLab UUID。
- Current status：queued、processing、review、completed、failed。
- Next action：wait/check later、select review frames、download/import、revise prompt。
