# 任务板

这个文件是其他对话或 agent 的任务入口。它只保留当前任务和最近上下文；历史任务、通用规则和长期计划放在独立文档里。

## 必读入口

当前规划、范围和实现规则以这些文件为准：

- [README.md](README.md)
- [docs/PROJECT_PLAN.md](docs/PROJECT_PLAN.md)
- [docs/DEMO_SCOPE.md](docs/DEMO_SCOPE.md)
- [docs/CONTROL_AND_COMBAT.md](docs/CONTROL_AND_COMBAT.md)
- [docs/ART_PIPELINE.md](docs/ART_PIPELINE.md)
- [docs/MAP_OBJECT_AND_BOUNDARY_SPEC.md](docs/MAP_OBJECT_AND_BOUNDARY_SPEC.md)
- [docs/AGENT_RULES.md](docs/AGENT_RULES.md)
- [docs/TASK_ARCHIVE.md](docs/TASK_ARCHIVE.md)
- [ASSET_PROMPT_TEMPLATE.md](ASSET_PROMPT_TEMPLATE.md)

如果旧笔记和上面文件冲突，以上面文件为准。

## 当前阶段

`combat_sandbox` 的纵向系统链路已经跑通：combat、loot、inventory/equipment、XP/level、skill unlock、Hotbar assignment、objective completion 都已有第一版。

`TASK-020` 到 `TASK-022` 的第一版 outdoor greybox 已经归档。它们证明了部分技术链路，但作为“第一张图体验”不合格。

`TASK-023` 已完成半随机地图生成核心。`TASK-024` 已把第一张 outdoor config 接入生成器，并能跑通 player/combat/loot/XP/hotbar loop，但用户复审失败：

- Prop / boundary collision 仍然太像从图片大小推导出来的粗略矩形，缺少 per-object footprint definition。
- 生成区域边缘没有连续封边；大片黑色 void 看起来像未完成地图，而且 void 和 playable area 的关系不清楚。

因此当前下一个任务不是继续扩内容，而是补地图生成的基础表现：object definition、footprint collision、walkable mask 和连续边界。

完整历史见 [docs/TASK_ARCHIVE.md](docs/TASK_ARCHIVE.md)。

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

## 当前任务

### TASK-025: Map Object Definitions And Generated Boundary Pass

Status: done

Goal:

修复 `TASK-024` 用户复审失败项：第一张生成地图必须有 per-object definition、脚底 footprint collision、可走区域 mask、连续封边素材和对应 collision。生成区域边缘必须看起来被树线、石头、栅栏、腐化根须、石墙等素材封住，不能继续像黑底 debug 图。

Inputs:

- 必读 [docs/MAP_OBJECT_AND_BOUNDARY_SPEC.md](docs/MAP_OBJECT_AND_BOUNDARY_SPEC.md)。
- 必读 `data/maps/first_outdoor_map.json`。
- 必读 `scripts/maps/first_outdoor_generated.gd`。
- 必读 `scripts/physics/outdoor_collision.gd`。
- 必读 `scripts/maps/procedural/map_generator.gd` 和 `scripts/maps/procedural/generated_map_layout.gd`。
- 必读 `tools/smoke_first_outdoor_generated.gd`。

Focus:

- 新增 `data/maps/map_object_defs.json` 或等价 object definition catalog。
- 每个 map object / boundary prop 从 object definition 读取：
  - texture path。
  - default scale。
  - sprite offset。
  - y-sort / foot point。
  - collision shape。
  - collision offset。
  - blocks_player。
  - tags。
- 第一版 collision shape 至少支持 `rect`、`circle`、`capsule`。
- `CapsuleShape2D` 第一版只要求支持 `vertical` orientation；横向根须、墙、栅栏优先使用 `rect`。
- Object node 的 position 必须表示 foot point / y-sort point；Sprite2D 用 offset 往上显示。
- 对树、门、洞口等高物体，collision 应按脚底 footprint 配置，不按整张 sprite 像素框配置。
- 不再把 texture size + blocker_ratio 当成主要碰撞规则；它只能作为 fallback，并且 validation 要给 warning。
- 从 zones + corridors 生成 walkable mask / walkable cells。
- 使用明确 `cell_size`，推荐 `64`；如果改成 `96`，必须写入 config / payload。
- 从 walkable mask 外缘生成 boundary cells / boundary segments。
- 沿 boundary cells 连续摆放 boundary objects，例如 tree、rock、broken_fence、corrupted_root、stone_wall placeholder。
- 每个 boundary object 必须有对应 blocker/collision。
- blocked / void 区域必须不可走；黑色 void 不能被当作普通可走背景。
- 第一版可以使用 grid mask，不要求复杂 polygon 或 NavMesh。
- 更新 debug payload，让 audit 能看到 `cell_size`、walkable cells、boundary cells、blocked area、boundary objects、object definitions used。

Required file layout:

- `data/maps/map_object_defs.json`
- `scripts/maps/procedural/map_object_definition.gd` 或等价 loader/factory。
- `scripts/maps/procedural/map_object_factory.gd` 或等价 builder。
- `scripts/maps/procedural/generated_boundary_pass.gd` 或等价 boundary/mask pass。
- 更新 `scripts/maps/first_outdoor_generated.gd`。
- 更新 `scripts/physics/outdoor_collision.gd`，保留可复用 collision helpers。
- 新增或更新 `tools/smoke_first_outdoor_generated.gd`。
- 可新增 `tools/smoke_map_object_definitions.gd`。

Boundary Rules:

- 生成图的边缘不能只靠四个大矩形 blocker。
- Playable area 外缘必须有连续 visual boundary。
- 每个 walkable cell 的外缘相邻 blocked / void cell，必须满足以下二选一：
  - 有 boundary object 覆盖。
  - 属于明确 opening anchor，例如 camp exit、dungeon entrance、next area soft gate。
- 最大连续视觉缺口不能超过 `2` 个 cell。
- 如果缺口超过 `2` 个 cell，validation 必须报错，不只是 warning。
- Visual boundary 可以用重复素材，但不能稀疏到一眼看出黑色 void 直接贴着可走区域。
- 主路两侧可以是 soft boundary，但地图外缘必须封闭。
- Boundary visual 和 collision 必须一一对应。
- 如果 boundary 需要留入口，例如 camp 出口、dungeon entrance、next area soft gate，入口必须是明确 anchor，不是随机缺口。

Object definition minimum examples:

```text
dead_tree -> vertical capsule footprint
rock -> circle footprint
broken_fence -> rect footprint
corrupted_root -> rect or vertical capsule footprint
camp_gate -> bottom rect footprint
dungeon_entrance -> bottom rect footprint
```

Acceptance:

- 每个 placed prop 都能找到 object definition。
- Tree / dead_tree 不再使用整图大矩形碰撞，使用 vertical capsule 或明确配置的小 footprint。
- Rock 使用 circle 或近似圆 footprint。
- Fence / wall 使用 rect footprint。
- Capsule shape 如果出现，必须声明 `orientation`；第一版只接受 `vertical`。
- Object foot point、sprite offset、collision offset 三者分离。
- `WorldEntities` 或 props root 的 y-sort 仍然有效，玩家可以在 prop 前后按 y 轴正确遮挡。
- 生成地图 payload 包含明确 `cell_size`，只能是当前实现选择的单一值。
- 生成地图 payload 包含 walkable mask / boundary cells / blocked area。
- Playable area 外缘有连续 boundary visual coverage。
- 每个 walkable cell 外缘相邻 blocked / void cell，要么有 boundary object，要么属于 opening anchor。
- 最大连续 boundary visual gap 不超过 `2` 个 cell。
- 玩家不能从 zone/corridor 直接走进 void。
- 玩家通路验证可以先用 payload 检查 blocked cells；如果做 physics smoke，则把 player 放到边界附近朝 void 方向移动若干 physics frames，确认不能进入 blocked / void cell。
- 黑色 void 不再作为可走背景贴着路线。
- 不再只有四个外圈大 blocker 负责阻挡。
- `tools/smoke_first_outdoor_generated.gd` 必须更新并通过 Godot headless wrapper。
- 如果新增 `tools/smoke_map_object_definitions.gd`，也必须通过。
- 完成后在本任务条目下写入 `Task agent status: done`。

禁止项:

- 不做第二职业。
- 不做 dungeon interior。
- 不扩完整 quest。
- 不做最终美术 polish。
- 不用手工固定整张图绕过 generator。
- 不用单个巨大 invisible wall 冒充连续封边。

Task agent status: done

Task agent report:

- Files read: `TASK_BOARD.md`, `docs/MAP_OBJECT_AND_BOUNDARY_SPEC.md`, `data/maps/first_outdoor_map.json`, `scripts/maps/first_outdoor_generated.gd`, `scripts/physics/outdoor_collision.gd`, procedural generator/layout scripts, and first outdoor smoke.
- Files changed: `data/maps/map_object_defs.json`, `data/maps/first_outdoor_map.json`, `scripts/maps/procedural/map_object_definition.gd`, `scripts/maps/procedural/map_object_factory.gd`, `scripts/maps/procedural/generated_boundary_pass.gd`, Godot-generated `.uid` files for those scripts, `scripts/maps/first_outdoor_generated.gd`, `scripts/physics/outdoor_collision.gd`, `tools/smoke_first_outdoor_generated.gd`, `tools/smoke_map_object_definitions.gd`, `artifacts/first_outdoor_seed_24001_payload.json`, `TASK_BOARD.md`.
- Summary: added map object definitions with foot-point based sprite offsets and configured `rect` / `circle` / vertical `capsule` collision; replaced texture-ratio prop collision with an object definition factory; added a grid boundary pass that outputs `cell_size`, walkable cells, boundary cells, blocked cells, boundary segments, boundary objects, and object definitions used; first outdoor now uses generated boundary objects and per-object collision rather than sparse debug-style props.
- User extra requirement: boundary materials are declared as a short config list in `boundary_style.material_families`, while the algorithm handles continuous segment placement. The current first outdoor config uses one rock family (`rock_a`, `rock_b`) so the boundary reads as continuous stone rather than random alternating material soup.
- Validation: `tools/smoke_map_object_definitions.gd`, `tools/smoke_first_outdoor_generated.gd`, `tools/smoke_map_generator_core.gd`, and `tools/capture_first_outdoor_seed_view.gd` passed through `tools/run_godot.ps1`.
- Risks: boundary tracing is V1 grid-based and sorted into deterministic segments, not a polished perimeter-following artist pass; it is structurally continuous and reviewable, but visual composition still needs interactive review.

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
