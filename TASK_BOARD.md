# 任务板

这个文件是主线程给其他对话或 agent 的交接入口。任何具体任务开始前，先读这里，再读相关冻结文档。

## 当前可信文档

当前规划、范围和实现规则以这些文件为准：

- [README.md](README.md)
- [docs/DEMO_SCOPE.md](docs/DEMO_SCOPE.md)
- [docs/CONTROL_AND_COMBAT.md](docs/CONTROL_AND_COMBAT.md)
- [docs/ART_PIPELINE.md](docs/ART_PIPELINE.md)
- [docs/PROJECT_PLAN.md](docs/PROJECT_PLAN.md)
- [docs/TASK_002_ASSET_INTEGRATION.md](docs/TASK_002_ASSET_INTEGRATION.md)
- [docs/TASK_003_COMBAT_SANDBOX_PLAN.md](docs/TASK_003_COMBAT_SANDBOX_PLAN.md)
- [ASSET_PROMPT_TEMPLATE.md](ASSET_PROMPT_TEMPLATE.md)

如果旧笔记和上面文件冲突，以上面文件为准。

## 当前阶段

已经完成第一轮 combat sandbox 和纵向系统主链路，现在进入 UI 可玩化与第一张 outdoor greybox 前的整理阶段。

## 当前目标

先把一个职业的最小 Diablo-like 纵向成长链路做扎实，再扩职业、怪物、技能数量：

```text
kill enemy
-> item drops
-> item goes into bag
-> player equips item
-> stats change
-> player kills faster
-> player gains XP
-> player levels up
-> player unlocks one new ability
-> player assigns skill to Hotbar
-> player uses skill
-> sandbox objective completes
```

原则：可以只有很少内容，但不能是假系统。`Item System`、`Progression System`、`Skill Tree`、`Hotbar` 都要有可扩展骨架，后面横向加内容时不应推倒重写。

## 当前任务

### TASK-018: Diablo-like UI Scale, Skill Tree, And Hotbar Rework

Status: done

Task agent status: done

Audit Status:

- 2026-05-17 strict audit: functionally passes runtime validation, but with caveats.
- Diablo II comparison: acceptable demo deviation that skill assignment uses a modern six-slot hotbar/icon picker instead of Diablo II left/right mouse skill binding; keep it documented because it changes the interaction model.
- Diablo II comparison: skill tree is currently a vertical prerequisite-card path, not a true Diablo II-style icon grid/tree. Acceptable for a first UI pass, but should not be called final tree layout.
- UI audit: 1280x720 viewport-safe layout, larger inventory slots/icons/text, bottom-center hotbar, skill picker, and tooltip paths pass smoke/runtime checks.
- UI audit finding: `InventoryPanel` and `SkillTreePanel` can currently be open at the same time and overlap. Fix by making large panels mutually exclusive: opening `B` inventory closes `K` skill tree, and opening `K` skill tree closes inventory.
- UI audit finding: the objective panel sits under/near the debug/character info block, so the left side reads cluttered. Move objective to a dedicated top-right safe area, or hide/collapse objective/debug info while a large panel is open.
- UI audit finding: current smoke tests only check offscreen bounds and panel existence; add a layout test for overlap between debug/objective/inventory/skill tree/hotbar when panels are toggled.
- Diablo II comparison: large focus panels should behave more like Diablo II-style modal character/inventory/skill surfaces, where the player is focused on one major management panel at a time rather than stacked overlapping panels.
- Handoff note: `TASK_BOARD.md` is saved as UTF-8 with BOM so Windows PowerShell and later agents can read Chinese text correctly.
- 2026-05-17 implemented UI scale/layout pass for the sandbox: viewport-safe larger Inventory, dedicated Skill Tree, bottom-center Hotbar, and Objective panel.
- Added project display defaults for 1280x720 with canvas stretch/expand so the prototype opens in the intended UI scale.
- Rebuilt Inventory/Equipment UI with 64px slots, larger item icons, larger labels, and viewport-clamped placement.
- Rebuilt Skill Tree into a separate `K` panel with icon cards and a visible `heavy_strike -> shield_charge -> shield_training` prerequisite path.
- Added `heavy_strike` as the first learnable active skill and made `shield_charge` require `heavy_strike`.
- Kept `light_attack` as the baseline non-tree action, default-assigned to `LMB`.
- Changed Hotbar assignment flow to click slot -> icon picker -> choose learned active skill; picker icons expose tooltip descriptions.
- Removed the visible Skill Tree `Assign V` button path; assignment now happens through Hotbar slot selection.
- Added placeholder generated skill icons using config `icon_color` values.
- Updated sandbox objective flow to require unlocking `heavy_strike`, then `shield_charge`, then assigning/using Shield Charge from Hotbar.
- Runtime validation passed with `tools/smoke_combat_sandbox_structure.gd`, `tools/debug_player_inputs.gd`, and `tools/debug_combat_sandbox.gd`.

Goal:

重做当前 sandbox UI，让它从 debug UI 变成可试玩的 ARPG UI。重点修正界面过小、面板超出屏幕、`Skill Tree` 不像树、`Hotbar` 没有真正落到底部的问题。

Focus:

- 整体游戏 UI 按当前窗口和 viewport 做缩放与安全布局，不再依赖一堆固定小坐标。
- 所有大面板必须完整留在可见范围内，不能超出屏幕边界。
- `Inventory` / `Equipment` 面板整体放大，包括 panel、slot、item icon、装备槽、字体和行距。
- `Inventory` 仍然用 `B` 打开，但不再承载 `Skill Tree`。
- `Skill Tree` 用 `K` 打开独立大面板，面板需要居中或安全停靠，并受 viewport 边距约束。
- `Skill Tree` 需要更接近 Diablo II 的树形结构，而不是普通按钮列表。
- 第一版 `Skill Tree` 节点：
  - `heavy_strike` / 重击：第一个可学习 skill。
  - `shield_charge` / 盾冲：第二个 skill，需要先学习 `heavy_strike`。
- `light_attack` / 平 A 是默认基础 action，不出现在 `Skill Tree` 中。
- Skill 节点需要图标；暂时可以使用 placeholder icon。
- 节点需要显示 rank、required level、prerequisite、unlock cost、locked/unlocked state。
- `Hotbar` 必须固定在窗口底部中央，常驻显示，不被其他面板遮挡。
- `Hotbar` 槽位继续由 config 定义，默认是 `LMB`, `RMB`, `Q`, `E`, `R`, `V`。
- 每个 `Hotbar` 方框需要显示两个内容：快捷键标签，以及该 slot 已安装 skill 的 icon；如果 slot 为空，只显示快捷键和空槽状态。
- `light_attack` 默认绑定到第一个 hotbar slot，也就是 `LMB`。
- 安装 skill 的交互改为：点击 hotbar slot -> 弹出该 slot 可装备的 learned active skill icon 列表 -> 玩家选择 skill。
- Hotbar 弹出的可装备 skill 选项以 skill icon 为主，不要只是文字列表。
- 鼠标悬停在弹出的 skill icon 上时，需要显示 tooltip，包含 skill 名称和描述。
- 不允许在 `Skill Tree` 面板里直接 `Assign V`。
- 未学习的 active skill 不能装备到 `Hotbar`。
- passive skill 不能装备到 `Hotbar`。
- 已学习的 active skill 可以装备到任意允许的 active slot。
- `shield_charge` 只有学习并安装到某个 slot 后，才能从该 slot 触发。
- 当前 UI 文案可以继续使用英文占位；需求和任务说明使用中文，代码名词保持英文。

Acceptance:

- 默认窗口下，`Inventory`、`Skill Tree`、`Objective`、`Hotbar` 都完整可见，不超出屏幕。
- UI 元素明显变大，slot、icon 和文字达到可试玩尺寸。
- `B` 打开的 `Inventory` / `Equipment` 面板可以正常拎取、放置、装备、交换和丢弃 item。
- `K` 打开独立 `Skill Tree` 面板，面板不是 `Inventory` 的一部分。
- `Skill Tree` 中 `heavy_strike` 在 `shield_charge` 前置路径上，`shield_charge` 依赖 `heavy_strike`。
- `Skill Tree` 节点有 placeholder icon，并显示 rank / level requirement / prerequisite / cost / locked state。
- Bottom-center `Hotbar` 显示 6 个 config-backed slots：`LMB`, `RMB`, `Q`, `E`, `R`, `V`。
- 每个 `Hotbar` slot 方框里能看到快捷键标签；如果已安装 skill，也能看到该 skill 的 icon。
- `light_attack` 默认存在、默认绑定 `LMB`，并且不出现在 `Skill Tree`。
- 点击 `Hotbar` slot 会显示可装备 skill icon 选项。
- Hover 弹出的 skill icon 会显示 tooltip，包含 skill 名称和描述。
- 只能把 learned active skill 装进 `Hotbar`；unlearned 或 passive skill 会被拒绝。
- 装入 `Hotbar` 的 `shield_charge` 能从对应 slot 触发。
- Existing attack、inventory、item cursor、objective、collision-debug controls 仍然工作。
- 完成后在本任务条目下写入 `Task agent status: done`。

## Backlog

### TASK-019: First Outdoor Greybox Plan

Status: blocked by TASK-018

Goal:

在 vertical sandbox loop 和核心 UI 证明可用后，规划第一张 outdoor map。这个任务先做计划，不直接实现地图。

Focus:

- 把 sandbox objective flow 翻译成一条 5-10 分钟 outdoor route。
- 定义出生点 / camp、combat zones、第一个 item drop moment、level-up moment、first skill unlock moment、hotbar skill-use moment、dungeon entrance。
- 明确哪些内容复用当前 `Inventory`、`Skill Tree`、`Hotbar`、item、XP、objective 系统。
- 不要求先加第二职业。

Acceptance:

- 计划能说明纵向链路如何变成 5-10 分钟 outdoor segment。
- 计划复用已验证系统，不重新发明新系统。
- 计划列出第一张地图实现时的最小场景、敌人、掉落和目标。

## Later / Horizontal Expansion

这些任务有意延后。先用一个职业把纵向系统跑通，再横向扩内容。

### LATER-001: Mage Prototype Plan

Reason:

第二职业是横向扩展。等 knight 的 inventory、equipment、XP、skill unlock、objective flow 和 UI 使用链路跑通后再做。

### LATER-002: Second Enemy Family

Reason:

当前 item 和 XP 节奏验证后，再加入第二类敌人。否则难判断是系统问题还是内容调参问题。

### LATER-003: More Equipment Slots

Reason:

`weapon` slot 先证明 item loop。`chest`、`accessory` 等槽位已经在骨架里预留，等第一轮链路稳定后再激活更多槽位。

### LATER-004: Dungeon Greybox

Reason:

先完成 outdoor segment 的 combat-growth route，再做 dungeon。dungeon 应该承接户外成长结果，而不是孤立测试场景。

## 已完成任务归档

### TASK-001: Project Audit

Status: done

Task agent status: done

Audit Status:

- 2026-05-16 review completed。
- Runtime flow: `project.godot` -> `scenes/maps/combat_sandbox.tscn` -> `KnightPlayer` + spawned mummy enemies + loot/debug roots。

### TASK-002: Standard Asset Integration And Minimal Structure Stabilization

Status: done

Task agent status: done

Audit Status:

- 2026-05-16 review：当前 sandbox 功能上 OK。
- 当前接受的 sprite 在 `assets/sprites/characters/` 和 `assets/sprites/enemies/`。
- 某些旧 task doc 可能已经过期；以本 task board 和当前 active scene/script 引用为准。

### TASK-003: Combat Sandbox Plan

Status: done

Task agent status: done

Audit Status:

- 2026-05-16 review：已实现并作为主测试场景使用。
- Sandbox 有 player、enemy spawn markers、`Enemies`、`Loot`，以及显示 enemy count、HP、damage、facing、action 的 debug label。

### TASK-004: Player Facing Prototype

Status: done

Task agent status: done

Audit Status:

- 2026-05-16 review：OK。
- `KnightPlayer` 有 `move_direction`、`aim_direction`、`facing_direction`、`action_direction`；鼠标攻击时朝向 aim direction，动作恢复后回到 movement-facing。

### TASK-005: Basic Hit Loop

Status: done

Task agent status: done

Audit Status:

- 2026-05-16 review：OK。
- Player attack 使用 delayed hit timing 和 one-hit-per-swing prevention；mummy enemies 可以受伤、flash、knockback/stagger、死亡并清理。

### TASK-006: First Loot And Power Gain

Status: done

Task agent status: done

Audit Status:

- 2026-05-16 review：OK。
- Mummy death drops `DamagePickup`；pickup 调用 `add_damage_bonus`，sandbox debug damage display 会反映 attack damage 增加。

### TASK-007: Combat Sandbox Feel Pass 1

Status: done

Task agent status: done

Owner: task agent

Audit Status:

- 2026-05-16 feel pass completed。
- Runtime wrapper validation passed for `scenes/maps/combat_sandbox.tscn`。
- Player 可以杀死 mummy、生成 damage loot、拾取并提高显示 attack damage。
- Light player hit timing 和 mummy attack timing 调晚，更匹配 visible active frames。
- Mummy attack lock 现在覆盖完整可见攻击动画。

Goal:

把当前 `CombatSandbox` 从“功能可用”推进到“读得清楚、值得继续迭代”。

Acceptance:

- Sandbox loads without blocking runtime errors。
- Player can kill at least one enemy and pick up damage loot。
- Combat remains readable and not too fast。
- Tuning changes small and easy to revert。
- Completed task entry includes `Task agent status: done`。

### TASK-008: Runtime Smoke Test Script

Status: done

Task agent status: done

Audit Status:

- 2026-05-16 added a narrow CombatSandbox structure smoke test。
- Runtime wrapper validation passed for `tools/smoke_combat_sandbox_structure.gd`。

Goal:

给 combat sandbox 增加或更新一个窄范围 Godot smoke test。

Acceptance:

- Test 可以通过 `tools/run_godot.ps1` 运行。
- Test 用简短日志报告 pass/fail。
- 不引入大型测试框架。

### TASK-009: Player Combat Feedback Pass

Status: done

Task agent status: done

Audit Status:

- 2026-05-16 added lightweight world-space floating feedback。
- Enemy hit 现在生成 damage numbers。
- Damage pickup 现在显示短暂 `Damage +N` pickup message。
- Runtime wrapper validation passed for CombatSandbox debug script。
- 2026-05-16 audit confirmed：`debug_combat_sandbox.gd` passes；hit feedback spawns，loot pickup raises damage from 24 to 32。

Goal:

在不加入大系统的前提下，提升玩家可见的 combat feedback。

Acceptance:

- Player can tell when hits connect。
- Player can tell when loot increased damage。
- Feedback remains readable in sandbox。

### TASK-010: First SFX Pass

Status: done

Task agent status: done

Audit Status:

- 2026-05-16 organized first accepted SFX into `assets/audio/sfx/`。
- Player attacks、enemy hit/death、damage pickup 已接入 placeholder。
- 2026-05-16 main-thread review：first wiring exists，但 player attack sound mapping 太泛，需要修正。
- 2026-05-16 revision completed：light attack、heavy attack、shield strike、enemy hit、enemy death、pickup、movement footsteps 已使用不同 accepted SFX names。
- Runtime wrapper validation passed for CombatSandbox debug and smoke scripts。

Goal:

修正并补全当前简单 combat sandbox 的音效映射。

Acceptance:

- Light attack 和 heavy attack 听起来不同。
- Shield charge / shield strike 使用独立 shield sound。
- Enemy hit 和 enemy death 听起来不同。
- Loot pickup 有简单 pickup sound。
- Sound volume 不刺耳。
- Audio files 位于清晰的 `assets/audio/sfx/` 结构。
- Completed task entry includes `Task agent status: done`。

### TASK-011: Item System Skeleton

Status: done

Task agent status: done

Audit Status:

- 2026-05-16 re-audit：OK against rewritten Milestone 3；item definitions、`ItemInstance` normalization、generic equipment slot map、damage stat path 都存在。
- Added `data/items/item_definitions.json` with item types、equipment slots、weapon definitions。
- Added `ItemDatabase` loader/lookup helpers for item definitions、equipment slots、normalized `ItemInstance` dictionaries。
- Player inventory now stores item instances and equipment uses generic equipment slots，当前只激活 weapon。
- Equipped stats 通过 reusable `stat_modifiers.damage` 生效，同时保留当前 attack damage UI。
- Existing ground pickup、cursor item、equip、swap、drop flows 兼容。
- Runtime wrapper validation passed for `tools/smoke_combat_sandbox_structure.gd` and `tools/debug_combat_sandbox.gd`。

Goal:

把当前 loot/equipment prototype 重构成真正的最小 `Item System` 骨架。内容可以少，但结构必须能支持后续 Diablo-like 扩展。

Acceptance:

- Item definitions 从 config 加载，不只写死在 pickup script。
- Dropped 和 inventory items 使用引用 definition 的 item instances。
- Inventory 可以存 item instances，不只认识 weapons。
- Equipment 可以通过 generic slot path 装备 weapon item instance。
- Equipped item stats 通过可复用 stat application path 影响 player damage。
- Skeleton 对 armor/accessory/consumable 有清晰扩展点，不需要重写 core。
- Completed task entry includes `Task agent status: done`。

### TASK-012: Item Drop Roll And Instance Data v1

Status: done

Task agent status: done

Audit Status:

- 2026-05-16 re-audit：OK；mummy drops 使用 config-backed drop table、rarity weights、rolled damage modifiers through `ItemDatabase`。
- Added `data/items/drop_tables.json` with mummy weapon drop definitions and rarity weights。
- Rarity prefixes、colors、damage ranges now live in config instead of enemy script。
- Enemy drops call `ItemDatabase.roll_item_instance("mummy_weapon")` to produce concrete `ItemInstance` data。
- Same item definitions can roll different names、rarity colors、`stat_modifiers.damage` values。
- Runtime wrapper validation passed for `tools/debug_combat_sandbox.gd`；drop sampling reported multiple names、all 3 rarities、varied damage values。

Goal:

让 enemy drops 使用 item-system skeleton，而不是固定 item result。

Acceptance:

- Enemy drops create rolled `ItemInstance` data。
- Same item definition can produce different concrete drops。
- Rarity changes item display and stat range。
- Drop logic later can add more item types without replacing the whole path。
- Completed task entry includes `Task agent status: done`。

### TASK-013: Inventory And Equipment UI v1

Status: done

Task agent status: done

Audit Status:

- 2026-05-16 re-audit：OK；inventory/equipment UI covers cursor pickup、bag placement、equip/swap/drop、item details、attack blocking。
- Inventory UI now displays item type、target equipment slot、stat damage from item instances。
- Equipment UI shows reusable slot structure：weapon active，chest/accessory reserved and locked for now。
- Player exposes generic equipment-slot accessors while preserving existing weapon-slot interaction。
- Existing Diablo-like cursor pickup、bag placement、equip、swap、drop、attack-block flows pass。
- Runtime wrapper validation passed for `tools/smoke_combat_sandbox_structure.gd` and `tools/debug_combat_sandbox.gd`。

Goal:

通过一个小但真实的 inventory/equipment UI，让 `Item System` 骨架可见、可用。

Acceptance:

- Player can open/close inventory with `B`。
- Player can pick a world item into cursor/bag。
- Player can equip a weapon through generic equipment slot path。
- Player can swap/drop items without item loss。
- UI proves the item system, not a weapon-only shortcut。
- Completed task entry includes `Task agent status: done`。

### TASK-014: Progression System Skeleton

Status: done

Task agent status: done

Audit Status:

- 2026-05-16 re-audit：OK；`ProgressionState` owns XP/level/skill points from config and sandbox validation confirms level-up resource reward。
- Added `data/progression/progression_config.json` for XP thresholds、level damage bonus、skill-point rewards。
- Added `ProgressionState` to hold level、current XP、XP-to-next-level、available skill points outside direct combat code。
- Player XP gain now flows through `ProgressionState`；level-up still updates visible damage and now awards skill points。
- Sandbox debug text and inventory panel show available skill points。
- Runtime wrapper validation confirmed level 1 -> 2，damage 24 -> 27，skill points 0 -> 1。

Goal:

把 XP/level growth 重构成小型 `Progression System` 骨架，之后能喂给 skill points、stat points、level-gated systems。

Acceptance:

- Enemy kills grant XP through reusable progression path。
- Player can level up。
- Level-up awards skill points or another explicit progression resource。
- Combat stats can still react to level if configured。
- System can feed later skill tree without rewriting XP logic。
- Completed task entry includes `Task agent status: done`。

### TASK-015: Minimal Skill Tree Skeleton

Status: done

Task agent status: done

Audit Status:

- 2026-05-16 re-audit：OK；`SkillTreeState` uses data definitions、level/point requirements、unlock cost、ranks、gates Shield Charge behavior。
- Added `data/skills/knight_skills.json` with `shield_charge` and a placeholder dependent passive。
- Added `SkillTreeState` for data-driven skill definitions、prerequisites、rank state、unlock cost、requirement checks。
- Player can spend progression skill points to unlock `shield_charge`。
- `V` shield charge is locked until configured skill is unlocked，then enables existing shield-charge attack。
- Inventory panel includes a minimal skill-tree block with shield-charge status and unlock button。
- Runtime validation confirms shield charge is blocked before unlock and works after unlock。

Goal:

创建真实的最小 `Skill Tree` 结构，只实现或配置少量低阶节点。

Acceptance:

- Skills are defined as data, not only `if level >= X`。
- Player can spend a skill point to unlock or rank up configured skill。
- Skill prerequisites/level requirements exist in the structure。
- At least one unlocked skill changes combat behavior。
- Completed task entry includes `Task agent status: done`。

### TASK-016: Skill Tree Panel And Skill Loadout UI

Status: done

Task agent status: done

Audit Status:

- 2026-05-17 re-audit：OK；dedicated `K` skill-tree panel、config-backed 6-slot loadout、default `LMB` light attack、assignment validation、`V` Shield Charge trigger all pass。
- Skill learning moved out of inventory panel into dedicated `K` skill-tree panel。
- Added config-driven skill loadout defaults in `data/skills/skill_loadout_defaults.json`。
- Added `SkillLoadoutState` with six default slots：`LMB`, `RMB`, `Q`, `E`, `R`, `V`。
- Added baseline `light_attack` as default active action，not part of skill tree，starts assigned to `LMB`。
- Bottom-center hotbar displays six configured slots during normal play。
- Learned active skills can be assigned；unlearned and passive skills are rejected。
- Shield Charge can be unlocked in skill-tree panel，assigned to `V`，and triggered from that slot。
- Runtime wrapper validation passed for smoke/debug scripts。

Goal:

把 skill learning 从 inventory panel 移出，并加入现代 ARPG active-skill loadout surface。

Acceptance:

- `K` opens/closes dedicated skill-tree panel。
- Inventory no longer contains skill-tree controls。
- Player can unlock or rank up a skill from skill-tree panel。
- Bottom-center UI shows 6 active skill slots loaded from config。
- `light_attack` is available by default, not shown as skill-tree node, starts assigned to `LMB`。
- Learned active skill can be assigned to loadout slot。
- Unlearned or passive skill cannot be assigned。
- Assigned Shield Charge can be triggered from configured slot。
- Existing attack, inventory, item cursor, and collision-debug controls still work。
- Completed task entry includes `Task agent status: done`。

### TASK-017: Sandbox Objective Flow

Status: done

Task agent status: done

Audit Status:

- 2026-05-17 re-audit：OK；sandbox objective flow reaches completion through combat、loot/equip、level 2、skill unlock、`V` assignment/use、brute defeat。
- Added sandbox objective tracker panel。
- Objective flow guides player through：kill a mummy、pick up loot、equip a weapon、reach level 2、unlock Shield Charge、assign it to `V`、use it from loadout、defeat `MummyBrute`。
- Objective completion is tracked through `get_objective_stage()` and `is_objective_complete()`。
- Runtime validation exercises complete chain through item pickup/equip、XP level-up、skill unlock、loadout assignment、shield-charge use、brute defeat。
- Runtime wrapper validation passed for smoke/debug scripts。

Goal:

把 sandbox 做成一条短 vertical-slice objective sequence，使用真实的 item、progression、skill-tree、skill-loadout 骨架。

Acceptance:

- Sandbox has beginning, middle, and completion state。
- Player experiences combat、item drop、inventory、equipment、XP、skill point、skill unlock、skill-slot assignment、skill use、completion in one flow。
- Completed task entry includes `Task agent status: done`。

## Agent 规则

- 先读本文件。
- 再读 `README.md` 和相关冻结文档。
- 在这个 Windows workspace 中，裸 `rg` 可能解析到 WindowsApps 版本并报 "Access denied"；使用项目内 `tools/ripgrep/rg.exe`，或用 PowerShell `Get-ChildItem`、`Select-String`、`Get-Content` fallback。
- 从 Codex 运行 Godot CLI 时，使用项目 wrapper：`powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 ...`；不要直接调用 Godot。wrapper 会设置 Codex 可写的 `LOCALAPPDATA`、`APPDATA`、`TEMP`、`TMP`，避免 headless/console run 崩溃。
- Godot CLI、headless、smoke test、script test、automated validation 任务必须使用项目 skill `godot-cli`。
- 简单文档或静态脚本编辑不要默认跑 Godot CLI。只有 runtime 行为重要时才跑，例如 scene loading、null instances、input wiring、resource paths、AI movement、combat timing、静态检查不能确认的 regression。
- Validation output 要小：短 smoke tests、窄 debug scripts、selected log lines、file-specific diffs。除非必要，不贴完整脚本、完整日志、完整 repo diff。
- 不做 broad architecture rewrites。
- 不替换已经冻结的设计决策，除非主线程先 review。
- 不碰无关文件。
- 不 revert 用户或其他 agent 的已有工作，除非明确要求。
- 优先做小而可玩的改动。
- 编辑后报告所有 changed files。
- 遇到 blocker 时，报告 blocker 和最小可推进下一步。
- 任务完成后，在对应 task entry 写入 `Task agent status: done`。

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

同时在本文件对应已完成任务条目中更新：

```text
Task agent status: done
```
