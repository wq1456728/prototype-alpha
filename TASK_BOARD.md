# 任务板

这个文件是其他对话或 agent 的任务入口。它只保留当前任务和最近上下文；历史任务、通用规则和长期计划放在独立文档里。

## 必读入口

当前规划、范围和实现规则以这些文件为准：

- x Create a [SINGLE ASSET TYPE] for Prototype Alpha, a 2D dark fantasy ARPG.​Subject: [SUBJECT].Purpose: [PURPOSE].​Style:Chronicon-like retro 16-bit pixel art.Pseudo top-down / slightly angled side view when applicable.Crisp pixels.Clean 1px dark outline where suitable.Limited palette.High silhouette readability.Dark fantasy mood.Readable gameplay silhouette.​Canvas/output:[SIZE].Transparent PNG.No background.No reflection.No watermark.No preview text.No UI frame unless requested.No soft shadow unless requested.​Asset constraints:Centered subject.Clear readable shape.Strong contrast against dark ground.Consistent scale with 64x64 humanoid characters.Suitable for Godot 2D gameplay.​Avoid anti-aliasing.Avoid blur.Avoid soft painterly shading.Avoid realistic lighting.Avoid realistic rendering.Avoid anime proportions.Avoid thin unreadable details.Avoid noisy texture.Avoid inconsistent scale.Avoid inconsistent camera angle.Avoid strong 45-degree isometric perspective.Avoid huge soft gradients.Avoid semi-transparent body pixels.Avoid ghost transparency.Avoid background scenery.Avoid cropped asset.Avoid text.text
- [docs/PROJECT_PLAN.md](docs/PROJECT_PLAN.md)
- [docs/DEMO_SCOPE.md](docs/DEMO_SCOPE.md)
- [docs/CONTROL_AND_COMBAT.md](docs/CONTROL_AND_COMBAT.md)
- [docs/ART_PIPELINE.md](docs/ART_PIPELINE.md)
- [docs/AGENT_RULES.md](docs/AGENT_RULES.md)
- [docs/TASK_ARCHIVE.md](docs/TASK_ARCHIVE.md)
- [ASSET_PROMPT_TEMPLATE.md](ASSET_PROMPT_TEMPLATE.md)

如果旧笔记和上面文件冲突，以上面文件为准。

## 当前阶段

`combat_sandbox` 的纵向系统链路已经跑通：combat、loot、inventory/equipment、XP/level、skill unlock、Hotbar assignment、objective completion 都已有第一版。

`TASK-020` 到 `TASK-022` 的第一版 outdoor greybox 已经归档。它们证明了部分技术链路，但作为“第一张图体验”不合格：路线结构、探索节奏、教学推进和地图生成模型都不能继续作为当前方向。

当前不再修旧 outdoor greybox，也不继续执行旧 backlog。接下来只集中做一件事：第一张 outdoor map 的半随机生成。

## 当前设计结论

第一张图不采用“AI 一次性设计一张固定地图”的方式。

当前方向是实现一套 Godot 内可运行、seed 可复现的受控随机生成算法，让每次进入第一张图时可以生成不同布局，但仍保持固定的暗黑式关卡骨架。

技术参考：

- [mgalos999/d2-mapper](https://github.com/mgalos999/d2-mapper)：可参考它围绕 seed / difficulty / level 生成可视化地图的使用方式，但它本身主要是 visual map generator。
- [blacha/diablo2 packages/map](https://github.com/blacha/diablo2/tree/master/packages/map)：更值得参考它输出的 map JSON 结构，包括 level id/name、offset、size、objects、collision map。我们不复制 Diablo II 数据或算法，只借鉴“seed -> map payload -> render/debug”的结构。

目标不是完全随机地图，而是：

```text
固定关键锚点
+ 随机路线形状
+ 随机区域模板
+ 随机怪物群落
+ 随机奖励点
+ 稳定边界和碰撞
```

第一张 outdoor map 必须始终包含：

- Camp / spawn 起点。
- First Contact 第一次遇敌区。
- Road / field route 主路线。
- Fork 分岔。
- Dungeon entrance 支线入口。
- Optional loot pocket 或 shrine。
- Elite / mini boss pressure point。
- Next area exit 或 demo 终点 hook。

设计原则：

- 参考 Diablo II 第一张野外图的结构感：安全营地外出、弱怪教学、可读道路、固定洞口、下一张图出口、随机地形和怪物群落。
- 保持 Chronicon-like 的 WASD、pseudo top-down、鼠标释放技能方向。
- 不抄袭具体地图、名称、怪物、任务文本或美术。
- 第一版生成系统可以使用 placeholder / simple tiles，但边界、碰撞和路线必须真实可玩。
- 每个 seed 都必须保证主线可达，不允许生成死路阻断关键流程。

## 当前任务

### TASK-023: Semi-Procedural Map Generator Core

Status: done

Goal:

实现一套 Godot 内可运行的半随机地图生成核心。这个任务先做通用算法、数据结构、边界/collision 生成和 debug/validation，不绑定第一张图的完整玩法内容。

Inputs:

- 必读本任务条目。
- 必读 [blacha/diablo2 packages/map](https://github.com/blacha/diablo2/tree/master/packages/map) README 中的 JSON payload 示例，重点看 `id`、`name`、`offset`、`size`、`objects`、`map` collision data 的思路。
- 可参考 [mgalos999/d2-mapper](https://github.com/mgalos999/d2-mapper) 的 seed/difficulty/level visualization workflow。
- 必读当前项目已有 outdoor scene 和 debug/smoke test：`scenes/maps/outdoor_greybox.tscn`、`scripts/maps/outdoor_greybox.gd`、`tools/smoke_outdoor_greybox_structure.gd`、`tools/debug_outdoor_greybox.gd`。
- 必读 Godot 运行规则：[docs/AGENT_RULES.md](docs/AGENT_RULES.md) 和 `.codex/skills/godot-cli/SKILL.md`。

Focus:

- 建立 `scripts/maps/procedural/` 下的地图生成核心脚本。
- 建立最小数据结构，例如 `MapGenerationConfig`、`GeneratedMapLayout`、`GeneratedZone`、`GeneratedAnchor`、`RouteConnection`、`SpawnGroup`、`BoundarySegment`。
- 使用 seed 初始化 RNG，保证相同 seed 输出相同 layout。
- 支持固定 anchor 放置：start、required branch、required exit。
- 支持 route graph 生成：主路线、支线、optional pocket。
- 支持 zone template 选择：每类模板先最多 2 个 variation。
- 支持 placeholder tile/shape 输出，让地图可以在 Godot 里实际看到。
- 支持 visual boundary 和 collision / blocker 同步生成。
- 支持 monster spawn group / reward marker / objective marker 的占位输出，但不接第一张图的完整数值。
- 增加 map payload debug 输出，结构参考 d2-map JSON 思路：seed、map id/name、size、anchors、objects、spawn groups、collision/blocker data。
- 增加可达性验证：start 到 required exit、start 到 required branch 都必须可达。
- 增加至少 3 个固定 seed 的自动验证。

Core API:

- `MapGenerator.generate(config, seed) -> GeneratedMapLayout`
- `GeneratedMapLayout.to_payload() -> Dictionary`
- `MapGenerationDebug.validate_layout(layout) -> Dictionary`
- `MapGenerationDebug.build_scene(parent, layout)`

API 说明：

- `generate` 只负责从 config + seed 生成 logical layout，不直接依赖当前 scene。
- `to_payload` 必须返回稳定可比较的 plain `Dictionary`，用于 deterministic test 和 audit。
- `validate_layout` 返回结构化结果，例如 `{ "ok": true, "errors": [], "warnings": [] }`。
- `build_scene` 只负责把已生成 layout 可视化到 parent node 下，方便 debug 和 smoke test。

Required file layout:

- `scripts/maps/procedural/map_generator.gd`
- `scripts/maps/procedural/generated_map_layout.gd`
- `scripts/maps/procedural/map_generation_config.gd`
- `scripts/maps/procedural/map_generation_debug.gd`
- `scenes/maps/procedural_map_test.tscn` 或等价 test scene。
- `tools/smoke_map_generator_core.gd`

如果已有文件结构明显更合适，可以调整，但完成报告必须说明原因。

V1 algorithm constraints:

- 使用 `RandomNumberGenerator` 和 explicit seed；不要使用不可复现的全局随机。
- 先生成 logical layout，再生成 Godot nodes。不要一边随机一边直接散落节点，避免后续不可审查。
- `Rect2`、`Vector2`、NodePath、Object reference 不能直接进入 debug payload；必须序列化成 plain data，例如 `{x, y, w, h}` 或 `{x, y}`。
- 内部变量不要命名为 `objects`，避免和 Godot `Object` 基类混淆；内部使用 `map_objects`，payload 可输出字段名 `objects`。
- V1 使用 zone graph，不要求完整 tile grammar：
  - 一条 main path，长度 4-6 个 zone。
  - 1 条 required branch。
  - 0-1 条 optional pocket。
  - 每个 zone 有 rectangle bounds、entry/exit anchors、type、template id。
- route 可以用折线 corridor 或 simple road rectangles 表达，不需要最终地形美术。
- boundary 可以先用 rectangles / segments 生成，但 visual placeholder 和 collision blocker 必须成对存在。
- 每个 visual boundary 必须带 `source` 或 `blocker_id`；每个 blocker 也必须带对应 `source` 或 `visual_id`，测试按 id/source 对齐。
- collision/blocker 输出可以是 `StaticBody2D` + `CollisionShape2D`，或现有项目更合适的等价结构。
- debug payload 必须能被测试读取，不只是在屏幕上画出来。
- V1 可达性只验证 graph connectivity 和 corridor/zone overlap，不承诺真实 Nav/physics pathfinding；真实玩家物理通路验证留到 `TASK-024` 或后续任务。

Debug payload minimum schema:

```text
{
  seed,
  map_id,
  map_name,
  size,
  zones: [{id, type, template_id, rect, anchors}],
  route_connections: [{from, to, kind}],
  anchors: [{id, type, position, required}],
  objects: [{id, type, zone_id, position}],
  spawn_groups: [{id, zone_id, type, count, budget}],
  boundary_visuals: [{id, rect, source, blocker_id}],
  blockers: [{id, rect, source, visual_id}]
}
```

禁止项:

- 不要接入最终 outdoor 美术。
- 不要在 TASK-023 同时做“好看的第一张图”“怪物/掉落/任务节奏”；这些属于 `TASK-024`。
- 不要做 dungeon 生成。
- 不要做 full overworld/freeform noise map。
- 不要恢复旧 TASK-020/021/022 layout 作为当前地图。
- 旧 `outdoor_greybox` 只能当 Godot scene/script 写法参考，不能复制成“随机版固定图”。
- 不要把 random result 写死成一个固定 scene。
- 不要依赖网络、Docker、Diablo II 安装或第三方 map generator 才能跑本项目测试。

Acceptance:

- 同一个 seed 多次生成结果一致。
- 不同 seed 至少在路线弯曲、区域模板选择、支线方向或 object placement 上有可见差异。
- 生成结果包含 start、required branch、required exit。
- 主路线和关键支线的 graph connectivity + corridor/zone overlap 检查通过。
- 生成的 visual boundary 有对应 collision / blocker，并且 payload 中的 `boundary_visuals[].blocker_id` 与 `blockers[].visual_id` 能互相对齐。
- 同 seed 两次 `to_payload()` 的 stable hash 一致。
- 三个固定 seed 都通过 `validate_layout()`。
- 不同 seed 至少 route、template、branch 或 map_objects 中有一类差异。
- Godot headless smoke test 能验证 3 个固定 seed。
- 有 debug 输出可以让 audit agent 看见 anchors、route graph、spawn groups、blockers。
- `tools/smoke_map_generator_core.gd` 必须通过 Godot headless wrapper。
- 不接入最终 outdoor 美术，不做 dungeon，不恢复旧 backlog。
- 完成后在本任务条目下写入 `Task agent status: done`。

Task agent status: done

Audit Status:

- 2026-05-18 审查：`pass with risks`。`tools/smoke_map_generator_core.gd` 已通过 Godot wrapper，3 个固定 seed 可生成、可验证、同 seed deterministic、不同 seed 有差异，debug scene 能生成 boundary visuals / blockers。
- 暗黑2对标：实现方向符合本任务要求，只借鉴 Diablo II map payload 的结构感：seed、map id/name、offset/size、objects、collision/blocker data；没有复制 Diablo II 数据、算法或依赖外部 D2 安装。当前项目输出是原创 procedural outdoor core。
- 验收对照：`MapGenerator.generate(config, seed)`、`GeneratedMapLayout.to_payload()`、`MapGenerationDebug.validate_layout(layout)`、`MapGenerationDebug.build_scene(parent, layout)` 都存在；payload 使用 plain Dictionary/Array/number/string，不直接暴露 `Rect2`、`Vector2`、NodePath 或 Object。
- 验收对照：payload 包含 start、required_branch、required_exit、zones、route_connections、corridors、objects、spawn_groups、boundary_visuals、blockers；visual/blocker 通过 `blocker_id` / `visual_id` 双向对齐。
- 审查风险：V1 可达性只验证 graph connectivity 和 corridor/zone overlap，没有验证真实 player physics pathfinding。这符合 TASK-023 明确边界，但 TASK-024 接第一张图时必须补真实移动、碰撞和玩家路线验证，不能只沿用本 smoke。
- 审查风险：boundary 目前是外圈 rectangle blocker pair，不是完整 collision map / tile mask。对生成核心可接受，但如果后续要接近 Diablo II map payload 的 collision data，需要把 blocker 输出扩展成更细的 collision grid 或 segment 集合。

Task agent report:

- Files read: `TASK_BOARD.md`, `docs/AGENT_RULES.md`, `.codex/skills/godot-cli/SKILL.md`, existing outdoor greybox scene/scripts/smoke references.
- Files changed: `data/maps/procedural_dummy_config.json`, `scripts/maps/procedural/map_generation_config.gd`, `scripts/maps/procedural/generated_map_layout.gd`, `scripts/maps/procedural/map_generator.gd`, `scripts/maps/procedural/map_generation_debug.gd`, `scripts/maps/procedural/procedural_map_test.gd`, Godot-generated `scripts/maps/procedural/*.gd.uid`, `scenes/maps/procedural_map_test.tscn`, `tools/smoke_map_generator_core.gd`, `TASK_BOARD.md`.
- Summary: implemented seed-reproducible semi-procedural layout core with external dummy config, logical layout payload, route graph/corridors, required branch/exit anchors, optional pocket, placeholder map objects/spawn groups, boundary visual/blocker pairs, labeled debug scene builder, structured validation, stable payload hash, and headless smoke coverage for three fixed seeds.
- Validation: `powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 --headless --path . --script res://tools/smoke_map_generator_core.gd` passed.
- Risks: V1 reachability intentionally validates graph/corridor overlap only; real player navigation, outdoor art hookup, enemy/loot/objective pacing remain for `TASK-024` or later tasks.

### TASK-024: First Outdoor Map Config And Asset Hookup

Status: done

Goal:

把第一张 outdoor map 作为具体 config 套进 `TASK-023` 的生成算法里，明确素材需求、agent 分工和第一张图的玩法结构。

Inputs:

- `TASK-023` 生成器和 smoke tests 必须已完成。
- 必读 [docs/DEMO_SCOPE.md](docs/DEMO_SCOPE.md)、[docs/CONTROL_AND_COMBAT.md](docs/CONTROL_AND_COMBAT.md)、[docs/ART_PIPELINE.md](docs/ART_PIPELINE.md)。
- 旧 [docs/TASK_019_OUTDOOR_GREYBOX_PLAN.md](docs/TASK_019_OUTDOOR_GREYBOX_PLAN.md) 只作为历史参考，不能直接照搬旧路线。

Focus:

- 建立 `data/maps/first_outdoor_map.json` 或等价资源文件。
- 配置第一张图固定结构：camp / spawn、first contact、fork、dungeon entrance branch、loot pocket 或 shrine、elite pressure、next area exit。
- 配置第一张图的 route rules：主路线长度、支线数量、区域顺序、允许弯曲范围、最小/最大场地尺寸。
- 配置 enemy pool 和 spawn budgets：弱怪教学区、普通路段、loot pocket、elite pressure。
- 配置 reward rules：首个 weapon drop、shrine/chest/loot marker 的生成条件。
- 配置 boundary prop rules：树线、石头、腐化根须、破栅栏、废墟等 placeholder/素材映射，以及对应 blocker 规则。
- 明确素材 agent 需要准备的 P0 素材：ground/road tileset sheet、边界 props、camp sign/gate、dungeon entrance、loot/shrine marker、debug-friendly map icons。
- 明确 task agent 需要做什么：把 config 接入生成器、生成 Godot scene、接已有 combat/loot/XP/hotbar loop、跑验证。
- 明确 design lead / user 需要做什么：审 3-5 个 seed 截图，判断路线感觉、区域宽度、分岔、入口可读性。
- 保持旧 `docs/TASK_019_OUTDOOR_GREYBOX_PLAN.md` 只作为历史参考，不直接照搬旧 layout。

Opening pacing rules:

- Camp 必须是真安全区：
  - 出生点附近不能立刻有敌人。
  - 玩家离开 camp 后，至少要走一小段才遇到第一批怪。
  - Camp 出口必须非常清楚，类似 Rogue Encampment 出门到第一张野外图的“唯一明确出口”。
- First contact 必须是教学怪，不是压力怪：
  - 只放 2-3 个弱怪。
  - 怪物分布要松，不能一上来围攻。
  - 目的只是让玩家理解 WASD、鼠标朝向、普通攻击、受击反馈和掉落反馈。
- 主路必须是视觉引导，不是狭窄走廊：
  - route / corridor 应该像 Blood Moor 的路，能引导玩家前进，但不强行把玩家夹在硬通道里。
  - 玩家可以离开路一点点，但不能因此迷失。
  - 两侧用树线、石头、栅栏、腐化根须形成 soft boundary，并配对应 blocker。
- Dungeon entrance branch 是核心任务 hook，不是普通可选支路：
  - 类似 Den of Evil 的作用：玩家应能从 fork 附近读懂“这条支路通向重要目标”。
  - 入口不能藏太远，也不能贴着 camp。
  - 入口区域需要明显 visual anchor。
- Next area exit 是 soft gate：
  - 它可以存在，让玩家知道世界继续向前。
  - 当前 outdoor 任务没完成前，它不应该比 dungeon entrance 更像优先目标。
  - 可以用 scout / sign / sealed roots / corrupted barrier 提示“先处理附近腐化”。
- 第一件装备掉落必须形成 Diablo-like 第一次闭环：
  - 玩家应在 2-4 分钟内看到第一个有用 weapon drop。
  - 掉落后应能马上感到变强。
  - loop 是 kill -> drop -> pick up -> equip -> kill faster。

Required file layout:

- `data/maps/first_outdoor_map.json`
- `scenes/maps/first_outdoor_generated.tscn` 或等价 generated-map entry scene。
- `scripts/maps/first_outdoor_generated.gd` 或等价 scene controller。
- `tools/smoke_first_outdoor_generated.gd`
- `tools/capture_first_outdoor_seed_view.gd` 或复用现有 screenshot 工具。

First outdoor config minimum:

- `map_id`: `first_outdoor`
- `map_name`: project-original name，不要使用 Blood Moor / Den of Evil 等 Diablo II 原名。
- `target_playtime_minutes`: outdoor 段先按 5-10 分钟。
- `required_anchors`: `camp_spawn`、`first_contact`、`road_fork`、`dungeon_entrance`、`elite_pressure`、`next_area_exit`。
- `zone_sequence`: camp -> first_contact -> road/fork -> pressure -> exit。
- `branch_rules`: 至少一条 dungeon branch；可选一条 loot pocket / shrine branch。
- `enemy_pool`: 先引用项目已有 enemy 或 placeholder enemy ids，不在本任务新增完整 enemy family。
- `reward_rules`: 至少一个 early weapon drop marker，一个 optional shrine/chest marker。
- `boundary_rules`: 每个 visual boundary source 必须声明 blocker/collision source。
- `asset_slots`: 先允许 placeholder，但必须列出 P0 替换素材路径和尺寸。

P0 asset request for asset agent:

- `tileset_outdoor01_ground_32.png`：32x32 tile sheet，dead grass、dirt road straight/corner/fork、road edge/transition。
- `prop_boundary_dead_tree_64.png`：64x64，边界树，最多 2 variations。
- `prop_boundary_rock_32.png`：32x32，边界石头，最多 2 variations。
- `prop_boundary_broken_fence_64.png`：64x64，破栅栏，最多 2 variations。
- `prop_corrupted_root_64.png`：64x64，腐化根须，最多 2 variations。
- `prop_camp_gate_128.png`：128x128，营地出口视觉锚点。
- `prop_dungeon_entrance_128.png`：128x128，第一张图的 dungeon entrance。
- `prop_shrine_or_loot_marker_64.png`：64x64，奖励点视觉锚点。
- `prop_route_sign_or_scout_marker_64.png`：64x64，用于 next area soft gate 或任务提示。
- `debug_map_icons_32.png`：32x32 icon sheet，至少包含 camp、dungeon、exit、loot、elite，用于 seed 审图/debug overlay。

Asset note:

- 如果 `assets/sprites/props/outdoor_01/` 或等价目录中已有 ground tileset、corrupted ground、dead tree、rock、broken fence、camp gate、corrupted hollow、roots、shrine、signpost，可以直接作为 placeholder/first-pass asset 接入。
- P0 asset list 不能阻塞实现；缺失素材用明确命名的 placeholder slot 保持结构。

Task agent responsibilities:

- 把 config 接入 `TASK-023` generator。
- 生成可进入的 Godot scene。
- 复用已有 player、combat、loot、XP、skill、Hotbar 系统。
- 用 placeholder 或已有素材先跑通；不要等待最终素材才实现逻辑。
- 输出至少 3 个 seed 的 screenshot/debug payload，供用户审查路线感觉。

User / design lead responsibilities:

- 审 3-5 个 seed 的截图。
- 判断路线是否像第一张教学野外图。
- 判断场地宽度、岔路、洞口、边界是否有感觉。
- 决定哪些 seed/layout 方向保留，哪些淘汰。

Seed rejection criteria:

- Camp 出口不清楚：失败。
- 第一批怪离出生点太近：失败。
- First contact 一上来形成围攻或压力怪：失败。
- Dungeon branch 太远、太隐蔽，或看起来只是普通岔路：失败。
- Route 太像蛇形迷宫或硬走廊：失败。
- 空地太大且没有视觉引导：失败。
- Fork 看不出主路和支路区别：失败。
- Next area exit 比 dungeon entrance 更显眼或更像主目标：失败。
- Visual boundary 和 blocker 明显不一致：失败。

禁止项:

- 不要在本任务做第二职业。
- 不要扩完整 skill tree。
- 不要做 dungeon interior。
- 不要做新大型美术替换 pass。
- 不要把第一张图做成手工固定 scene 绕过 generator。

Acceptance:

- 第一张 outdoor map 可以通过 config 使用通用生成器生成。
- 至少 3 个固定 seed 都能生成结构正确、路线不同的第一张图。
- 每个 seed 都包含 camp、first contact、fork、dungeon entrance、elite/pressure point、next exit。
- Camp 是安全区，出生点附近没有立即接敌。
- First contact 是 2-3 个弱怪的教学接触，不是压力战。
- 主路是视觉引导型道路，不是狭窄硬走廊。
- Dungeon entrance branch 明显是核心任务 hook。
- Next area exit 作为 soft gate 存在，但不会抢走 dungeon entrance 的优先级。
- 2-4 分钟内可以形成 first weapon drop 的 kill -> drop -> pick up -> equip -> stronger loop。
- 第一张图能复用已有 combat、loot、equipment、XP、skill、Hotbar 系统。
- P0 素材清单清楚区分“用户/素材 agent 准备”和“task agent 接入”。
- 生成 3-5 个 seed 的截图或 debug overlay，足够让用户按 seed rejection criteria 审路线感觉。
- `tools/smoke_first_outdoor_generated.gd` 必须通过 Godot headless wrapper。
- 完成后在本任务条目下写入 `Task agent status: done`。

Task agent status: done

Task agent report:

- Files read: `TASK_BOARD.md`, `docs/DEMO_SCOPE.md`, `docs/CONTROL_AND_COMBAT.md`, `docs/TASK_019_OUTDOOR_GREYBOX_PLAN.md`, existing `combat_sandbox` / `outdoor_greybox` scene scripts, item/enemy/objective scripts.
- Files changed: `data/maps/first_outdoor_map.json`, `scripts/maps/first_outdoor_generated.gd`, `scenes/maps/first_outdoor_generated.tscn`, `tools/smoke_first_outdoor_generated.gd`, `tools/capture_first_outdoor_seed_view.gd`, `scripts/maps/procedural/map_generator.gd`, `artifacts/first_outdoor_seed_24001_payload.json`, `TASK_BOARD.md`.
- Summary: added first outdoor config and generated scene entry using the Task23 generator; connected existing player, combat, loot pickup/equipment, XP, skill/Hotbar UI, route/objective flow, outdoor props, soft boundaries, dungeon hook, next-area soft gate, and first weapon loop. Props such as rocks, shrine, corrupted hollow, roots, fences, gate, and signposts now create matching `StaticBody2D` blockers with blocker sizes derived from their displayed texture size.
- Validation: `tools/smoke_map_generator_core.gd`, `tools/smoke_first_outdoor_generated.gd`, and `tools/capture_first_outdoor_seed_view.gd` passed through `tools/run_godot.ps1`. Headless capture writes payload-only because the headless renderer does not provide a viewport image.
- Risks: route feel, dungeon branch readability, and next-exit priority still need user/design-lead visual review in an interactive Godot run; smoke validates structure, safety distance, first-contact count, collision pairing, and first weapon pickup/equip loop but cannot fully judge Diablo-like map feel.

## 暂停项

旧 backlog 已从本任务板移除。不是永久取消，而是在第一张半随机 outdoor map 的规格和原型完成前不继续排期；需要恢复时再从历史归档或 git history 里重新评估。

完整历史归档见 [docs/TASK_ARCHIVE.md](docs/TASK_ARCHIVE.md)。

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
