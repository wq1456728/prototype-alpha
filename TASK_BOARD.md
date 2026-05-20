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
- [docs/OUTDOOR_TERRAIN_ASSET_LIST.md](docs/OUTDOOR_TERRAIN_ASSET_LIST.md)
- [docs/AGENT_RULES.md](docs/AGENT_RULES.md)
- [docs/TASK_ARCHIVE.md](docs/TASK_ARCHIVE.md)
- [ASSET_PROMPT_TEMPLATE.md](ASSET_PROMPT_TEMPLATE.md)

如果旧笔记和上面文件冲突，以上面文件为准。

## 当前阶段

`combat_sandbox` 的纵向系统链路已经跑通：combat、loot、inventory/equipment、XP/level、skill unlock、Hotbar assignment、objective completion 都已有第一版。

`TASK-020` 到 `TASK-022` 的第一版 outdoor greybox 已归档，只保留技术链路参考；旧 greybox 不再作为第一张图继续迭代。

`TASK-023` 到 `TASK-026` 已归档：现在有 seed 可复现的 semi-procedural map core、第一张 outdoor config、per-object footprint collision、连续 boundary pass，以及能显示 `walkable_cells` / `boundary_cells` / `blocked_cells` 的 `Procedural Map Test` overlay。

当前不要先调技能数值，也不要一口气做完整素材。接下来先把两个接口定住：

```text
固定 Camp scene 怎么接 generated outdoor
P0 outdoor terrain / road / transition 素材词汇表是什么
```

这两个定住以后，再进入 walkable shape、terrain paint、first outdoor playable loop。

完整历史见 [docs/TASK_ARCHIVE.md](docs/TASK_ARCHIVE.md)。

## 当前设计结论

第一张图不采用“AI 一次性设计一张固定地图”的方式。

当前方向是实现一套 Godot 内可运行、seed 可复现的受控随机生成算法，让每次进入第一张图时可以生成不同布局，但仍保持固定的暗黑式关卡骨架。

Camp / base 不走 procedural generator。Camp 是固定 scene，价值在于安全区、出生点、NPC / stash / quest 起点、进入第一张 outdoor 的出口。用户可以手动调整营地布局和美术，但工程接口必须先由 agent 搭好。

第一张 outdoor map 仍然走 generated scene。Generator 内部可以用 zone / corridor 控节奏，但玩家看到的应该是一整片可读的野外区域，不是调试方块。

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

### TASK-027: Camp Scene Contract And Outdoor Transition

Status: todo

Goal:

建立固定 Camp scene 的工程接口，并把它接到第一张 generated outdoor scene。Camp 第一版不追求最终美术，但必须给用户一个可手动调整的可运行营地底稿。

Why now:

- Camp 不应该混在 outdoor generator 的 start zone 里。
- Camp 随机价值很低；固定 scene 更适合 NPC、安全区、任务起点、stash、出生点。
- 用户不需要从 0 搭建营地；agent 应先搭一个结构合理的 greybox / rough layout，用户再手动调整空间、美术和氛围。

User does:

- 在 agent 搭好的 Camp scene 上手动调整布局、地表、道具摆放和美术氛围。
- 判断营地大小、出口位置、NPC / stash / quest placeholder 的相对位置是否舒服。
- 决定哪些营地素材需要补，哪些 placeholder 可以先接受。
- 不需要从空 scene 开始搭建。

Task agent does:

- 创建或更新 `scenes/maps/camp_scene.tscn`。
- 创建或更新 `scripts/maps/camp_scene.gd`。
- 搭一个可运行的 Camp greybox / rough layout，包括：
  - `CampSpawn`
  - `CampExitToOutdoor`
  - 安全区边界 collision
  - camp gate / exit marker placeholder
  - stash placeholder
  - NPC / quest giver placeholder
  - optional waypoint / return marker placeholder
- 把 Camp exit 接到 `scenes/maps/first_outdoor_generated.tscn`。
- 进入 outdoor 后，玩家应出生在 outdoor 的 camp entrance / camp spawn 对应位置。
- 预留 outdoor 返回 Camp 的接口，即使第一版可以不做完整返回交互。
- 增加 smoke test，验证 Camp scene 存在、必要节点存在、没有敌人、transition target 可解析。

Collaboration contract:

- Agent 搭结构和接口，用户改视觉和空间。
- 用户调整 scene 时必须保留节点名：`CampSpawn`、`CampExitToOutdoor`、`CampBounds` 或任务内最终约定的等价名字。
- 如果用户移动出口，agent 后续只根据节点位置读，不写死坐标。
- Camp scene 里不放 outdoor encounter，不接怪物生成。

Suggested scene shape:

```text
CampScene
  CampBounds
  Ground
  Props
  NPCPlaceholders
  Interactables
  CampSpawn
  CampExitToOutdoor
  DebugLabels 或可关闭 helper
```

Acceptance:

- `camp_scene.tscn` 可以独立运行。
- 玩家从 `CampSpawn` 出生。
- Camp 内没有敌人，也不会触发 outdoor encounter。
- Camp 有明确出口。
- 从 Camp exit 可以进入 `FirstOutdoorGenerated`。
- 进入 first outdoor 后，玩家出现在 camp-side entrance，而不是随机地图中部。
- Camp 边界能挡住玩家离开可读区域。
- 用户可以直接打开 scene 手动调整，不需要理解大量脚本。
- Smoke test 通过。
- 完成后在本任务条目下写入 `Task agent status: done`。

禁止项:

- 不做最终营地美术 polish。
- 不做完整 NPC 对话系统。
- 不做商店、仓库完整功能。
- 不把 Camp 继续塞进 procedural generator。
- 不改第一张 outdoor 的地图算法。
- 不调技能、数值、掉落平衡。

Task agent status: not started

### TASK-028: Outdoor Terrain Vocabulary And P0 Asset List

Status: todo

Goal:

冻结第一张 outdoor map 的 P0 地表、道路、过渡、边界和装饰素材清单，让用户 / 素材 agent 有明确生成目标。这个任务不要求立刻把所有素材接进地图，但必须让后续 terrain paint 不再继续使用调试方块。

Why now:

- 当前 corridor 看起来像黄色大方块，不像暗黑式小路。
- 当前地面缺少草地、泥路、边缘过渡、腐化 patch 和噪声变化。
- 仅靠算法改 walkable shape，地图仍然会像 debug block。
- 需要先定义 art vocabulary，再做 walkable shape 和 terrain paint。

User does:

- 根据 [docs/OUTDOOR_TERRAIN_ASSET_LIST.md](docs/OUTDOOR_TERRAIN_ASSET_LIST.md) 判断 P0 清单是否符合想要的暗黑式第一张 outdoor 氛围。
- 使用素材网站或素材 agent 生成 / 筛选 P0 素材。
- 对素材质量做主观选择：哪些地面过渡自然、哪些道路太亮、哪些边界素材太卡通。
- 把原始素材放到 raw 区，接受的素材按项目命名规则交给 agent 整理。

Asset agent does:

- 按 P0 清单生成或整理素材。
- 优先保证风格统一、视角统一、尺寸统一、透明背景正确。
- 不自由扩充大量 P1/P2 内容；第一轮每类最多 2 个 variation。
- 交付时标注每个素材对应清单条目。

Task agent does:

- 创建或更新 [docs/OUTDOOR_TERRAIN_ASSET_LIST.md](docs/OUTDOOR_TERRAIN_ASSET_LIST.md)。
- 检查当前 `assets/sprites/tiles/outdoor_01/` 和 `assets/sprites/props/outdoor_01/` 已有素材，标记哪些可暂用、哪些缺失。
- 明确 P0 素材的建议尺寸、文件命名、用途和是否需要透明背景。
- 明确 terrain paint 的原则：
  - logic corridor 可以宽，visual road 应该窄。
  - walkable 不等于 road；road 只是视觉引导。
  - 地面不要整块纯色铺满，要有 transition / patch / decal。
  - 腐化区域用局部 patch，不要整块矩形。
- 不把这些素材全部接入生成器；接入放到后续 `Terrain Paint Pass`。

P0 asset groups:

```text
Ground base:
- grass / dead grass base tile
- dry dirt base tile
- dark mud or trampled ground base tile

Road:
- dirt road center
- dirt road edge blend
- dirt road corner / turn blend
- small road noise decals

Transitions:
- grass_to_dirt transition
- dirt_to_corrupted transition
- corrupted edge blend

Corruption:
- corrupted ground patch
- root stain / dark crack decal
- small corrupted weed / thorn decal

Boundary:
- small rock
- medium rock
- dead tree
- broken fence
- corrupted root wall

Landmarks:
- camp gate / camp exit marker
- dungeon entrance
- next area blocked sign / scout marker
- shrine or loot marker
```

Acceptance:

- `docs/OUTDOOR_TERRAIN_ASSET_LIST.md` 存在，并包含 P0 / P1 分级。
- P0 每个条目都有用途、建议尺寸、透明背景要求、命名建议、是否已有可暂用素材。
- 明确 `tileset sheet` 和单张 PNG 的交付区别：
  - terrain tile 优先 tileset sheet 或同尺寸 tile group。
  - props / landmarks 优先透明背景单张 PNG。
  - decals 优先透明背景单张 PNG。
- 第一轮 variation 控制在每类 1-2 个，不追求一次性铺满内容。
- 清单足够让素材 agent 直接开始生成，不需要重新追问“到底要什么”。
- 完成后在本任务条目下写入 `Task agent status: done`。

禁止项:

- 不要求一次性生成全部 P1/P2 素材。
- 不做 terrain paint 实现。
- 不重做地图算法。
- 不调技能、数值、掉落平衡。
- 不把临时素材直接视为最终素材。

Task agent status: not started

## 后续建议顺序

```text
TASK-027 Camp Scene Contract And Outdoor Transition
TASK-028 Outdoor Terrain Vocabulary And P0 Asset List
TASK-029 Outdoor Walkable Shape Model
TASK-030 First Outdoor Terrain Paint Pass
TASK-031 First Outdoor Layout And Pacing Pass
TASK-032 First Outdoor Playable Loop Pass
TASK-033 Dungeon Entrance Contract And Transition
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

