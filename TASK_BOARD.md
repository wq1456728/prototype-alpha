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

`TASK-023` 到 `TASK-026` 已归档：现在有 seed 可复现的 semi-procedural map core、第一张 outdoor config、per-object footprint collision、连续 boundary pass，以及能显示 `walkable_cells` / `boundary_cells` / `blocked_cells` 的 `Procedural Map Test` overlay。

`TASK-027` 到 `TASK-029` 已归档：当前方向已改为 persistent `MainWorld`，包含固定 `FixedTown` 和同一世界坐标系下的 `GeneratedRegion`；第一张 outdoor 的 P0 terrain vocabulary 已冻结，Camp 所需的 P1 支撑素材也已经入库为 `available`。

当前优先级不是继续调技能数值，也不是扩完整任务系统。当前最高优先级是把固定基地修成可用、可手调、能承载后续 NPC / stash / waypoint / quest 起点的 Camp。

完整历史见 [docs/TASK_ARCHIVE.md](docs/TASK_ARCHIVE.md)。

## 当前设计结论

第一张图不采用“AI 一次性设计一张固定地图”的方式。

当前方向是实现一套 Godot 内可运行、seed 可复现的受控随机生成算法，让每次进入第一张 outdoor 时可以生成不同布局，但仍保持固定的暗黑式关卡骨架。

Camp / base 不走 procedural generator。Camp 是固定区域，价值在于安全区、出生点、NPC / stash / quest 起点、进入第一张 outdoor 的出口。用户可以手动调整营地布局和美术；agent 应先搭一个结构合理的固定底稿。

第一张 outdoor 不再作为传统 scene switching 的目标地图。它应作为 `MainWorld` 同一坐标系下的 `GeneratedRegion`，从 `FixedTown` 出口附近开始生成。玩家离开基地后，回头仍然能看到基地。

后续以 [docs/WORLD_STRUCTURE.md](docs/WORLD_STRUCTURE.md) 为准：不要使用 `Town.tscn -> Wilderness.tscn` 的主流程，不 teleport 玩家到另一张地图；使用 persistent world scene、fixed town、anchor / socket based wilderness expansion。

第一张 outdoor map 必须始终包含：

- Camp 出口连接点。
- First Contact 第一次遇敌区。
- Road / field route 主路线。
- Fork 分岔。
- Dungeon entrance 支线入口。
- Optional loot pocket 或 shrine。
- Elite / mini boss pressure point。
- Next area exit 或 demo 终点 hook。

## 当前任务

### TASK-030: Camp Visual Assembly And Gate Collision Pass

Status: done

Goal:

把 `MainWorld` 里的固定 `FixedTown` / Camp 从 rough placeholder 修成第一版可玩的营地。使用 `TASK-029` 已入库的 Camp 素材，把基地周围用木栅栏围起来，修正大门碰撞，让玩家能从门中间离开，同时保留用户后续手动调整布局的空间。

Definition:

这个任务是固定 Camp 的视觉装配和碰撞 pass，不是随机生成任务。Camp 不走 procedural generator，不使用随机 boundary algorithm；第一版允许 agent 直接按固定坐标摆放，后续用户可以在 scene / data 中手动微调。

User does:

- 审查 Camp 是否终于像一个营地，而不是抽象块。
- 手动微调道具、NPC、stash、waypoint、帐篷、火堆、围栏的位置。
- 决定哪些 `available` Camp 素材可以升级为 `accepted`。
- 暂不要求完整 quest 系统。

Task agent does:

- 读取 `scenes/world/main_world.tscn`、`scripts/world/main_world.gd`、`scenes/maps/camp_scene.tscn`、`scripts/maps/camp_scene.gd`，确认当前 `FixedTown` 来源和节点契约。
- 使用 `TASK-029` 入库的 Camp 素材：
  - `prop_camp01_wood_fence_straight_96_a.png`
  - `prop_camp01_wood_fence_corner_96_a.png`
  - `prop_camp01_wood_fence_broken_96_a.png`
  - `prop_camp01_wood_fence_gate_side_96_a.png`
  - `prop_camp01_palisade_wall_96_a.png`
  - `prop_camp01_tent_128_a.png`
  - `prop_camp01_campfire_64_a.png`
  - `prop_camp01_stash_chest_64_a.png`
  - `prop_camp01_crate_barrel_stack_96_a.png`
  - `prop_camp01_waypoint_marker_96_a.png`
  - `npc_camp01_quest_giver_idle_64_a.png`
  - `decal_camp01_trampled_ground_64_a.png`
- 把 Camp 周围用木栅栏围住，至少包含横向围栏、纵向围栏、角落和大门区域。
- 横向围栏和纵向围栏必须使用不同视觉方向。第一版可以通过旋转已有素材或使用不同节点 scale / rotation 实现，但必须在 scene / script / config 中清楚表达方向；不要让所有边都看起来是同一张横向素材硬贴。
- 大门区域必须中间可通行，两侧有碰撞：
  - 不允许给整张大门图做一整块 blocker。
  - 门柱 / 侧门 / 门边可以有碰撞。
  - 中间通道必须连通 `TownExitSocket` 到 `GeneratedRegion` 的连接区。
- 给 fence、palisade、tent、stash、crate/barrel 等占地物加第一版 collision。碰撞盒不必最终完美，但不能明显挡住门口、出生点、NPC、stash 或 waypoint。
- Camp 内摆放：
  - NPC placeholder。
  - Stash chest。
  - Waypoint marker。
  - Campfire。
  - Tent。
  - Crate / barrel supply stack。
  - Trampled ground decal / camp floor wear。
- 保持 y-sort / z-index 正常：玩家在道具下方时应显示在前，玩家在道具上方时可被道具遮挡。排序基准优先使用 foot point / collision footprint 下沿。
- 增加一个轻量 NPC interaction placeholder：
  - 节点名清楚，例如 `QuestGiverPlaceholder`。
  - 有 `Area2D` 或等价交互区域。
  - 玩家靠近或交互时能显示临时文本即可。
  - 不做完整 quest state machine、不做奖励、不接 dungeon clear 条件。
- 新增或更新 smoke test，验证 Camp / `MainWorld` 中：
  - `FixedTown` 存在。
  - 关键 Camp props 存在。
  - 围栏 / 大门节点存在。
  - 大门中间从 spawn / town interior 到 `TownExitSocket` 可通行。
  - 侧边围栏或 blocker 能阻挡玩家离开 Camp 边界。
  - NPC placeholder、stash、waypoint、campfire 节点存在。

Implementation note:

- Camp 是固定区域，允许先用固定坐标。不要把 Camp fence placement 放进 procedural generator。
- 如果当前 `FixedTown` 是从 `camp_scene` 结构拷贝 / 实例化而来，优先保持一个来源清楚的实现，避免 scene 和 script 两边各维护一套不同布局。
- 横向 / 竖向围栏如果暂时没有独立素材，可以旋转现有木栅栏作为第一版，但要在完成报告里标明这是 placeholder，后续可以由 Asset Agent 生成真正的 vertical fence。
- 大门建议用两个 `wood_fence_gate_side` 或门柱节点拼出入口，碰撞只放左右两侧。
- NPC placeholder 只负责交互占位，不引入完整任务模块。完整任务系统后续单开任务。

Acceptance:

- 打开 `MainWorld` 时，基地内部不再是大面积 placeholder / ColorRect 拼块；Camp 至少有 fence、gate、tent、campfire、stash、waypoint、NPC、supplies 的可读布局。
- Camp 四周有木栅栏或木桩墙形成明确边界。
- 横向边界和纵向边界的视觉方向不同，不能四边都像同一方向素材。
- 大门中间可以通过；大门两侧或门柱有碰撞。
- 玩家不能从非大门位置随便穿出 Camp。
- Camp 出口仍然连接 `GeneratedRegion` 的 wilderness start / town connection corridor，不被新增 fence / collision 堵住。
- `GeneratedRegion` 的 transition chunk、boundary objects、combat chunk 起点和随机装饰不得覆盖或堵住 Camp gate opening；TownExitSocket 到 wilderness start 必须保持一条清楚、可走、可读的连续通路。
- 关键 Camp prop 不遮挡玩家出生点、出口或主要交互点。
- NPC / stash / waypoint / campfire / tent / supplies 都能在 scene tree 中定位，命名清楚。
- `QuestGiverPlaceholder` 有轻量交互占位，但不做完整 quest module。
- y-sort / z-index 不出现明显错误：玩家不会长期被地面、整块 town background 或不该遮挡的 fence 压住。
- Smoke test 覆盖关键节点、门口通行、边界阻挡和交互 placeholder 存在。
- 完成后在本任务条目下写入 `Task agent status: done`。

禁止项:

- 不做完整任务系统。
- 不做 quest reward、洞窟清怪条件、任务日志 UI。
- 不重写 outdoor generator。
- 不做后续 terrain paint。
- 不把 Camp 改成随机生成。
- 不因为素材还不是最终美术而阻塞第一版固定摆放。
- 不删除用户手动调整过的 scene 内容；如果必须替换，先确认它属于旧 placeholder。

Task agent status: done

Task agent report:

```text
Task:
TASK-030 Camp Visual Assembly And Gate Collision Pass

Status:
done

Files read:
- TASK_BOARD.md
- scenes/world/main_world.tscn
- scripts/world/main_world.gd
- scenes/maps/camp_scene.tscn
- scripts/maps/camp_scene.gd
- tools/smoke_main_world_contract.gd
- tools/smoke_camp_scene_contract.gd
- scripts/physics/collision_layers.gd

Files changed:
- scripts/world/main_world.gd
- tools/smoke_task30_camp_assembly.gd
- TASK_BOARD.md

Summary:
- Replaced the rough `FixedTown` placeholder prop layout in `MainWorld` with the TASK-029 Camp asset set: wooden fence perimeter, gate side posts, tents, campfire, stash chest, waypoint marker, crate/barrel stack, palisade storage, trampled ground decals, and NPC placeholder.
- Built the Camp as fixed layout code in `main_world.gd`; Camp remains outside procedural generation.
- Added horizontal fence segments, rotated vertical fence segments, four corners, and a two-post gate. The gate center remains open while both sides collide.
- Added first-pass collision for fence, gate posts, tents, stash, waypoint, campfire, palisade, supply stack, broken fence detail, and NPC placeholder.
- Added lightweight `QuestGiverPlaceholder/InteractionArea` and a temporary hint label: `Clear the den outside the camp.`
- Added `tools/smoke_task30_camp_assembly.gd` to validate key Camp nodes, fence orientation, interaction placeholder, gate passability, and side-boundary blocking.

Verification:
- `powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 --headless --path . --script res://tools/smoke_task30_camp_assembly.gd` PASS
- `powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 --headless --path . --script res://tools/smoke_main_world_contract.gd` PASS
- `powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 --headless --path . --script res://tools/smoke_task29_asset_inventory.gd` PASS

Findings:
- Current `FixedTown` is generated programmatically in `scripts/world/main_world.gd`, not instanced from `camp_scene.tscn`; keeping the Task30 layout there avoids two competing Camp sources.
- Vertical wooden fences currently use the straight fence asset rotated by 90 degrees. This satisfies first-pass directional readability, but a dedicated vertical fence sprite would look cleaner.

Risks:
- This is still an agent-placed first pass. User visual review in the running scene is needed for exact spacing, collision feel, and final prop placement.
- NPC interaction is deliberately only a placeholder; no quest state, reward, or dungeon-clear logic was added.
- Some collision boxes are conservative first-pass shapes and may need hand tuning after visual inspection.

Recommended next task:
TASK-031 Asset Footprint Draft And Collision Preview Tool
```

## 最近完成摘要

### TASK-027 / TASK-028 / TASK-029

- `TASK-027`：建立了 Camp scene contract、outdoor transition 接口和 P0 asset intake 初版。后来主流程方向被用户修正为 persistent `MainWorld`，旧 scene switching 只保留为参考。
- `TASK-028`：建立 persistent `MainWorld`，把 fixed town 和 generated wilderness 放进同一 world space；玩家离开基地后仍能回头看到基地。
- `TASK-029`：冻结第一张 outdoor P0 terrain vocabulary，并补入 road / transition / decal / Camp support assets。复审已通过但有风险：部分素材仍只是 `available` placeholder，需要在后续 terrain paint / Camp polish 中肉眼审查。

详细历史和审查结论见 [docs/TASK_ARCHIVE.md](docs/TASK_ARCHIVE.md)。

## 当前任务

### TASK-031: Asset Footprint Draft And Collision Preview Tool

Status: done

Task agent status: done

Goal:

建立一个半自动工具，为新导入的 sprite / prop / enemy / interactable 生成第一版 collision footprint、interaction area、sprite offset 和 sort point 建议，并提供可读的碰撞预览。这个工具用于先解决 `TASK-030` 后暴露出的 Camp 碰撞调参问题，再服务后续 outdoor props / dungeon entrance。

Why:

- `TASK-030` 已把 Camp 视觉素材摆进去，但用户复查发现碰撞仍有明显问题；继续手调前需要更好的可视化和 draft 工具。
- 当前 prop、角色、入口、倒地物、栅栏等资产的碰撞语义不同，单纯按整张图片或底部固定比例生成碰撞会经常错。
- 人工逐个调 collision footprint 成本高，且容易遗漏 `sprite_offset`、`sort_y`、interaction area 等配套数据。
- Agent 比较适合给素材标 `asset_type`，算法可以根据类型生成更可靠的 draft，再由用户 / agent review。

Input:

```text
image_path
asset_type
optional asset_id
optional orientation
optional intended_behavior
optional output_path
```

Required asset types:

```text
character
enemy
prop_low
prop_tall
barrier
entrance
interactable
decal
ground_tile
```

First target assets:

```text
Camp fence straight / vertical-rotated fence
Camp fence corner
Camp gate side post
Camp tent
Camp stash chest
Camp crate / barrel stack
Camp waypoint
Campfire
NPC placeholder
Existing dungeon entrance
Existing dead tree / rock / broken cart
```

Type behavior:

- `character` / `enemy`：生成脚底小 ellipse / capsule，表示站位和挤碰，不按整张身体。
- `prop_tall`：只挡底座 / 树干 / 支撑区域，不挡树冠、帐篷顶部等高处视觉。
- `prop_low`：接近物体底部整体 footprint，例如石头、箱子、倒地马车。
- `barrier`：生成横向 / 纵向连续 blocker，例如栅栏、墙、根须。
- `entrance`：支持多段 collision parts，中间保留 opening；不能整张入口图挡死。
- `interactable`：生成 collision footprint 和 interaction area，两者分开。
- `decal` / `ground_tile`：默认 no collision。

Recommended output: `FootprintDraft`

```json
{
  "asset_id": "prop_example",
  "image_path": "res://assets/sprites/props/example.png",
  "asset_type": "prop_low",
  "image_size": {"w": 96, "h": 96},
  "sprite": {
	"visual_bounds": {"x": 4, "y": 18, "w": 88, "h": 66},
	"foot_point": {"x": 48, "y": 78},
	"sprite_offset": {"x": 0, "y": -30},
	"sort_y_offset": 0
  },
  "collision": {
	"enabled": true,
	"shape": "rect",
	"orientation": "horizontal",
	"size": {"x": 82, "y": 18},
	"radius": 0,
	"offset": {"x": 0, "y": -9},
	"parts": []
  },
  "interaction": {
	"enabled": false,
	"shape": "none",
	"size": {"x": 0, "y": 0},
	"offset": {"x": 0, "y": 0}
  },
  "analysis": {
	"confidence": 0.76,
	"needs_review": true,
	"reason": "prop_low uses lower visible band as footprint",
	"warnings": []
  }
}
```

Entrance example requirement:

```text
collision.parts:
- left_blocker
- right_blocker
opening:
- center
- size
interaction:
- enabled true
- covers entrance trigger area
```

Implementation notes:

- Use PNG alpha mask to detect visible bounds.
- Ignore fully transparent pixels and tiny alpha noise.
- Analyze lower visible band, but band ratio must depend on `asset_type`。
- Output confidence and `needs_review`; low confidence must not be silently accepted。
- Output should be convertible into `map_object_defs.json` or future object definition drafts。
- Provide a debug preview mode or generated overlay image showing sprite bounds、foot point、collision、interaction area。
- For Camp assets, the tool must be able to produce a side-by-side or per-asset preview that makes it obvious whether the collision is too high, too low, too wide, or blocking a gate opening。
- Tool output may be used by the next task to tune `FixedTown` collisions, but this task should not silently rewrite all Camp collisions without review。

Acceptance:

- Tool can process at least one example for each required `asset_type`。
- Tool returns structured `FootprintDraft` JSON with stable keys。
- Tool can run against the current Camp asset set and write draft output under a review / artifacts path。
- Tool can generate a readable preview overlay image for Camp collision review。
- `entrance` supports multi-part collision and opening。
- `interactable` separates collision and interaction area。
- `decal` and `ground_tile` return collision disabled。
- Draft output includes confidence、needs_review、reason、warnings。
- Tool does not overwrite accepted object definitions without explicit confirmation。
- Add smoke / fixture tests using existing assets, e.g. camp fence、dead tree、camp chest、dungeon entrance、NPC placeholder、road decal。

Report:

```text
Task:
TASK-031 Asset Footprint Draft And Collision Preview Tool

Status:
done

Files read:
- TASK_BOARD.md
- scripts/debug/collision_debug_overlay.gd
- scripts/maps/procedural/map_object_definition.gd
- scripts/maps/procedural/map_object_factory.gd
- data/maps/map_object_defs.json

Files changed:
- scripts/tools/asset_footprint_draft_tool.gd
- tools/smoke_asset_footprint_draft.gd
- tools/generate_task31_footprint_review.gd
- artifacts/task031_footprint_drafts/smoke_footprints.json
- artifacts/task031_footprint_drafts/smoke_footprints_preview.png
- artifacts/task031_footprint_drafts/task031_camp_footprints.json
- artifacts/task031_footprint_drafts/task031_camp_footprints_preview.png
- TASK_BOARD.md

Summary:
- Added AssetFootprintDraftTool to generate FootprintDraft JSON from PNG alpha bounds and asset_type.
- Added type-specific draft behavior for character, enemy, prop_low, prop_tall, barrier, entrance, interactable, decal, and ground_tile.
- Added multi-part entrance collision drafts with central opening, and separated interactable collision from interaction area.
- Added preview sheet generation: green visual bounds, cyan collision, yellow interaction, and magenta foot point.
- Added smoke fixture script and Camp/outdoor review generation script.

Findings:
- The tool is useful as a first draft and review aid, especially for Camp fence, tent, chest, waypoint, entrance, rocks, and dead tree assets.
- Some confidence scores are intentionally low for barrier / entrance cases because gameplay intent still needs human review.
- The generated output is stored under artifacts and does not overwrite accepted map object definitions.

Risks:
- Rotated in-scene assets still need orientation metadata; the source PNG alone cannot infer scene rotation.
- Draft rectangles/capsules are approximate and should be reviewed before copying into map_object_defs.json or scene data.
- Animated enemy sheets are treated as a single visible image; future enemy-specific tooling may need frame selection.

Recommended next task:
TASK-032 Camp Collision Tuning Pass
```

禁止项:

- 不把工具输出当作最终人工验收。
- 不试图仅凭图片自动判断所有 gameplay intent。
- 不要求在本任务中重做所有现有 object definitions。
- 不把 decal / ground tile 误标为 blocker。
- 不把 entrance 中间 opening 生成成实体 blocker。

## 后续建议顺序

```text
TASK-030 Camp Visual Assembly And Gate Collision Pass
TASK-031 Asset Footprint Draft And Collision Preview Tool
TASK-032 Camp Collision Tuning Pass
TASK-033 First Outdoor Terrain Paint Pass
TASK-034 Outdoor Walkable Shape And Pacing Follow-up
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
