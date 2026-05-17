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
- Set project display defaults to 1280x720 with canvas stretch/expand。
- Inventory/Equipment UI uses larger slots、icons、labels and viewport-clamped placement。
- Skill Tree rebuilt into separate `K` panel with `heavy_strike -> shield_charge -> shield_training` path。
- `light_attack` remains baseline non-tree action assigned to `LMB`。
- Hotbar assignment flow changed to click slot -> icon picker -> choose learned active skill。
- Runtime validation passed with `tools/smoke_combat_sandbox_structure.gd`、`tools/debug_player_inputs.gd`、`tools/debug_combat_sandbox.gd`。

Risks:

- Skill tree is still vertical prerequisite-card path, not true Diablo II-style icon grid/tree。
- Headless smoke proves bounds/focus/overlap, but not final visual polish。
