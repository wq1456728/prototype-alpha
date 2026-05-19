# 任务归档

这个文件保存已完成 task 的历史记录。当前任务入口见 [../TASK_BOARD.md](../TASK_BOARD.md)。

归档只保留关键结果、审查结论和验证信息；不要把这里当作当前任务说明。

## TASK-001: Project Audit

Status: done

Task agent status: done

Result:

- 2026-05-16 review completed。
- 确认 runtime flow：`project.godot` -> `scenes/maps/combat_sandbox.tscn` -> `KnightPlayer` + spawned mummy enemies + loot/debug roots。

## TASK-002: Standard Asset Integration And Minimal Structure Stabilization

Status: done

Task agent status: done

Result:

- 当前 sandbox 功能上 OK。
- Active accepted sprites 位于 `assets/sprites/characters/` 和 `assets/sprites/enemies/`。
- 旧 task docs 可能过期；以后以 `TASK_BOARD.md` 和 active scene/script 引用为准。

## TASK-003: Combat Sandbox Plan

Status: done

Task agent status: done

Result:

- `CombatSandbox` 已成为主测试场景。
- Sandbox 有 player、enemy spawn markers、`Enemies`、`Loot` 和 debug label。

## TASK-004: Player Facing Prototype

Status: done

Task agent status: done

Result:

- `KnightPlayer` 有 `move_direction`、`aim_direction`、`facing_direction`、`action_direction`。
- 鼠标攻击时朝向 aim direction，动作恢复后回到 movement-facing。

## TASK-005: Basic Hit Loop

Status: done

Task agent status: done

Result:

- Player attack 使用 delayed hit timing 和 one-hit-per-swing prevention。
- Mummy enemies 可以受伤、flash、knockback/stagger、死亡并清理。

## TASK-006: First Loot And Power Gain

Status: done

Task agent status: done

Result:

- Mummy death drops `DamagePickup`。
- Pickup 调用 `add_damage_bonus`，sandbox damage display 会反映 attack damage 增加。

## TASK-007: Combat Sandbox Feel Pass 1

Status: done

Task agent status: done

Result:

- Player 可以杀死 mummy、生成 damage loot、拾取并提高 attack damage。
- Light player hit timing 和 mummy attack timing 调晚，更匹配 visible active frames。
- Mummy attack lock 覆盖完整可见攻击动画。
- Runtime wrapper validation passed for `scenes/maps/combat_sandbox.tscn`。

## TASK-008: Runtime Smoke Test Script

Status: done

Task agent status: done

Result:

- 添加 narrow CombatSandbox structure smoke test。
- Runtime wrapper validation passed for `tools/smoke_combat_sandbox_structure.gd`。

## TASK-009: Player Combat Feedback Pass

Status: done

Task agent status: done

Result:

- Enemy hit 生成 damage numbers。
- Damage pickup 显示短暂 `Damage +N` pickup message。
- `debug_combat_sandbox.gd` passed；hit feedback spawns，loot pickup raises damage from 24 to 32。

## TASK-010: First SFX Pass

Status: done

Task agent status: done

Result:

- First accepted SFX organized under `assets/audio/sfx/`。
- Light attack、heavy attack、shield strike、enemy hit、enemy death、pickup、movement footsteps 使用不同 accepted SFX names。
- Runtime wrapper validation passed for CombatSandbox debug and smoke scripts。

## TASK-011: Item System Skeleton

Status: done

Task agent status: done

Result:

- Added `data/items/item_definitions.json` with item types、equipment slots、weapon definitions。
- Added `ItemDatabase` loader/lookup helpers。
- Inventory stores item instances；equipment uses generic equipment slots，当前只激活 weapon。
- Equipped stats 通过 `stat_modifiers.damage` 生效。
- Runtime wrapper validation passed for smoke/debug scripts。

## TASK-012: Item Drop Roll And Instance Data v1

Status: done

Task agent status: done

Result:

- Added `data/items/drop_tables.json`。
- Mummy drops 使用 config-backed drop table、rarity weights、rolled damage modifiers。
- Enemy drops call `ItemDatabase.roll_item_instance("mummy_weapon")`。
- Drop sampling reported multiple names、all 3 rarities、varied damage values。

## TASK-013: Inventory And Equipment UI v1

Status: done

Task agent status: done

Result:

- `B` inventory UI covers cursor pickup、bag placement、equip/swap/drop、item details、attack blocking。
- Equipment UI shows reusable slot structure：weapon active，chest/accessory reserved。
- Runtime wrapper validation passed for smoke/debug scripts。

## TASK-014: Progression System Skeleton

Status: done

Task agent status: done

Result:

- Added `data/progression/progression_config.json`。
- Added `ProgressionState` for level、current XP、XP-to-next-level、available skill points。
- Runtime validation confirmed level 1 -> 2，damage 24 -> 27，skill points 0 -> 1。

## TASK-015: Minimal Skill Tree Skeleton

Status: done

Task agent status: done

Result:

- Added `data/skills/knight_skills.json`。
- Added `SkillTreeState` for data-driven definitions、prerequisites、rank state、unlock cost、requirement checks。
- `shield_charge` locked until configured skill is unlocked，then changes combat behavior。
- Runtime validation confirmed shield charge is blocked before unlock and works after unlock。

## TASK-016: Skill Tree Panel And Skill Loadout UI

Status: done

Task agent status: done

Result:

- Skill learning moved out of inventory panel into dedicated `K` skill-tree panel。
- Added `data/skills/skill_loadout_defaults.json`。
- Added `SkillLoadoutState` with slots `LMB`, `RMB`, `Q`, `E`, `R`, `V`。
- `light_attack` is baseline action，not part of skill tree，assigned to `LMB`。
- Learned active skills can be assigned；unlearned and passive skills are rejected。
- Shield Charge can be unlocked、assigned、triggered。

## TASK-017: Sandbox Objective Flow

Status: done

Task agent status: done

Result:

- Added sandbox objective tracker panel。
- Flow guides player through kill mummy、pick up loot、equip weapon、reach level 2、unlock Shield Charge、assign to `V`、use from loadout、defeat `MummyBrute`。
- Objective completion tracked through `get_objective_stage()` and `is_objective_complete()`。
- Runtime validation exercised the complete vertical chain。

## TASK-018: Diablo-like UI Scale, Skill Tree, And Hotbar Rework

Status: done

Task agent status: done

Result:

- 2026-05-17 re-audit: pass with risks。
- Implemented viewport-safe larger Inventory、dedicated Skill Tree、bottom-center Hotbar、Objective panel。
- Set project display defaults to 1280x720 with canvas stretch/expand at the time；later planning changed the primary target resolution to 1920x1080 while keeping 1280x720 as minimum validation。
- Inventory/Equipment UI uses larger slots、icons、labels and viewport-clamped placement。
- Skill Tree rebuilt into separate `K` panel with `heavy_strike -> shield_charge -> shield_training` path。
- `light_attack` remains baseline non-tree action assigned to `LMB`。
- Hotbar assignment flow changed to click slot -> icon picker -> choose learned active skill。
- Runtime validation passed with `tools/smoke_combat_sandbox_structure.gd`、`tools/debug_player_inputs.gd`、`tools/debug_combat_sandbox.gd`。

Risks:

- Skill tree is still vertical prerequisite-card path, not true Diablo II-style icon grid/tree。
- Headless smoke proves bounds/focus/overlap, but not final visual polish。

## TASK-019: First Outdoor Greybox Plan

Status: done

Task agent status: done

Result:

- Added [TASK_019_OUTDOOR_GREYBOX_PLAN.md](TASK_019_OUTDOOR_GREYBOX_PLAN.md)。
- Planned a 5-10 minute outdoor route that translates the sandbox vertical loop into a first-map structure。
- Route: Camp Gate -> Training Verge -> Broken Road -> First Loot Clearing -> Shrine Fork -> Corrupted Hollow Entrance -> Gate Scout / Dungeon Hook。
- Referenced Diablo II Blood Moor / Den of Evil structure: safe camp exit, weak first enemies, readable road, nearby dungeon entrance, soft boundary before next area。
- Referenced Chronicon direction: direct WASD control, pseudo top-down readability, bottom Hotbar, early loot/skill feedback。
- Defined system verification points for item drop, inventory/equip, XP/level, skill unlock, Hotbar assignment, skill use, and dungeon entrance hook。

Risks:

- First outdoor route must stay short; a wide open map would dilute the already proven sandbox loop。
- First weapon drop and XP timing should be reliable enough to guarantee the planned power/skill moments。

## TASK-020: First Outdoor Greybox Implementation

Status: done

Task agent status: done

Audit Status:

- 2026-05-17 audit: pass with risks。
- Outdoor structure smoke、outdoor route debug、combat sandbox smoke、player input debug、combat sandbox debug all pass through `tools/run_godot.ps1`。
- Diablo II comparison: route correctly borrows Blood Moor / Den of Evil teaching logic：safe camp -> weak enemies -> first loot/equip -> level/skill growth -> pressure fight -> dungeon marker。
- Chronicon comparison: route remains WASD / pseudo top-down rather than Diablo II 45-degree movement，which is accepted project direction。
- UI / route audit: 1280x720 validation passes for outdoor and combat sandbox UI。No blocking overlap issue found in automated checks。
- Audit risk: route boundaries are still visual-only；there is no physical camp/road/entrance blocking。Acceptable for TASK-020 greybox，but TASK-021 should add clearer soft boundary and route pressure pass。
- Audit risk: `debug_outdoor_greybox.gd` proves the vertical loop and objective states，but its entrance fight validation is synthetic because it directly starts Shield Charge and kills the encounter。Real feel/pressure still needs manual or stronger simulation pass in TASK-021。

Result:

- Added `scenes/maps/outdoor_greybox.tscn` and `scripts/maps/outdoor_greybox.gd`。
- First outdoor greybox became the current main scene。
- Route contains Camp Gate、Training Verge、Broken Road、First Loot Clearing、Shrine Fork、Corrupted Hollow Entrance。
- Route enemies are grouped as `outdoor_training`、`outdoor_road`、`outdoor_loot`、`outdoor_shrine`、`outdoor_entrance`。
- Route covers training fight、loot fight、XP/skill fight、entrance pressure fight。
- `FirstLootCaptain` drops a real weapon item；the player can pick it up through inventory cursor, equip it, and improve combat stat。
- Route XP reliably brings player to level 2 with enough skill points to learn `heavy_strike` and `shield_charge`。
- Outdoor objective panel guides leaving camp、training fight、weapon equip、level-up、skill unlock、Hotbar picker assignment、using `shield_charge`、entrance fight、and reaching entrance marker。
- Added `tools/smoke_outdoor_greybox_structure.gd` and `tools/debug_outdoor_greybox.gd`。

Validation:

- `tools/run_godot.ps1 --headless --path . --script res://tools/smoke_outdoor_greybox_structure.gd` pass。
- `tools/run_godot.ps1 --headless --path . --script res://tools/debug_outdoor_greybox.gd` pass。
- `tools/run_godot.ps1 --headless --path . --script res://tools/smoke_combat_sandbox_structure.gd` pass。
- `tools/run_godot.ps1 --headless --path . --script res://tools/debug_player_inputs.gd` pass。
- `tools/run_godot.ps1 --headless --path . --script res://tools/debug_combat_sandbox.gd` pass。

Risks:

- Outdoor greybox currently has no physical boundary / collision blocking；route relies on visual road and encounter placement。
- Godot headless debug scripts still show resource leak warnings on exit，but return code is 0 and existing sandbox debug has similar warnings。
- Current version is pre-polish greybox；enemy density、route pacing、entrance pressure、scale and boundary quality need TASK-021。

## TASK-021: Outdoor Playable Experience Rework

Status: failed audit

Task agent status: done

Audit Status:

- 2026-05-18 用户实测复审：`fail`。
- 玩家向上跑会跑出可读地图区域，违反 Acceptance：“Player 不能轻易走出地图外圈”。
- 石子、神庙等地图关键物件都是纯装饰，没有 collision 或 soft blocking，违反 Acceptance：“边界视觉和 collision / soft blocking 一致”。
- 2026-05-17 自动验证覆盖不足：只证明 4 个外圈 `StaticBody2D` 存在，没有证明 route visual boundary、石头、神庙、栅栏、树、腐化根须等 props 与碰撞一致。
- 之前 `pass with risks` 判断过宽，应以后续修复任务处理。

Result:

- Outdoor playable bounds expanded to `2200x2760`。
- Route changed from short straight test corridor to larger sections: camp、training field、broken road、loot clearing、shrine fork、entrance arena。
- Added `OutdoorBoundary` with four outer `StaticBody2D` colliders。
- Player / outdoor enemies enabled boundary collision mask in this scene。
- Added visual boundary props: trees、rocks、fences、corrupted roots。
- Adjusted world scale: player visual scale、camera zoom、enemy display scale、key prop scale。
- Reduced enemy count and spaced encounters out。
- Objective wording became lighter and less checklist-like。
- Generated screenshot: `artifacts/task021_outdoor_1920x1080.png`。

Validation:

- `tools/run_godot.ps1 --headless --path . --script res://tools/smoke_outdoor_greybox_structure.gd` pass。
- `tools/run_godot.ps1 --headless --path . --script res://tools/smoke_outdoor_playable_experience.gd` pass。
- `tools/run_godot.ps1 --headless --path . --script res://tools/debug_outdoor_greybox.gd` pass。
- `tools/run_godot.ps1 --headless --path . --script res://tools/smoke_combat_sandbox_structure.gd` pass。
- `tools/run_godot.ps1 --headless --path . --script res://tools/debug_player_inputs.gd` pass。
- `tools/run_godot.ps1 --headless --path . --script res://tools/debug_combat_sandbox.gd` pass。
- Non-headless capture generated `artifacts/task021_outdoor_1920x1080.png`。

Risks / Required Follow-up:

- Must fix visual boundary and collision / soft blocking consistency before asset polish。
- Must add smoke coverage for “from camp upward cannot leave readable map area”。
- Must add smoke or manual coverage for key boundary props not being directly passable。
- TASK-022 should handle these required fixes before TASK-023 asset integration。

## TASK-022: Outdoor Boundary And Prop Collision Fix

Status: done

Task agent status: done

Result:

- 新增 camp 北侧内部 readable limit blocker，玩家从 camp 向上移动会被挡住，不能跑出可读地图区域。
- 给关键边界 props 增加 `StaticBody2D` blocker：camp gate、camp fences、broken cart、shrine、corrupted hollow、训练区树、路边石头、loot clearing 树/石头、shrine roots、entrance roots、entrance dead trees。
- 当前 outdoor scene 有 25 个 blocker collider，其中 20 个是 key prop blocker。
- 保留 TASK-021 的地图空间、怪物密度、路线节奏和 world scale。
- 新增 `get_prop_blocker_count()`、`get_prop_blocker_rects()`、`get_camp_north_readable_limit_y()`，供 smoke test 验证 visual boundary / collision 对齐。

Validation:

- `tools/run_godot.ps1 --headless --path . --script res://tools/smoke_outdoor_playable_experience.gd` pass；覆盖 camp 向上阻挡、关键 props 不能穿、route marker 仍可走、route spacing、bounds、UI layout。
- `tools/run_godot.ps1 --headless --path . --script res://tools/smoke_outdoor_greybox_structure.gd` pass。
- `tools/run_godot.ps1 --headless --path . --script res://tools/debug_outdoor_greybox.gd` pass；loot -> equip -> level-up -> skill unlock -> Hotbar assignment -> skill use route loop 不回归。
- `tools/run_godot.ps1 --headless --path . --script res://tools/smoke_combat_sandbox_structure.gd` pass。
- `tools/run_godot.ps1 --headless --path . --script res://tools/debug_player_inputs.gd` pass。
- `tools/run_godot.ps1 --headless --path . --script res://tools/debug_combat_sandbox.gd` pass。

Risks / Design Conclusion:

- Prop blocker 使用矩形近似，不是逐像素或精确轮廓；对当时 greybox 阶段足够，但后续正式素材替换时仍需重新对齐。
- 自动测试覆盖关键点位和 route loop，但不能替代长时间手动边界扫图。
- 2026-05-18 设计结论：TASK-020 到 TASK-022 只作为技术链路参考归档；旧 outdoor greybox 不再作为第一张地图继续迭代。后续方向改为第一张 outdoor map 的半随机生成系统。

## TASK-023: Semi-Procedural Map Generator Core

Status: done

Task agent status: done

Audit Status:

- 2026-05-18 审查：`pass with risks`。
- `tools/smoke_map_generator_core.gd` 已通过 Godot wrapper。
- 3 个固定 seed 可生成、可验证、同 seed deterministic、不同 seed 有差异。
- Debug scene 能生成 boundary visuals / blockers。
- 实现方向符合任务要求，只借鉴 Diablo II map payload 的结构感：seed、map id/name、offset/size、objects、collision/blocker data；没有复制 Diablo II 数据、算法或依赖外部 D2 安装。

Result:

- Added seed-reproducible semi-procedural layout core。
- Added external dummy config、logical layout payload、route graph / corridors、required branch / exit anchors、optional pocket。
- Added placeholder map objects / spawn groups、boundary visual / blocker pairs、labeled debug scene builder、structured validation、stable payload hash。
- Core API existed at completion:
  - `MapGenerator.generate(config, seed)`
  - `GeneratedMapLayout.to_payload()`
  - `MapGenerationDebug.validate_layout(layout)`
  - `MapGenerationDebug.build_scene(parent, layout)`

Files changed:

- `data/maps/procedural_dummy_config.json`
- `scripts/maps/procedural/map_generation_config.gd`
- `scripts/maps/procedural/generated_map_layout.gd`
- `scripts/maps/procedural/map_generator.gd`
- `scripts/maps/procedural/map_generation_debug.gd`
- `scripts/maps/procedural/procedural_map_test.gd`
- `scenes/maps/procedural_map_test.tscn`
- `tools/smoke_map_generator_core.gd`

Validation:

- `powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 --headless --path . --script res://tools/smoke_map_generator_core.gd` passed。

Risks:

- V1 reachability intentionally validates graph/corridor overlap only; real player navigation remains for later tasks。
- Boundary at completion was still outer rectangle blocker pairs, not complete collision map / tile mask。

## TASK-024: First Outdoor Map Config And Asset Hookup

Status: done

Task agent status: done

Audit / User Review:

- 2026-05-19 用户复审：`fail for visual boundary / collision model`。
- 第一张 outdoor config 和 generated scene 能跑，但生成图仍然像 debug layout：zone/corridor 外有大面积黑色 void，边缘没有连续封闭素材。
- Prop collision 仍然主要从 texture size / source ratio 推导，不是每个 object 自己声明 footprint、y-sort point 和 collision shape。
- 结论：不能继续扩地牢、任务、职业或更多内容；必须先做 `TASK-025`。

Result:

- Added `data/maps/first_outdoor_map.json`。
- Added `scenes/maps/first_outdoor_generated.tscn` and `scripts/maps/first_outdoor_generated.gd`。
- First outdoor map uses TASK-023 generator and first outdoor config。
- Connected existing player、combat、loot pickup/equipment、XP、skill/Hotbar UI、route/objective flow、outdoor props、soft boundaries、dungeon hook、next-area soft gate、and first weapon loop。
- Added smoke and capture tools for generated first outdoor map。

Files changed:

- `data/maps/first_outdoor_map.json`
- `scripts/maps/first_outdoor_generated.gd`
- `scenes/maps/first_outdoor_generated.tscn`
- `tools/smoke_first_outdoor_generated.gd`
- `tools/capture_first_outdoor_seed_view.gd`
- `scripts/maps/procedural/map_generator.gd`
- `artifacts/first_outdoor_seed_24001_payload.json`

Validation:

- `tools/smoke_map_generator_core.gd` passed through `tools/run_godot.ps1`。
- `tools/smoke_first_outdoor_generated.gd` passed through `tools/run_godot.ps1`。
- `tools/capture_first_outdoor_seed_view.gd` passed through `tools/run_godot.ps1`；headless capture writes payload-only because headless renderer does not provide a viewport image。

Risks:

- Route feel、dungeon branch readability、and next-exit priority still need user/design-lead visual review in interactive Godot run。
- Collision and boundary model failed user review and is now handled by TASK-025。
