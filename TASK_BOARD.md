# 任务板

这个文件是其他对话或 agent 的任务入口。它只保留当前任务、最近上下文和后续顺序；历史任务、通用规则和长期计划放在独立文档里。

## 必读入口

当前规划、范围和实现规则以这些文件为准：

- [README.md](README.md)
- [docs/PROJECT_PLAN.md](docs/PROJECT_PLAN.md)
- [docs/DEMO_SCOPE.md](docs/DEMO_SCOPE.md)
- [docs/CONTROL_AND_COMBAT.md](docs/CONTROL_AND_COMBAT.md)
- [docs/ART_PIPELINE.md](docs/ART_PIPELINE.md)
- [docs/WORLD_STRUCTURE.md](docs/WORLD_STRUCTURE.md)
- [docs/MAP_OBJECT_AND_BOUNDARY_SPEC.md](docs/MAP_OBJECT_AND_BOUNDARY_SPEC.md)
- [docs/OUTDOOR_TERRAIN_ASSET_LIST.md](docs/OUTDOOR_TERRAIN_ASSET_LIST.md)
- [docs/AGENT_RULES.md](docs/AGENT_RULES.md)
- [docs/TASK_ARCHIVE.md](docs/TASK_ARCHIVE.md)
- [ASSET_PROMPT_TEMPLATE.md](ASSET_PROMPT_TEMPLATE.md)

如果旧笔记和上面文件冲突，以上面文件为准。

## 当前阶段

`combat_sandbox` 的纵向系统链路已经跑通：combat、loot、inventory/equipment、XP/level、skill unlock、Hotbar assignment、objective completion 都已有第一版。

`TASK-023` 到 `TASK-031` 已归档。当前已经有：

- seed 可复现的 semi-procedural map core。
- persistent `MainWorld`，包含固定 `FixedTown` 和同世界坐标下的 `GeneratedRegion`。
- P0 terrain vocabulary 和 Camp support assets。
- Camp visual assembly 第一版。
- Asset footprint draft / collision preview tool。

用户人工复审认为到 `TASK-030` 前后的主结构基本可接受。当前主要问题转到地表表现和世界边缘整合：

- 地面不是技术 seam 问题，而是 tile / layer 太规整、重复度高、像色块铺出来。
- Town gate 到 wilderness start 之间有空缺 / 缺少固定过渡区。
- Walkable 外侧和未铺地表区域暴露黑色 void。
- Road 应该是视觉引导，不应该等于整条逻辑 corridor。
- `TASK-032` 旧实现已被用户复审否定：路面仍然像方块拼接，Town / GeneratedRegion 衔接处仍有大块黑区，现有 ground tile 质量不合格。

完整历史见 [docs/TASK_ARCHIVE.md](docs/TASK_ARCHIVE.md)。

## 当前设计结论

第一张 outdoor 不采用传统 scene switching。它是 `MainWorld` 同一坐标系下的 `GeneratedRegion`，从 `FixedTown` 出口附近开始生成。玩家离开基地后，回头仍然能看到基地。

后续以 [docs/WORLD_STRUCTURE.md](docs/WORLD_STRUCTURE.md) 为准：不要使用 `Town.tscn -> Wilderness.tscn` 的主流程，不 teleport 玩家到另一张地图；使用 persistent world scene、fixed town、anchor / socket based wilderness expansion。

Terrain 表现采用分层思想。第一版明确不要做完整 `TileMap` / terrain autotile 系统，也不要重写 generator；先用 `Node2D + Sprite2D` 的 tiled / decal scatter 把视觉层拆出来。后续如果确实需要，再切换到 `TileMap` / terrain autotile。

`GeneratedRegion` 下应保留稳定的 terrain visual root。优先使用 `FirstOutdoorVisuals` 作为根节点或兼容 adapter，下面至少有这些可被 smoke test 检查的 layer：

```text
GroundBaseLayer        no collision
TerrainOverlayLayer    no collision
RoadLayer              no collision
DecalLayer             no collision
OuterBufferLayer       no collision
DecorativePropLayer    no collision by default
GameplayPropLayer      collision optional by object definition
BoundaryLayer          collision required
InteractionLayer       interaction area, collision optional
```

重要规则：

```text
walkable area != visual road
logic corridor can be wide
visual road should be narrower, irregular, and readable
```

## 当前任务

### TASK-032: Dual Grid Wang16 Terrain Prototype Redo

Status: done / algorithm prototype ready

Latest override:

本任务重新改写。不要继续沿用 FrameRonin / Tile47 prototype 作为当前执行方向，也不要直接改 `MainWorld`。当前唯一目标是：使用项目内这张 4x4 Wang16 图，参考 dual-grid tilemap system 的算法结构，用 GDScript 复写一份最小可控实现，并重新做独立 prototype 地图。

Required asset:

```text
res://assets/sprites/terrain/pixellab_dark_arpg_wang/tileset_dark_grass_dirt_wang16_32.png
```

Current execution note:

用户最新指令是先不继续生成 / 下载素材，先重写算法。当前实现因此保留最终素材路径作为 preferred atlas；如果该 PNG 尚不存在，会自动回退到 debug placeholder atlas，只用于验证 dual-grid Wang16 算法结构。

Known asset facts:

```text
image size: 128x128
tile size: 32x32
atlas: 4 columns x 4 rows
tile count: 16
intended use: dual-grid / Wang16 grass-dirt transition candidate
```

Algorithm reference:

```text
https://github.com/jess-hammer/dual-grid-tilemap-system-godot
```

Use the repository as algorithm reference only:

- It is a Godot Mono / C# demo, not something to import directly.
- Do not introduce C# / Mono to this project.
- Reimplement the minimal algorithm in GDScript.
- The useful structure to copy is `world/logical terrain layer -> display layer` and `4-corner mask -> atlas tile` mapping.

New prototype target:

```text
scenes/dev/terrain_dual_grid_wang_test.tscn
scripts/terrain/dual_grid_terrain_painter.gd
tools/smoke_task32_dual_grid_wang_test.gd
artifacts/task32_dual_grid_wang_preview.png
```

Required scene structure:

```text
TerrainDualGridWangTest
  GroundDisplayTileMapLayer
  DecalPreviewLayer
  DebugOverlayLayer optional
  Camera2D
```

Required GDScript implementation:

```text
DualGridTerrainPainter
  terrain_grid: stores logical terrain points, at least grass / dirt
  set_terrain_point(cell, terrain)
  paint_dirt_rect(rect)
  paint_dirt_path(points, radius)
  rebuild()
  _get_corner_mask(x, y) -> int
  _mask_to_atlas_coords(mask) -> Vector2i
```

Dual-grid rule:

```text
Each rendered tile samples 4 logical terrain points:

A B
C D

If a point is dirt, set its bit.
The 4-bit mask selects one of the 16 tiles in the 4x4 atlas.
```

The exact bit order must be documented in code comments and in the task report, for example:

```text
bit 0 = top-left
bit 1 = top-right
bit 2 = bottom-left
bit 3 = bottom-right
```

Important: do not assume the atlas is in the correct binary order. The task agent must create and tune a `mask_to_atlas_coords` table by visual inspection / test pattern. If the first mapping is wrong, fix the mapping table, not the terrain algorithm.

Prototype map requirements:

- Fill the whole visible area with grass via the dual-grid display layer.
- Paint at least one irregular dirt patch.
- Paint one curved dirt road using logical terrain points and `paint_dirt_path()`; do not draw the road with old square road sprites.
- The road / patch edges must come from Wang16 mask transitions.
- Add a small `DecalPreviewLayer` with non-collision decorative marks if available, but decals are optional. The core proof is the Wang16 transition.
- Do not add gameplay collisions.
- Do not change `MainWorld`, `FixedTown`, `GeneratedRegion`, combat, quest, inventory, loot, or old map generator.

Acceptance for this redo:

- Prototype scene opens independently.
- Smoke verifies required scene nodes exist.
- Smoke verifies the atlas texture path is exactly `res://assets/sprites/terrain/pixellab_dark_arpg_wang/tileset_dark_grass_dirt_wang16_32.png`.
- Smoke verifies 16 mask mappings exist.
- Smoke verifies the displayed tilemap has non-empty cells.
- Smoke verifies at least one dirt patch and one curved path were painted into the logical terrain grid.
- Completion report includes `mask_to_atlas_coords` table and preview artifact path.
- User visual review decides whether this Wang16 asset and dual-grid approach are acceptable.

禁止项:

- 不使用 FrameRonin 的 24x24 atlas 继续推进本任务。
- 不引入 Godot Mono / C#。
- 不直接集成到 `MainWorld`。
- 不继续使用旧失败方块路。
- 不把这张 Wang16 图当最终美术；它先用于验证技术方案。
- 不把 smoke 当作视觉验收，视觉仍由用户审核。

Redo decision:

当前 `TASK-032` 旧实现不通过验收，不能在旧 road / ground tile 上继续补丁式微调。本任务需要重做 ground / road / transition 的视觉基础：

- `GroundBaseLayer` 要重构，覆盖整个正常可见区域，包括 FixedTown、Town exit、GeneratedRegion、transition apron 和外侧 buffer。
- 原来不合格的 ground / road tile 视觉应从当前 paint 结果中移除，不再作为主地表使用。
- 需要重新寻找免费可用素材，或重新生成连续地表素材；素材必须两块相邻时看起来连续，而不是一眼能看出 tile 方块边界。
- 草地、dead grass、dirt base 至少要有能稳定铺开的 base vocabulary。
- Road 方案需要重新设计，不能继续使用明显方块化的 road tile 串。
- Town 和 wilderness 的连接处不能露黑，必须由 base ground、transition apron、road/decal overlay 和 outer buffer 共同覆盖。

Reference:

- Godot TileMap / TileSet tutorial reference supplied by user: https://www.bilibili.com/video/BV18e411R7sV/?spm_id_from=333.337.search-card.all.click&vd_source=cfd06268afcefbc9b5cd601770ae189a
- Task agent should watch / inspect this tutorial if possible, but implementation must still follow the written contract below. Do not rely on undocumented video memory in the completion report.

Execution strategy:

不要直接在 `MainWorld` 上重做地表。先做一个小型独立 prototype 验证 TileMap terrain 工作流，确认 grass / dirt / transition / road 能做出连续自然的效果，再把方案迁移回主地图。

Prototype scene:

```text
scenes/dev/terrain_tilemap_test.tscn
```

Prototype required nodes:

```text
TerrainTilemapTest
  GroundBaseTileMapLayer
  DirtRoadTileMapLayer
  TerrainOverlayTileMapLayer
  DecalPreviewLayer
  PropPreviewLayer
```

Prototype must prove:

- 能铺满连续 grass base，不露黑底。
- 能画一块 dirt / trampled area。
- grass 和 dirt 之间有 transition，不是硬边矩形。
- 能画一条弯曲、不规则、窄于 logic corridor 的 dirt road。
- road 不是一串明显方块 tile。
- 能叠少量 grass / dirt / pebble / stain decal 打散重复。
- 不改 `MainWorld`，不接 combat，不接 quest，不接 generator。

Prototype acceptance:

- 用户肉眼看 screenshot / 运行场景后认为地表方向可以继续。
- 如果 prototype 仍然像方块拼接，则停止迁移，先换 tileset / 素材。
- Prototype 通过后，才进入 `MainWorld` integration，把 `GeneratedRegion/FirstOutdoorVisuals` 的 ground base 改成相同方案。

Tile47 / autotile asset requirement:

本任务需要素材 agent 配合提供一套 outdoor grass / dirt 的 `Tile47`、blob autotile、RPG Maker autotile 或 Godot terrain compatible tileset。不要只提供单张 grass tile / dirt tile；这类素材无法解决当前方块感。

素材 agent 优先级：

```text
1. 先去网上找免费可用素材。
2. 优先选择允许 commercial use 或至少 prototype use 的资源。
3. 必须记录 source URL 和 license。
4. 找不到合适素材时，再使用 PixelLab / AI 像素网站生成。
5. 生成素材必须做拼接验证，不允许只交原图。
```

搜索关键词建议：

```text
free pixel art grass dirt 47 tileset
free RPG maker grass dirt autotile
Godot grass dirt terrain tileset
pixel art outdoor autotile 47
top-down grass dirt path tileset
blob autotile grass dirt pixel art
```

Tile47 / autotile 素材必须覆盖：

```text
grass base / center
dirt base / center
grass-to-dirt edges
grass-to-dirt outer corners
grass-to-dirt inner corners
thin strips
single tile islands
T junctions / cross variants if included by the format
small grass / dirt noise decals if available
```

交付格式：

```text
source URL
license
tileset PNG path
tile size, preferred 32x32
grid layout notes
format notes: Tile47 / blob / RPG Maker autotile / Godot terrain compatible
2-3 stitched preview images showing grass area, dirt patch, curved path, and transition edges
recommendation: use / reject / needs cleanup
```

验收要求：

- 两块同类 tile 相邻时不能明显露出方形边界。
- grass / dirt transition 不能是硬矩形。
- curved road / patch preview 不能读成一串方块。
- 风格要接近 dark fantasy ARPG；避免过亮、过卡通、过饱和。
- 如果 AI 生成结果不严格对齐 32x32 grid，必须标记为 rejected or needs cleanup。

Goal:

把 `MainWorld` 中 FixedTown 到 GeneratedRegion 的地表表现从“规整 tile / 色块 / 黑 void”推进到第一版可读的 dark fantasy outdoor。这个任务合并处理地表自然化、Town-to-Wilderness 过渡、walkable 外侧 buffer、road 视觉引导和黑色 void 暴露问题。

Definition:

这不是修 tile seam 的任务。当前问题主要是：

- 地表图案太规整。
- 相同 / 不同地块放在一起不自然。
- Road / dirt / grass / corruption 像矩形块。
- 现有 road tile / ground tile 质量不合格，不能作为主视觉基础继续使用。
- Town fence 到 wilderness boundary / road start 之间有空缺。
- Walkable 以外暴露黑色 void。

本任务应通过 terrain layer、overlay、decal、fixed transition chunk、outer buffer、camera / visible bounds 共同解决。

User does:

- 运行 `MainWorld` 肉眼审查地表是否还像调试色块。
- 审查新 ground base 是否连续，尤其是两块相邻时是否还能看出明显方块边界。
- 判断 road 是否像视觉引导，而不是又宽又硬的黄色 corridor。
- 判断 Town gate 到 wilderness start 是否连续自然。
- 判断 walkable 外侧是否还露出黑色 void。
- 确认哪些新地表素材可以进入 `available` / `accepted`。
- 标出仍然不舒服的位置，让 agent 继续微调。

Task agent does:

- 先完成 `scenes/dev/terrain_tilemap_test.tscn` prototype，不要直接改主地图地表。
- 尽量参考用户提供的 Bilibili Godot TileMap / TileSet 教程链接，尤其是 TileSet 切图、TileMapLayer、terrain / autotile、layer 分工。
- 读取 `scenes/world/main_world.tscn` 和 `scripts/world/main_world.gd`。
- 读取 `docs/OUTDOOR_TERRAIN_ASSET_LIST.md`，使用 TASK-029 的 available terrain / road / transition / decal assets。
- 检查 `GeneratedRegion` 当前 ground / road / boundary 的绘制方式。
- 把当前不合格的 ground / road tile paint 从主地表绘制中移除；不要在旧方块路上继续修补。
- 盘点当前可用地表素材，明确哪些素材因为重复、硬边、色块感太强而不得作为 `GroundBaseLayer` 主素材。
- 重新接入免费可用素材或 AI 生成素材作为新 ground base。素材来源必须在报告中写清楚；如果使用外部免费素材，需要记录 license / source URL；如果使用 AI 生成素材，需要记录生成来源和文件路径。
- 新 ground base 至少覆盖：
  - grass / dead grass base
  - dirt base
  - grass-to-dirt transition or overlay
  - road / trampled path overlay candidate
- 不要做完整 `TileMap` 系统，不要重写 procedural generator；本任务只做 terrain paint / visual layer pass。
- 在 `GeneratedRegion/FirstOutdoorVisuals` 下增加或重构稳定 terrain visual layers：
  - `GroundBaseLayer`
  - `TerrainOverlayLayer`
  - `RoadLayer`
  - `DecalLayer`
  - `OuterBufferLayer`
  - `BoundaryLayer`
- 不要把所有可见东西都做成 TileMap blocker；视觉地表层默认无碰撞。
- 将碰撞继续交给 walkable mask、boundary props、object definitions、Camp blockers。
- `GroundBaseLayer` 必须覆盖正常 camera view 中所有应该可见的世界区域，不能只覆盖 walkable cell 内部。
- `GroundBaseLayer` 应该先铺成连续自然的底，不依赖 road / decal 来遮大块黑区。
- 让 logic corridor 保持足够宽以支持战斗，但 visual road 只占其中较窄区域。
- 使用 `layout.corridors`、zone center、route anchor / socket 数据生成一条从 Town gate / TownExitSocket 出发的 irregular road spine。
- Road spine 不能手写成固定矩形，也不能继续把整条 logic corridor 画成 road。
- Road 不能使用明显方块化、硬边重复的 tile 串作为最终显示。优先考虑：
  - 在连续 base ground 上叠加透明 dirt / trampled decal。
  - 使用较宽的连续 `Line2D` / polygon dirt ribbon 加边缘 decal 打散。
  - 使用真正可拼接的 road tileset sheet，前提是边缘过渡自然。
- Road spine 应有轻微 jitter、宽度变化、断续和边缘噪声，不要是完整矩形 corridor。
- 沿 road spine 放置 road center、road edge blend、corner / turn、road end / fade。
- 用 grass-to-dirt transition、road noise、root stain、dark crack、trampled ground 等 decal 打散重复。
- Town gate 到 wilderness entry 之间建立 fixed transition chunk / apron：
  - trampled ground
  - dirt start
  - rocks / small props
  - broken fence or signpost
  - road start cue
- transition chunk 可以先保留程序生成，但需要集中到 helper，例如 `_build_transition_terrain_layers()`，避免继续堆 scattered magic rect。
- FixedTown fence 到 GeneratedRegion boundary 之间不能留黑色空洞。
- Walkable 外侧增加 outer buffer：
  - base ground fill
  - darker grass / dead grass
  - sparse rocks / trees / fence / root visual
  - optional darkened edge
- Outer buffer 不能做成一个巨大黑遮罩；应该是 base ground fill + darker grass / dead grass + sparse props / decal。
- Camera / visible world bounds 只作为兜底，不应该靠限制镜头掩盖地表缺口。
- 更新 debug / smoke，验证必要 layer 存在、Town gate 到 wilderness road 连续、边界阻挡仍有效。

Terrain naturalization rules:

```text
Base ground covers broad visible world bounds.
Base ground must not expose obvious square tile borders in normal view.
Road is a visual guide, not the full walkable corridor.
Road edges are irregular and blended.
Decals break up repetition but do not block players.
Corruption appears as local patch / stain / crack, not a hard rectangle.
Boundary props close the readable area; outer buffer hides void.
```

Collision rules:

- `GroundBaseLayer` no collision。
- `TerrainOverlayLayer` no collision。
- `RoadLayer` no collision。
- `DecalLayer` no collision。
- Small visual scatter no collision by default。
- Boundary props / blocker objects must retain collision。
- Interactables keep interaction area separate from collision。
- Do not add collision to road noise、grass patches、trampled ground、cracks、stains、small decorative gravel。

Implementation notes:

- If the current terrain is drawn programmatically in `main_world.gd`, keep the first pass pragmatic but avoid hardcoding scattered magic numbers without helper functions.
- If introducing data config is cheap, prefer small structured arrays for road / decal / transition placement.
- Do not rewrite the whole generator unless required. This pass may add a terrain paint pass over existing layout / chunks.
- If road / transition assets look visually weak, do not promote them into the main visual result; mark them rejected / placeholder and replace the visible paint path.
- Preserve `Procedural Map Test` and existing walkable overlay tools; terrain paint should not break debug payloads.
- Smoke test 只验证工程合同，不负责证明视觉最终好看；“是否自然”必须由用户肉眼审查。

Acceptance:

- Prototype scene exists and can be opened independently from `MainWorld`。
- Prototype shows continuous grass base、dirt area、grass/dirt transition、curved road、decal breakup。
- Prototype passes user visual review before changing `MainWorld` terrain integration。
- `MainWorld` no longer shows large black void directly adjacent to Town gate, generated road, or walkable boundary in normal camera view.
- `GroundBaseLayer` covers FixedTown exit, transition apron, GeneratedRegion, and normal visible outer buffer without exposing black background.
- Old rejected ground / road tile paint is removed from the main visible terrain path.
- New grass / dead grass / dirt base tiles or textures read as continuous when repeated; obvious square tile borders are not acceptable in normal view.
- Town gate to wilderness start has a visible fixed transition chunk / apron.
- Town fence / Camp boundary and GeneratedRegion boundary visually connect without an obvious empty gap.
- Ground outside walkable area is not simply black; it has base fill, outer buffer, darkened terrain, boundary props, or is hidden by camera / visible bounds.
- Road is visibly narrower than the logic corridor and functions as visual direction cue.
- Road is not a hard straight rectangle; it has some irregularity, edge blending, jitter, broken edges, or decal breakup.
- Road does not read as a chain of square road tiles.
- Road / grass / dirt / corruption transitions do not read as large hard-edged blocks.
- Repeated tile pattern is reduced through overlay / decal / patch variation.
- Decals and terrain overlays do not add player collision.
- Boundary props / blockers still prevent walking into void.
- Player can still move from FixedTown through TownExitSocket into GeneratedRegion.
- First Contact route remains readable after terrain paint.
- Smoke test covers:
  - `FirstOutdoorVisuals` 或等价 root 下的 terrain layer nodes exist。
  - `GroundBaseLayer`、`TerrainOverlayLayer`、`RoadLayer`、`DecalLayer`、`OuterBufferLayer` exist。
  - road layer / transition chunk has at least one node / paint entry。
  - outer buffer layer has at least one node / paint entry。
  - TownExitSocket to wilderness start remains passable。
  - boundary blockers still block side exits。
  - transition chunk has road / decal / outer buffer nodes。
  - no terrain overlay / decal nodes are on blocking collision layers。
- Completion report includes screenshots or capture artifacts if feasible, plus a short “user review required” note for visual naturalness.
- Completion report lists replaced / rejected terrain assets and newly introduced terrain assets, including source / license notes when relevant.
- 完成后在本任务条目下写入 `Task agent status: done`。

禁止项:

- 不调技能数值。
- 不做完整 quest。
- 不做 dungeon interior。
- 不重写 combat、loot、inventory、skill。
- 不把 visual road 当成唯一可走路径。
- 不给所有 decals / small details 加碰撞。
- 不用一个巨大黑遮罩掩盖所有问题。
- 不把本任务变成最终美术 polish。
- 不继续沿用被用户否定的方块路作为主路表现。
- 不把黑区问题交给 camera limit 单独解决。

Task agent status: done

Task agent report:

```text
Task:
TASK-032 Dual Grid Wang16 Terrain Prototype Redo

Status:
done / algorithm prototype ready; final terrain art pending user asset

Files changed:
- scripts/terrain/dual_grid_terrain_painter.gd
- scripts/dev/terrain_dual_grid_wang_test.gd
- scenes/dev/terrain_dual_grid_wang_test.tscn
- tools/smoke_task32_dual_grid_wang_test.gd
- assets/sprites/terrain/debug/dual_grid_wang16_placeholder_16.png
- artifacts/task32_dual_grid_algorithm_preview.png
- artifacts/task32_dual_grid_wang_preview.png
- TASK_BOARD.md

Summary:
- Rewrote the Task32 prototype around dual-grid Wang16 instead of FrameRonin / Tile47.
- Added `DualGridTerrainPainter`, which stores logical terrain points, paints dirt rectangles / curved dirt paths, computes a 4-corner mask per display tile, and maps the 16 masks into a 4x4 atlas.
- Added independent prototype scene `scenes/dev/terrain_dual_grid_wang_test.tscn`.
- Did not change `MainWorld`, `FixedTown`, `GeneratedRegion`, combat, quest, loot, inventory, collisions, or the old generator.
- Final asset path remains `res://assets/sprites/terrain/pixellab_dark_arpg_wang/tileset_dark_grass_dirt_wang16_32.png`; because the user said assets will be supplied later, the prototype currently falls back to `res://assets/sprites/terrain/debug/dual_grid_wang16_placeholder_16.png`.

Mask bit order:
- bit 0 / value 1 = top-left logical point.
- bit 1 / value 2 = top-right logical point.
- bit 2 / value 4 = bottom-left logical point.
- bit 3 / value 8 = bottom-right logical point.

mask_to_atlas_coords table:
- 0 -> (0, 0)
- 1 -> (1, 0)
- 2 -> (2, 0)
- 3 -> (3, 0)
- 4 -> (0, 1)
- 5 -> (1, 1)
- 6 -> (2, 1)
- 7 -> (3, 1)
- 8 -> (0, 2)
- 9 -> (1, 2)
- 10 -> (2, 2)
- 11 -> (3, 2)
- 12 -> (0, 3)
- 13 -> (1, 3)
- 14 -> (2, 3)
- 15 -> (3, 3)

Verification:
- `powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 --headless --path . --import` PASS
- `powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 --headless --path . --script res://tools/smoke_task32_dual_grid_wang_test.gd` PASS

Preview:
- `artifacts/task32_dual_grid_algorithm_preview.png`
- `artifacts/task32_dual_grid_wang_preview.png`

Risks:
- Current preview uses a debug placeholder atlas, so it validates algorithm shape only, not final visual quality.
- When the final Wang16 PNG is added, the only expected tuning point should be `MASK_TO_ATLAS_COORDS`; the logical algorithm should not need to change.
```

Superseded task agent report, do not follow:

```text
Task:
TASK-032 Terrain Paint And World Edge Integration Pass

Status:
prototype ready / user visual review required

Files read:
- TASK_BOARD.md
- docs/OUTDOOR_TERRAIN_ASSET_LIST.md
- .codex/external/FrameRonin/frontend/src/components/infiniteMap/blobTerrain.ts
- .codex/external/FrameRonin/frontend/public/map/blob/map.html
- .codex/external/FrameRonin/frontend/public/map/blob/*
- .codex/external/FrameRonin/frontend/public/map/tileg/*
- .codex/external/FrameRonin/frontend/public/map/tiler/*

Files changed:
- assets/sprites/terrain/frameronin/blob/frame_004.png
- assets/sprites/terrain/frameronin/blob/frame_004X1.png
- assets/sprites/terrain/frameronin/tileg/frame_004.png
- assets/sprites/terrain/frameronin/tiler/frame_004.png
- assets/sprites/terrain/frameronin/tiler/frame_007.png
- docs/OUTDOOR_TERRAIN_ASSET_LIST.md
- scenes/dev/terrain_tilemap_test.tscn
- scripts/dev/terrain_tilemap_test.gd
- tools/smoke_task32_terrain_tilemap_test.gd
- artifacts/task32_terrain_tilemap_test_preview.png
- scripts/terrain/blob_tile47.gd
- scripts/terrain/terrain_cell_field.gd
- TASK_BOARD.md

Summary:
- Re-read the updated TASK-032 contract and followed its prototype-first requirement instead of continuing MainWorld integration.
- Cloned and inspected `systemchester/FrameRonin`, then copied selected `map/blob`, `map/tileg`, and `map/tiler` atlas PNGs into project terrain assets.
- Built `scenes/dev/terrain_tilemap_test.tscn` with required nodes: `GroundBaseTileMapLayer`, `DirtRoadTileMapLayer`, `TerrainOverlayTileMapLayer`, `DecalPreviewLayer`, and `PropPreviewLayer`.
- Implemented a Godot 4.6 `TileMapLayer` prototype using FrameRonin's 8-neighbor blob / Tile47-like atlas mapping.
- Refactored the prototype to borrow FrameRonin's architecture more cleanly: `scripts/terrain/blob_tile47.gd` owns atlas slicing / mask-to-index painting, and `scripts/terrain/terrain_cell_field.gd` owns reusable cell-layer queries / transition rings / blob masks.
- Prototype paints continuous grass base, dirt / trampled patches, grass-to-dirt transition cells, a curved road spine, decal breakup, and a few prop previews.
- To avoid repeating the rejected square-road problem, the road's readable body uses continuous `Line2D` dirt ribbons over the TileMapLayer mask; the TileMapLayer still proves the atlas workflow.
- Did not modify `MainWorld`, generator, combat, quest, loot, inventory, or collisions in this pass.

Source / license:
- Source URL: https://github.com/systemchester/FrameRonin
- License: no explicit asset license found in the repository; treat as prototype-only pending confirmation.
- Format: blob / Tile47-like atlas, 3 columns x 24 rows, 24x24 cells.
- Note: FrameRonin tile size is 24x24, not the preferred 32x32.

Preview:
- `artifacts/task32_terrain_tilemap_test_preview.png`

Verification:
- `powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 --headless --path . --import` PASS
- `powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 --headless --path . --script res://tools/smoke_task32_terrain_tilemap_test.gd` PASS

Findings:
- FrameRonin is useful to validate TileMapLayer / blob-mask workflow quickly.
- The palette is too bright for final dark fantasy outdoor without recolor / replacement.
- The repository did not expose a clear license file for these map assets, so they should not be promoted into final MainWorld art yet.

Risks:
- Prototype smoke verifies node contract and paint counts only; it does not prove final visual quality.
- MainWorld terrain integration remains intentionally untouched until user visual review accepts the direction.

Recommended next task:
User visual review of `scenes/dev/terrain_tilemap_test.tscn` / preview artifact. If accepted, continue TASK-032 with MainWorld integration; if rejected, replace or recolor the Tile47 asset before integration.
```

Rejected previous task agent report:

```text
Task:
TASK-032 Terrain Paint And World Edge Integration Pass

Status:
done

Files read:
- TASK_BOARD.md
- docs/OUTDOOR_TERRAIN_ASSET_LIST.md
- data/maps/first_outdoor_map.json
- scripts/maps/first_outdoor_generated.gd
- scripts/world/main_world.gd
- tools/smoke_main_world_contract.gd
- tools/smoke_task30_camp_assembly.gd

Files changed:
- data/maps/first_outdoor_map.json
- scripts/maps/first_outdoor_generated.gd
- scripts/world/main_world.gd
- tools/smoke_main_world_contract.gd
- TASK_BOARD.md

Summary:
- Added stable terrain visual layers under `GeneratedRegion/FirstOutdoorVisuals`: `GroundBaseLayer`, `TerrainOverlayLayer`, `RoadLayer`, `DecalLayer`, `OuterBufferLayer`, and `BoundaryLayer`.
- Replaced the old full-rect road paint with a narrower visual road spine generated from zone route centers. After user review, removed the ugly repeated road tile blocks and switched the visible road body to continuous `Line2D` dirt ribbons with sparse road noise decals.
- Added outer buffer base fill / dead grass tiling / edge decals so normal camera view is less likely to expose black void outside walkable space.
- Added zone edge breakup, trampled ground, corruption decals, root stains, cracks, and grass-to-dirt blends to reduce hard rectangular reads.
- Rebuilt `TransitionChunk` as layered terrain (`OuterBufferLayer`, `GroundBaseLayer`, `TerrainOverlayLayer`, `RoadLayer`, `DecalLayer`) with a fixed town-to-wilderness apron, continuous road ribbon, trampled decals, rocks, signpost, and broken fence visual cues.
- Kept visual terrain layers collision-free; blocking remains on boundary / prop collision systems.
- Extended `smoke_main_world_contract.gd` to validate required terrain layers, non-collision paint layers, non-empty road/decal/outer-buffer layers, and the transition paint contract.

Verification:
- `powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 --headless --path . --script res://tools/smoke_main_world_contract.gd` PASS
- `powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 --headless --path . --script res://tools/smoke_task30_camp_assembly.gd` PASS
- `powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 --headless --path . --script res://tools/smoke_first_outdoor_generated.gd` PASS

Notes:
- User review found the first road pass unacceptable because it visibly repeated square road tiles and left a black join around the camp-to-generated transition. Follow-up changed the road rendering to continuous dirt ribbons and expanded / brightened the transition ground coverage.
- No screenshot artifact was generated in this pass; visual naturalness still needs user review in the running `MainWorld`.
- This is a terrain paint / integration pass only. It does not replace the generator with a full TileMap / terrain autotile system.
```

## 后续建议顺序

```text
TASK-032 Terrain Paint And World Edge Integration Pass
TASK-033 Outdoor Walkable Shape And Pacing Follow-up
TASK-034 Camp Collision Tuning Pass
TASK-035 First Outdoor Playable Loop Pass
TASK-036 Quest Contract / First Quest Loop
TASK-037 Dungeon Entrance Contract And Transition
```

## 暂停项

旧 backlog 已从本任务板移除。不是永久取消，而是在第一张半随机 outdoor map 的规格和原型完成前不继续排期；需要恢复时再从历史归档或 git history 里重新评估。

## Reporting Format

agent 完成任务时，按这个格式汇报：

```text
Task:
Status:
Files read:
Files changed:
Summary:
Findings:
Risks:
Recommended next task:
```

同时在对应 task 条目中更新：

```text
Task agent status: done
```
