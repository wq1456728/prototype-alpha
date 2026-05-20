# 任务板

这个文件是其他对话或 agent 的任务入口。它只保留当前任务和最近上下文；历史任务、通用规则和长期计划放在独立文档里。

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

`TASK-020` 到 `TASK-022` 的第一版 outdoor greybox 已归档，只保留技术链路参考；旧 greybox 不再作为第一张图继续迭代。

`TASK-023` 到 `TASK-026` 已归档：现在有 seed 可复现的 semi-procedural map core、第一张 outdoor config、per-object footprint collision、连续 boundary pass，以及能显示 `walkable_cells` / `boundary_cells` / `blocked_cells` 的 `Procedural Map Test` overlay。

当前不要先调技能数值，也不要一口气做完整素材。最新结构方向是先修正 world / map 架构：

```text
MainWorld persistent scene
FixedTown child
GeneratedRegion child
same world coordinates
TownExitSocket -> fixed transition chunk -> generated wilderness chunks
```

这一步完成后，再继续 P0 素材盘点、walkable shape、terrain paint、first outdoor playable loop。

完整历史见 [docs/TASK_ARCHIVE.md](docs/TASK_ARCHIVE.md)。

## 当前设计结论

第一张图不采用“AI 一次性设计一张固定地图”的方式。

当前方向是实现一套 Godot 内可运行、seed 可复现的受控随机生成算法，让每次进入第一张图时可以生成不同布局，但仍保持固定的暗黑式关卡骨架。

Camp / base 不走 procedural generator。Camp 是固定区域，价值在于安全区、出生点、NPC / stash / quest 起点、进入第一张 outdoor 的出口。用户可以手动调整营地布局和美术，但工程接口必须先由 agent 搭好。

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

### TASK-027: Camp Scene Contract, Outdoor Transition, And P0 Asset Intake

Status: done

Goal:

建立固定 Camp scene 的工程接口，把它接到第一张 generated outdoor scene，并同步盘点 / 接收当前能拿到的 P0 Camp + outdoor terrain 素材。Camp 第一版不追求最终美术，但必须给用户一个可手动调整的可运行营地底稿，且不能继续完全依赖抽象色块。

Why now:

- Camp 不应该混在 outdoor generator 的 start zone 里。
- Camp 随机价值很低；固定 scene 更适合 NPC、安全区、任务起点、stash、出生点。
- 用户不需要从 0 搭建营地；agent 应先搭一个结构合理的 greybox / rough layout，用户再手动调整空间、美术和氛围。
- Camp 搭建会立刻暴露素材缺口，所以本任务必须从一开始盘点可用素材，并把后续 `TASK-029` 的 P0 素材需求提前纳入视野。
- 如果现在不盘点素材，Camp 和 outdoor terrain 后续会继续被调试方块拖住。

User does:

- 在 agent 搭好的 Camp scene 上手动调整布局、地表、道具摆放和美术氛围。
- 判断营地大小、出口位置、NPC / stash / quest placeholder 的相对位置是否舒服。
- 决定哪些营地素材需要补，哪些 placeholder 可以先接受。
- 从素材网站或素材 agent 拿到优先级最高的 P0 素材，尤其是 road / transition / decal / camp props。
- 告诉 task agent 哪些素材可以作为 accepted gameplay assets，哪些只能留在 raw / reference。
- 不需要从空 scene 开始搭建。

Task agent does:

- 创建或更新 `scenes/maps/camp_scene.tscn`。
- 创建或更新 `scripts/maps/camp_scene.gd`。
- Camp scene 必须使用固定节点契约，后续 agent / smoke 只认这些名字：
  - Root: `CampScene` Node2D。
  - `WorldEntities` Node2D，承载 player / props / interactables。
  - `Ground` Node2D。
  - `Props` Node2D。
  - `NPCPlaceholders` Node2D。
  - `Interactables` Node2D。
  - `CampSpawn` Marker2D。
  - `CampExitToOutdoor` Area2D，必须带 CollisionShape2D。
  - `CampBounds` StaticBody2D 或 Node2D root，下面必须有实际 blocker StaticBody2D / CollisionShape2D。
  - `DebugHelpers` CanvasLayer 或 Node2D，默认隐藏或可关闭。
- 盘点当前可用素材：
  - `assets/sprites/tiles/outdoor_01/`
  - `assets/sprites/props/outdoor_01/`
  - 其他可能可暂用的 accepted gameplay assets。
- 更新 [docs/OUTDOOR_TERRAIN_ASSET_LIST.md](docs/OUTDOOR_TERRAIN_ASSET_LIST.md) 的 current fallback / missing 状态。
- 把已经可用、命名合理、风格可接受的 P0 素材列入 “available now”。
- 把缺失但必须尽快拿到的素材列入 “needed before terrain paint”。
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
- 明确 Camp -> Outdoor transition contract：
  - `CampExitToOutdoor` 是交互 / 触发节点，不写死目标坐标。
  - `CampExitToOutdoor` 必须暴露 `target_scene_path = res://scenes/maps/first_outdoor_generated.tscn` 和 `target_spawn_marker = CampEntranceSpawn`。
  - transition payload 至少包含 `target_scene`、`target_spawn_anchor`、`return_scene`、`return_spawn_anchor`。
  - Outdoor scene 必须暴露 `CampEntranceSpawn` 或同名 anchor；如果 generator 暂时不能直接消费该 anchor，必须用 adapter / spawn override 接入。
  - Outdoor scene 加载后必须读取 `target_spawn_marker`，把玩家放到 marker 附近，不允许用固定坐标或随机 start zone。
- 预留 outdoor 返回 Camp 的接口，即使第一版可以不做完整返回交互：
  - `FirstOutdoorGenerated` 中必须保留 camp-side return marker 或 Area2D placeholder。
  - return placeholder 必须记录 `target_scene_path = res://scenes/maps/camp_scene.tscn` 和 `target_spawn_marker = CampSpawn` 或 `CampReturnSpawn`。
- Outdoor camp entrance 周围必须保留短距离安全缓冲区，玩家刚出 Camp 后不应立刻被怪物包围。
- Camp gate 外应有清晰 road / field direction cue，引导玩家进入 First Contact，而不是让出口直接贴到怪群、封边、dungeon hook、elite pressure 或 next area exit。
- 增加 smoke test，验证 Camp scene 存在、必要节点存在、没有敌人、transition target 可解析。

Collaboration contract:

- Agent 搭结构和接口，用户改视觉和空间。
- 用户调整 scene 时必须保留固定节点名：`CampSpawn`、`CampExitToOutdoor`、`CampBounds`、`Ground`、`Props`、`NPCPlaceholders`、`Interactables`。
- 不使用“等价名字”替代固定节点名；如果确实要改名，必须同步更新本任务条目和 smoke test。
- 如果用户移动出口，agent 后续只根据节点位置读，不写死坐标。
- Camp scene 的视觉布局可以人工调整，但 gameplay contract 以节点和 marker 为准，不以 sprite 坐标或手工截图为准。
- Camp scene 里不放 outdoor encounter，不接怪物生成。
- Asset agent 可以在本任务期间并行生成 P0 素材；task agent 负责把 accepted assets 放入正确目录、命名、登记到清单。
- 本任务允许先用 placeholder 搭 Camp，但不能无视素材盘点；完成报告和 [docs/OUTDOOR_TERRAIN_ASSET_LIST.md](docs/OUTDOOR_TERRAIN_ASSET_LIST.md) 都必须明确哪些素材已有、哪些还缺。

Implementation note:

- TASK-027 不需要等待最终素材，可以先做工程接口和 Camp rough layout。
- 本任务不重做 outdoor map algorithm；允许增加 transition adapter、spawn anchor 读取、scene path 配置和 smoke test。任何会改变 zone / corridor / encounter / boundary 生成逻辑的改动都留到后续任务。
- 当前素材足够搭可运行 Camp greybox：`camp_gate`、`signpost`、`shrine`、`broken_cart`、`rock`、`dead_tree`、`broken_fence`、`corrupted_root` 都可暂用。
- 如果目标参考 Diablo II Act 1 Rogue Encampment 的阅读方式，Camp 美术素材仍缺：营地围栏 / 木桩墙、帐篷 / 布棚、篝火 / 火盆、木桶 / 箱子 / 货物堆、stash chest、waypoint marker、NPC placeholder sprite、营地踩踏泥地 / 灰烬 decal。
- Task agent 第一版只需要把这些缺口以 placeholder 形式留好位置，不要因为缺素材阻塞 Camp transition。
- 同时提前拿 `TASK-029` 的关键素材：`dirt_road_center`、`dirt_road_edge_blend`、`dirt_road_corner_blend`、`grass_to_dirt_transition`、`road_noise_decal`。这些不一定要在 TASK-027 里接入 terrain paint，但应该尽量在本任务期间收集 / 入库 / 标记状态。
- `DebugHelpers` 可以存在，但默认隐藏或可通过同一个 debug toggle 关闭；如果显示 label，不能遮挡玩家出生点、出口碰撞区和主要交互物。

Suggested scene shape:

```text
CampScene
  WorldEntities
  Ground
  Props
  NPCPlaceholders
  Interactables
  CampSpawn
  CampExitToOutdoor
  CampBounds
  DebugHelpers
```

Acceptance:

- `camp_scene.tscn` 可以独立运行。
- 独立运行时必须实例化玩家、相机和基础 HUD；玩家出生在 `CampSpawn`，不依赖从 main scene 注入状态才能移动。
- 玩家从 `CampSpawn` 出生。
- Camp 内没有敌人，也不会触发 outdoor encounter。
- Camp 有明确出口。
- 从 Camp exit 可以进入 `FirstOutdoorGenerated`。
- 进入 first outdoor 后，玩家 global position 接近 `CampEntranceSpawn`，该点处于 walkable area 内，而不是随机地图中部或固定硬编码坐标。
- 从 Camp 进入 outdoor 后，玩家能在 3-5 秒内读到主方向：camp gate、road hint、field opening 或 signpost 至少一种可见。
- Outdoor 入口不能直接连接 dungeon entrance、elite pressure point 或 next area exit；入口后的第一段应服务于 First Contact。
- Camp exit 必须被 outdoor boundary pass 识别为 opening anchor，不允许被 boundary objects 封死。
- Camp 边界能挡住玩家离开可读区域。
- CampBounds 必须使用与 outdoor blocker 一致的 collision layer / mask 约定，且不能挡住 `CampExitToOutdoor` 的交互 / 触发区域。
- `docs/OUTDOOR_TERRAIN_ASSET_LIST.md` 更新为当前真实状态，明确 available / missing / accepted / placeholder。
- `docs/OUTDOOR_TERRAIN_ASSET_LIST.md` 中每个 P0 条目必须至少包含 `status`、`current_path` 或 `current_fallback`、`blocker_for_task_030`、`note`，不得只在完成报告里描述素材状态。
- 完成报告必须包含：
  - Camp 当前使用了哪些已有素材。
  - Outdoor terrain P0 已有哪些素材。
  - Road / transition / decal 还缺哪些素材。
  - 哪些缺口会阻塞 `TASK-031 First Outdoor Terrain Paint Pass`。
- 用户可以直接打开 scene 手动调整，不需要理解大量脚本。
- 新增 `tools/smoke_camp_scene_contract.gd`，并通过 Godot wrapper 运行。
- Smoke test 必须覆盖：scene load、固定节点存在、玩家 spawn、无敌人、玩家移动若干 physics frames 后仍无敌人、CampBounds 四边 physics 阻挡、CampExitToOutdoor target scene 可 load、outdoor target spawn marker 存在、transition 后 player global position 接近 outdoor camp entrance anchor。
- 完成后在本任务条目下写入 `Task agent status: done`。

禁止项:

- 不做最终营地美术 polish。
- 不做完整 NPC 对话系统。
- 不做商店、仓库完整功能。
- 不把 Camp 继续塞进 procedural generator。
- 不改第一张 outdoor 的地图算法。
- 不做完整 terrain paint 实现。
- 不调技能、数值、掉落平衡。

Task agent status: done

Task agent report:

```text
Task:
TASK-027 Camp Scene Contract, Outdoor Transition, And P0 Asset Intake

Status:
done

Files read:
- scenes/maps/first_outdoor_generated.tscn
- scenes/maps/combat_sandbox.tscn
- scenes/player/knight_player.tscn
- scripts/maps/first_outdoor_generated.gd
- scripts/maps/combat_sandbox.gd
- scripts/player/knight_player.gd
- scripts/physics/outdoor_collision.gd
- scripts/physics/collision_layers.gd
- docs/OUTDOOR_TERRAIN_ASSET_LIST.md
- data/maps/map_object_defs.json

Files changed:
- scenes/maps/camp_scene.tscn
- scripts/maps/camp_scene.gd
- scripts/maps/first_outdoor_generated.gd
- tools/smoke_camp_scene_contract.gd
- docs/OUTDOOR_TERRAIN_ASSET_LIST.md
- project.godot
- TASK_BOARD.md

Summary:
- Added a fixed `CampScene` with `CampSpawn`, `CampExitToOutdoor`, `CampBounds`, `Ground`, `Props`, `NPCPlaceholders`, `Interactables`, and reusable placeholder layout.
- Reused current accepted outdoor props for Camp rough layout: camp gate, signpost, shrine, broken cart, rock, dead tree, and broken fence.
- Added `CampScene` script with player collision initialization, camera limits, exit trigger, transition target path, target spawn anchor, return scene anchor, and transition payload.
- Set project main scene to `res://scenes/maps/camp_scene.tscn`.
- Added outdoor contract anchors `CampEntrance` and `CampEntranceSpawn`; `FirstOutdoorGenerated` now exposes `get_camp_entrance_position()` and `get_camp_return_target_path()`.
- Added `tools/smoke_camp_scene_contract.gd` covering scene load, fixed nodes, player spawn, no enemies, physics frames with no enemies, CampBounds blocking, transition payload, target scene loading, outdoor camp spawn marker, and player placement after transition.
- Updated `docs/OUTDOOR_TERRAIN_ASSET_LIST.md` with TASK-027 P0 audit fields: status, current path / fallback, blocker_for_task_030, and note.

Findings:
- Camp contract can proceed without final Camp art.
- Boundary / landmark props are enough for P0 rough layout.
- Terrain paint is still blocked by missing road / transition / decal assets: dirt road center, road edge, road corner, grass-to-dirt transition, dirt-to-corruption transition, corruption edge blend, road noise decal, root stain / crack decal, and camp trampled ground decal.
- Camp identity is still visually placeholder-heavy because tent, campfire, stash chest, waypoint marker, palisade wall, crate/barrel stack, and NPC placeholder sprite are missing.

Verification:
- `powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 --headless --path . --script res://tools/smoke_camp_scene_contract.gd` PASS
- `powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 --headless --path . --script res://tools/smoke_first_outdoor_generated.gd` PASS
- `powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 --headless --path . --script res://tools/smoke_map_generator_core.gd` PASS

Risks:
- `smoke_first_outdoor_generated.gd` still prints the existing Godot exit resource warning after PASS.
- Camp visuals are intentionally rough; final Rogue Encampment-like feel depends on the missing Camp support assets.
- Actual transition state payload is exposed as contract data, but there is not yet a general scene transition manager.

Recommended next task:
TASK-028 Outdoor Terrain Vocabulary Freeze And Missing Asset Follow-up
```

User review / superseded direction:

- 2026-05-21 用户复审：旧 `CampScene -> FirstOutdoorGenerated` 的传统 scene switching 方向不符合目标。
- 新方向：采用 persistent `MainWorld`，其中 `FixedTown` 和 `GeneratedRegion` 同时存在于同一个 world space。
- 玩家离开基地后，回头仍应能看到基地；不要 teleport 到另一张地图。
- `TASK-027` 产出的 camp rough layout、素材盘点、节点契约和 smoke 仍有参考价值，但 world flow 需要由 `TASK-028` 重构。
- `TASK-028` 是当前最高优先级；原 terrain vocabulary follow-up 顺延为 `TASK-029`。

### TASK-028: Persistent MainWorld, FixedTown, And GeneratedRegion Contract

Status: done

Goal:

重构当前 world / map 结构，采用 persistent `MainWorld`，让 fixed town 和 generated wilderness 在同一个 world 坐标系中连续存在。不要继续用 `camp_scene.tscn -> first_outdoor_generated.tscn` 的传统切场景作为主流程。

Inputs:

- 必读 [docs/WORLD_STRUCTURE.md](docs/WORLD_STRUCTURE.md)。
- 必读 `scenes/maps/camp_scene.tscn` 和 `scripts/maps/camp_scene.gd`，只作为 fixed town rough layout / placeholder source。
- 必读 `scenes/maps/first_outdoor_generated.tscn` 和 `scripts/maps/first_outdoor_generated.gd`，只作为 generated region implementation source。
- 必读 `scripts/maps/procedural/map_generator.gd`、`generated_boundary_pass.gd`、`procedural_map_test.gd`。
- 必读 [docs/OUTDOOR_TERRAIN_ASSET_LIST.md](docs/OUTDOOR_TERRAIN_ASSET_LIST.md)。

Core structure:

```text
MainWorld
  Player
  Camera2D
  FixedTown
  GeneratedRegion
```

Required direction:

- Town / Base 是固定区域，不走 procedural generator。
- Wilderness 从 Town 出口附近开始动态生成 / instantiate。
- Town 和 Wilderness 必须在同一个 world space。
- 玩家从 Town 走出去后，回头仍然能看到 Town。
- 靠近 Town 的区域半固定，用于保持视觉连续。
- 离 Town 越远，随机性越强。
- 第一版可以在 MainWorld 初始化时一次性生成 wilderness chunks，不要求运行时无限 streaming。

Task agent does:

- 新建或重构 `scenes/world/main_world.tscn`。
- 新建或重构 `scripts/world/main_world.gd`。
- 把 `camp_scene` 的可用结构收束成 `FixedTown` child，不再作为主流程切换目标。
- 把 first outdoor generation 收束成 `GeneratedRegion` child，不再作为主流程切换目标 scene。
- 建立 `TownExitSocket` / `WildernessStartSocket` 或等价固定 anchor。
- 建立 fixed transition chunk，连接 Town 出口和 wilderness entry。
- 第一版 chunks 可以是 rough `.tscn` 或 generated Node2D，但必须有 socket / anchor contract。
- 保留 player、camera、HUD 的稳定父级，不因离开 Town 销毁重建。
- 保留 `Procedural Map Test` 作为 debug viewer，不把它当 main world。
- 增加 smoke，验证 MainWorld 可以加载、Town 和 GeneratedRegion 同时存在、玩家能从 Town 出口走向 generated region、Town 仍在同一坐标系可见范围内。

Chunk contract:

```text
ChunkRoot
  NorthSocket / EastSocket / SouthSocket / WestSocket 或任务内缩小后的 socket set
  GameplayBounds
  SpawnMarkers
  PropMarkers
```

第一版不要求所有方向 socket 都实现，但必须有可测试的 entry / exit socket。

Acceptance:

- `MainWorld` 是新的 playable world entry candidate。
- `FixedTown` 和 `GeneratedRegion` 同时存在于同一个 scene tree 和 world coordinate space。
- 不使用 `change_scene_to_file()` 或等价 scene switching 从 Town 进入 Wilderness 作为主流程。
- 不 teleport 玩家到另一个 map scene。
- 玩家从 Town 出口移动到 wilderness entry 时，Town 不被卸载。
- `FixedTown` 出口附近有 fixed transition chunk。
- `GeneratedRegion` 从 fixed socket / anchor 开始布局。
- 旧 `camp_scene` 可以保留为 source / prefab / reference，但不能再是主流程入口。
- 旧 `first_outdoor_generated` 可以保留为 generator implementation source，但不能再假设自己独占整张地图 scene。
- Smoke test 覆盖 MainWorld load、FixedTown exists、GeneratedRegion exists、TownExitSocket exists、generated start anchor exists、player parent remains stable、no scene switch call needed。
- 完成后在本任务条目下写入 `Task agent status: done`。

禁止项:

- 不做无限开放世界 streaming。
- 不做复杂 chunk unload / reload。
- 不重写 combat、loot、inventory、skill。
- 不调技能数值。
- 不做完整 terrain paint。
- 不为了这个重构删除已可用的 generator / overlay debug 工具。

Task agent status: done

Task agent report:

```text
Task:
TASK-028 Persistent MainWorld, FixedTown, And GeneratedRegion Contract

Status:
done

Files read:
- docs/WORLD_STRUCTURE.md
- TASK_BOARD.md
- docs/OUTDOOR_TERRAIN_ASSET_LIST.md
- scenes/maps/camp_scene.tscn
- scripts/maps/camp_scene.gd
- scenes/maps/first_outdoor_generated.tscn
- scripts/maps/first_outdoor_generated.gd
- scripts/maps/procedural/map_generator.gd
- scripts/maps/procedural/generated_boundary_pass.gd
- scripts/maps/procedural/procedural_map_test.gd
- scenes/enemy/mummy_enemy.tscn
- scripts/enemy/mummy_enemy.gd
- assets/sprites/enemies/*

Files changed:
- scenes/world/main_world.tscn
- scripts/world/main_world.gd
- tools/smoke_main_world_contract.gd
- project.godot
- scripts/enemy/mummy_enemy.gd
- scripts/maps/first_outdoor_generated.gd
- data/maps/first_outdoor_map.json
- TASK_BOARD.md

Summary:
- Added persistent `MainWorld` playable entry candidate.
- `MainWorld` keeps `FixedTown` and `GeneratedRegion` in one scene tree and one world coordinate space.
- `FixedTown` is built as a fixed safe area with `TownSpawn`, `TownBounds`, `TownExitSocket`, `Props`, `NPCPlaceholders`, and `Interactables`.
- `GeneratedRegion` reuses the existing first outdoor generation implementation but no longer needs to be entered by `change_scene_to_file()` as the main flow.
- Added `TransitionChunk` with `NorthSocket`, `SouthSocket`, `WildernessStartSocket`, and `GameplayBounds` connecting Town exit to the generated camp-side anchor.
- Project main scene now points to `res://scenes/world/main_world.tscn`.
- Existing `camp_scene` remains as a sample / source scene from TASK-027, not the new main flow.
- Enemy script now supports configurable `sprite_root`, `sprite_file_prefix`, and `enemy_display_name`.
- First outdoor enemy pools now use three existing enemy visual types: Mummy, Snake, and Hyena.

Findings:
- The existing enemy sprite library is enough for 2-3 monster types in the first outdoor map; no new monster art was needed.
- Terrain road / transition / decal assets are still not generated in this task because TASK-028 explicitly does not implement terrain paint; that work remains in TASK-029 / TASK-031.
- MainWorld currently builds wilderness once at startup, matching the task scope; no streaming or chunk unloading was added.

Verification:
- `powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 --headless --path . --script res://tools/smoke_main_world_contract.gd` PASS
- `powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 --headless --path . --script res://tools/smoke_first_outdoor_generated.gd` PASS
- `powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 --headless --path . --script res://tools/smoke_camp_scene_contract.gd` PASS
- `powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 --headless --path . --script res://tools/smoke_map_generator_core.gd` PASS

Risks:
- `MainWorld` currently reuses the first outdoor implementation by inheritance; this is pragmatic for the contract, but later tasks may want to extract reusable generated-region builders.
- Town visual quality is still placeholder-heavy.
- Road / transition / decal assets are still missing for terrain paint, so visual road quality remains a TASK-029 / TASK-031 blocker.
- Existing Godot exit resource warning still appears after `smoke_first_outdoor_generated.gd` PASS.

Recommended next task:
TASK-029 Outdoor Terrain Vocabulary Freeze And Missing Asset Follow-up
```

### TASK-029: Outdoor Terrain Vocabulary Freeze And Missing Asset Follow-up

Status: todo

Goal:

在 `TASK-027` 的素材盘点和 `TASK-028` 的 world structure 修正基础上，冻结第一张 outdoor map 的 P0 terrain vocabulary，并补齐仍缺的 P0 road / transition / decal 素材。这个任务仍不做 terrain paint 实现，但要让后续 `TASK-031` 不再因为素材不清楚而阻塞。

Definition:

冻结 P0 terrain vocabulary 的含义是：确定 terrain / road / transition / decal / boundary / landmark 的 ID、文件命名、尺寸、透明背景要求、用途、状态、fallback、后续 terrain paint 输入名。冻结不代表素材最终美术完成。

Why now:

- 当前 corridor 看起来像黄色大方块，不像暗黑式小路。
- 当前地面缺少草地、泥路、边缘过渡、腐化 patch 和噪声变化。
- 仅靠算法改 walkable shape，地图仍然会像 debug block。
- `TASK-027` 已做第一轮素材盘点，本任务负责把缺口收束、冻结命名和交付状态。
- `TASK-028` 会改变 world / map 结构，本任务需要确保 terrain vocabulary 能用于 `GeneratedRegion` / chunk layout，而不是旧独立 scene。

User does:

- 重点审查 `TASK-027` 盘点后的缺口。
- 优先生成 / 筛选 road、transition、decal，而不是继续扩怪物或边界 props。
- 对素材质量做主观选择：哪些地面过渡自然、哪些道路太亮、哪些边界素材太卡通。
- 把原始素材放到 raw 区，接受的素材按项目命名规则交给 agent 整理。

Asset agent does:

- 按 P0 清单生成或整理素材。
- 优先保证风格统一、视角统一、尺寸统一、透明背景正确。
- 不自由扩充大量 P1/P2 内容；第一轮每类最多 2 个 variation。
- 交付时标注每个素材对应清单条目。

Task agent does:

- 基于 `TASK-027` 的盘点结果，最终冻结 [docs/OUTDOOR_TERRAIN_ASSET_LIST.md](docs/OUTDOOR_TERRAIN_ASSET_LIST.md)。
- TASK-029 开始前必须读取 TASK-027 完成报告、TASK-028 完成报告和 `docs/OUTDOOR_TERRAIN_ASSET_LIST.md` 当前状态；如果清单状态不可信，本任务第一步是修正清单状态，不得直接重新定义一套 vocabulary。
- 检查当前 `assets/sprites/tiles/outdoor_01/` 和 `assets/sprites/props/outdoor_01/` 已有素材，标记哪些 accepted、哪些 placeholder、哪些 missing。
- 明确 P0 素材的建议尺寸、文件命名、用途和是否需要透明背景。
- P0 / P1 清单每个条目必须包含这些列：`ID`、`Priority`、`Use case`、`Asset type`、`Required form`、`Size`、`Transparency`、`Naming pattern`、`Current path`、`Fallback path`、`Status`、`Blocks TASK-031`、`Owner / next action`。
- 为每个 P0 terrain 条目标注后续 terrain paint 使用场景：base fill、visual road center、road edge blend、road corner / turn、road end / fade、local corruption patch、soft transition overlay、noise decal、boundary / landmark prop。
- 清单里的 ID 必须能直接映射到后续 terrain paint 规则，不允许只写主观描述。
- `accepted` 只能表示用户确认可作为当前阶段 gameplay asset；agent 自行判断只能标记为 `available` 或 `placeholder`，不得把新发现或新导入素材直接标为 `accepted`。
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
- dirt road center straight
- dirt road soft edge north / south / east / west 或等价 autotile edge
- dirt road corner / turn blend
- dirt road end / fade piece
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

Implementation note:

- 当前 outdoor props 足够做 P0 封边和 landmark：small rock、dead tree、broken fence、corrupted root、camp gate、dungeon entrance、shrine、signpost、broken cart 都已有可暂用素材。
- 主要缺口不是怪物或边界物，而是 terrain vocabulary：road、transition、patch、decal。
- 最高优先级补素材：`dirt_road_center`、`dirt_road_edge_blend`、`dirt_road_corner_blend`、`grass_to_dirt_transition`、`road_noise_decal`。
- 第二优先级补素材：`root_stain_decal`、`dark_crack_decal`、`thorn_weed_decal`、`dead_bush`、更多 dead grass / dry dirt / trampled mud variation。
- Camp 相关素材可以记录在清单里，但不要让它们阻塞 outdoor terrain vocabulary；Camp 的工程接口已由 TASK-027 负责。
- Terrain paint 的关键风险：如果没有 road + transition + decal，后续算法即使形状正确，画面仍会像色块拼接，不会接近暗黑式野外。
- Road / transition / corruption 素材不得使用高饱和黄色、亮紫色、现代铺装、卡通草坪、硬矩形边缘或明显重复图案。
- 地面素材应保持低对比，避免抢过 monster、loot、interactable 的阅读优先级。
- Decal 用于打散重复感，不应成为新的大块主地形。
- 第一轮 variation 限制按 ID 计算：每个 P0 ID 最多 1-2 个 accepted variation；多余 variation 放 raw / reference，不进入 `assets/sprites/...` accepted path；文件名必须带 `_a` / `_b` 或清单指定后缀。

Acceptance:

- `docs/OUTDOOR_TERRAIN_ASSET_LIST.md` 包含 P0 / P1 分级，并反映 `TASK-027` 后的真实素材状态。
- `docs/OUTDOOR_TERRAIN_ASSET_LIST.md` 的每个 P0 / P1 条目都包含 `ID`、`Priority`、`Use case`、`Asset type`、`Required form`、`Size`、`Transparency`、`Naming pattern`、`Current path`、`Fallback path`、`Status`、`Blocks TASK-031`、`Owner / next action`。
- P0 每个条目都有用途、建议尺寸、透明背景要求、命名建议、是否已有可暂用素材。
- P0 每个条目必须标注 `available`、`placeholder`、`missing` 或 `accepted`。
- 最高优先级 P0：`dirt_road_center`、`dirt_road_edge_blend`、`dirt_road_corner_blend`、`grass_to_dirt_transition`、`road_noise_decal` 必须全部为 `accepted` 或至少 `available`；否则必须有用户明确批准继续保持 `missing` / `placeholder`，并在清单中标注 `Blocks TASK-031 = yes`。没有用户批准时，不得在这些关键素材仍 missing 的情况下把 TASK-029 标为 done。
- 所有标为 `available` 或 `accepted` 的素材必须有可解析项目路径；`accepted` 不允许指向 raw / reference 目录。
- 明确 `tileset sheet` 和单张 PNG 的交付区别：
  - terrain tile 优先 tileset sheet 或同尺寸 tile group。
  - props / landmarks 优先透明背景单张 PNG。
  - decals 优先透明背景单张 PNG。
- 冻结后的清单必须给 TASK-031 留出接入信息：
  - terrain base / road / transition 是否属于 TileMap tileset sheet。
  - 如果是 sheet，写明 32px grid、tile index 或区域说明。
  - 如果是 overlay decal，写明推荐放置层级和是否可随机旋转 / 翻转。
  - 如果只是 placeholder，写明不能用于最终 paint 的原因。
- 第一轮 variation 控制在每类 1-2 个，不追求一次性铺满内容。
- 清单足够让素材 agent 直接开始生成，不需要重新追问“到底要什么”。
- 新增或更新 asset inventory smoke / lint，验证所有标为 `available` 或 `accepted` 的素材：路径存在、Godot 可加载或 `.import` 存在、PNG 尺寸符合清单声明、decals / props / landmarks 有透明背景、terrain base tile 不要求透明。
- Terrain base 和 road tile 至少需要用 3x3 或更大重复预览检查明显接缝；transparent decal / prop 必须确认背景透明且没有白边 / 黑边脏像素。
- Godot 导入设置必须适合 pixel art，避免 filtering 导致地面发糊。
- 清单必须支持“宽 walkable field + 窄 visual road”的表达，而不是只支持 corridor 全宽铺路。
- 清单必须支持 road 断续、偏移、变窄、消失到草地里的情况。
- 清单必须支持 corruption 作为局部侵蚀 patch / decal 出现，而不是整块矩形地表替换。
- 清单必须区分 gameplay boundary props 和 decorative props；boundary props 后续需要 collision / footprint，decorative decals 不应阻挡玩家。
- 完成报告必须列出 TASK-031 最小可视化组合：base ground、road center、road edge、corner / turn、road end / fade、grass_to_dirt、road_noise。
- 如果关键 road / transition 仍 missing，完成报告必须写明 debug viewer 仍只能验证 layout / walkable，不能验收最终地表可读性。
- 完成后在本任务条目下写入 `Task agent status: done`。

禁止项:

- 不要求一次性生成全部 P1/P2 素材。
- 不做 terrain paint 实现。
- 不重做地图算法。
- 不调技能、数值、掉落平衡。
- 不把临时素材直接视为最终素材。
- 不把 terrain vocabulary 扩成完整 Act 1 美术库。
- 不因为缺少某个完美 tileset 而推迟冻结 P0 命名和状态。
- 不把视觉 road 当成唯一可走路径。

Task agent status: not started

### TASK-027 / TASK-028 / TASK-029 Shared Diablo-Like Outdoor Gate

这两项完成时，审查重点不是“像素素材是否最终漂亮”，而是第一张 outdoor 的工程契约和视觉词汇是否支持暗黑式可读野外：

- Camp 是安全、固定、可返回的起点，不是 procedural generator 里的 start zone。
- Outdoor 是一整片可读野外，不是一串房间 / 走廊。
- Road 负责视觉引导，不等于碰撞路径，也不等于唯一可走路径。
- First Contact、Fork、Dungeon Entrance、Optional Reward、Elite Pressure、Next Area Hook 的阅读顺序不能被素材、入口接法或 road 画法破坏。
- Boundary 必须像自然封边，而不是黑 void、硬矩形 blocker 或随机摆件。
- Debug viewer / smoke 负责证明 contract 和数据正确；最终视觉舒服程度仍需要用户打开 scene 做人工判断。

## 后续建议顺序

```text
TASK-028 Persistent MainWorld, FixedTown, And GeneratedRegion Contract
TASK-029 Outdoor Terrain Vocabulary Freeze And Missing Asset Follow-up
TASK-030 Outdoor Walkable Shape Model
TASK-031 First Outdoor Terrain Paint Pass
TASK-032 First Outdoor Layout And Pacing Pass
TASK-033 First Outdoor Playable Loop Pass
TASK-034 Dungeon Entrance Contract And Transition
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
