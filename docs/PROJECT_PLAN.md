# 项目计划

这个文件是 Prototype Alpha vertical slice 的长期计划。它描述“要按什么顺序把系统和内容做出来”，具体当前执行任务以 [TASK_BOARD.md](../TASK_BOARD.md) 为准。

## 项目范围

当前冻结范围：

- 15-20 分钟 Windows demo。
- Godot 4.6。
- 2D dark fantasy ARPG。
- Primary target resolution: `1920x1080`；minimum validation resolution: `1280x720`。
- Diablo II-like 的刷宝、装备和成长节奏。
- Chronicon-like 的 WASD 控制与 pseudo top-down 表现。
- 一张 outdoor map。
- 一个可进入 dungeon。
- 一个 small boss。
- 一条轻量 quest thread。
- 两个职业原型：paladin-style melee 和 mage-style ranged。

核心方向：

- 最终体验靠刷宝、升级、解锁技能、获得更强机动性和战斗效率形成正反馈。
- 第一阶段不做大量横向内容，先把一个职业的 vertical loop 拉通。
- 系统可以小，但不能假。`Item System`、`Progression System`、`Skill Tree`、`Hotbar` 必须是之后能横向扩展的骨架。
- 美术主要依赖 AI 生成和人工筛选整理，项目内重点是资产规范、命名、导入和动画稳定。

## Milestone 0: Project Audit And Rules

Goal:

理解当前项目里已有的 scene、script、asset、animation、input 设置，并把后续工作对齐到冻结设计文档。

Tasks:

- 审查当前 scenes、scripts、assets、animations、input setup。
- 判断哪些 player/enemy code 可以保留，哪些只是临时实现。
- 判断哪些临时素材需要替换或标记为 deprecated。
- 确认 scenes、scripts、sprites、animation resources、raw AI outputs 的文件夹约定。
- 在 combat sandbox 前做一轮小范围结构稳定，不做全项目大清理。
- 分离 raw AI output 和 accepted gameplay sprites。
- 找到 active player scene、enemy scene、sprite assets、animation resources。
- 明确标记临时素材，不在这个阶段追求最终美术质量。
- 持续维护 `TASK_BOARD.md`，让其他 agent 可以接手。

Acceptance:

- 项目结构已经被理解。
- 有 keep / redo 列表。
- active conventions 足够清楚，其他 agent 可以继续工作。
- 明显的文件夹和 resource 混乱被降低。
- 第一版 `CombatSandbox.tscn` 计划清楚。

不要把这个 milestone 做成完整 architecture cleanup。目标是降低 combat 工作前的混乱，不是把整个代码库重构到完美。

## Milestone 1: Combat Sandbox

Goal:

创建一个小场景，让 movement、facing、attack、hit feedback、enemy death、loot 可以快速测试。

Tasks:

- 创建或确认 `CombatSandbox.tscn`。
- 添加 player spawn。
- 添加 dummy enemy。
- 添加 melee chaser enemy。
- 需要时加入简单 debug labels。
- 验证 WASD movement。
- 验证 mouse aim direction。
- 验证冻结的 facing rules。
- 验证一个 basic attack loop。

Acceptance:

- Player 可以用 WASD 移动。
- Player 正常移动时朝移动方向。
- Player 攻击或施法时朝鼠标方向。
- Player 可以伤害并杀死 enemy。
- Combat 改动可以不进入完整地图就快速测试。

## Milestone 2: First Combat Feel Pass

Goal:

让最小攻击循环读得清楚，并且开始有可迭代的手感。

Tasks:

- 把 hit detection 对齐到 visible active frames。
- 增加 enemy hit flash。
- 增加 enemy knockback 或 stagger。
- 增加 damage numbers。
- 如果有可用素材，加入 basic hit sound placeholders。
- 对重要命中加入短 hit stop。
- 调整 movement speed、attack range、attack recovery、enemy health。

Acceptance:

- 命中在视觉上可读。
- 玩家能理解攻击是否打中。
- Enemy death 清楚。
- 战斗节奏保持偏慢，接近 Diablo II-like pacing，而不是动作游戏高速乱斗。

## Milestone 3: Vertical Item And Growth Loop

Goal:

在扩职业、敌人、技能数量之前，用一个职业证明最小 Diablo-like 纵向成长链路。这个 milestone 必须建立真实可复用的系统骨架，只是内容量可以很小，不能用临时 hardcoded shortcut 假装完成。

Tasks:

- 建立 `Item System` 骨架：item definitions、item instances、item database/load path、drop roller、inventory、equipment slots、stat modifiers。
- 使用简单 data/config tables，优先 JSON under `data/items/`；demo 阶段不使用 SQL。
- Item categories 先按未来可扩展设计：weapon、armor、accessory、consumable、material、quest。当前只要求 weapon 有行为。
- Equipment slots 先按未来可扩展设计：weapon、chest、accessory。当前只激活 weapon。
- 使用小规模 Diablo-like drop logic：base item definition + rarity + rolled stats = concrete item instance。
- 增加 tiny rarity/drop config：normal、magic、rare weapons。
- 增加 functional inventory/equipment UI，并支持鼠标 item handling。
- 建立 `Progression System` 骨架：XP、level、XP curve/rewards config、skill points。
- 建立 `Skill Tree` 骨架：skill definitions、prerequisites、level requirements、ranks、unlock cost、learned state。
- 只配置 1-2 个 low-tier knight skills，并只实现最小有用 active skill。
- 把 prototype UI 从 debug panels 改成可玩的 ARPG UI：更大且 screen-safe 的 `Inventory`，独立 `K` 打开的 `Skill Tree`，底部居中的 config-backed `Hotbar`，以及基于 icon 的 learned active skill 点击安装交互和 hover descriptions。
- 保留 `light_attack` 作为默认 non-tree action，默认绑定 `LMB`；`shield_charge` 等 learned active skills 通过 `Hotbar` 安装和触发。
- 加入 sandbox objective flow，让玩家实际经历 combat、loot、equipment、XP、skill unlock、skill assignment、skill use 和完成状态。

Acceptance:

- Enemy 可以掉落 rolled weapon item instances。
- Player 可以把 item 拾取到 small bag。
- Player 可以通过 generic equipment slot path 装备 weapon。
- Equipped item stats 通过 reusable stat path 影响 combat。
- Player 可以获得 XP、level up，并得到 skill points 等 progression resource。
- Player 可以通过 `Skill Tree` skeleton 解锁或升级 configured skill。
- Player 可以使用大尺寸、screen-safe 的 `Inventory`、独立 `Skill Tree` 和 bottom-center `Hotbar`。
- Player 可以把 learned active skills 安装到 `Hotbar` slots；unlearned/passive skills 会被拒绝。
- Sandbox 有一条短的 beginning-to-completion flow。
- 后续增加 armor/accessory/consumable、更多 rarity、更多 skills、更多 classes 时，不需要替换核心骨架。

## Milestone 4: First Outdoor Semi-Procedural Map

Goal:

把已经证明可用的 vertical sandbox loop 和 UI 搬进 persistent `MainWorld`，采用固定 Town / Base + 半随机 Wilderness 的结构，而不是 Town scene 切换到 Wilderness scene。第一张 outdoor 从基地出口附近在同一 world space 中生成。

Tasks:

- 建立 `MainWorld`：`Player`、`Camera2D`、`FixedTown`、`GeneratedRegion` 同时存在。
- 固定 Town / Base 不走 procedural generator；用户可以手动调整布局和美术。
- Wilderness 不作为独立切换 scene，而是从 `TownExitSocket` 附近 instantiate 到同一 world 坐标系。
- 建立 fixed transition chunk：Town exit -> wilderness entry。
- 第一版 chunk generation 先做一次性 room / chunk graph assembly，不做无限 streaming。
- 先实现通用半随机地图生成核心，再接第一张 outdoor map config。
- 定义第一张图的固定关卡骨架：camp、first contact、fork、dungeon entrance、loot pocket、elite pressure、next area exit。
- 建立 seed 可复现的 map generation 流程。
- 建立区域模板数据：`MapGenerationConfig`、`ZoneTemplate`、`AnchorPoint`、`RouteConnection`、`SpawnRule`、`BoundaryRule`。
- 让算法随机选择区域模板、路线弯曲、支线左右、怪物群落、奖励点和装饰 prop。
- 保证所有关键锚点必定存在且可达。
- 建立 map object definition：每种 prop 自己声明 texture、sprite offset、y-sort foot point 和 collision footprint。
- 支持 `rect`、`circle`、`capsule` 等基础 footprint collision，不把整张图片当碰撞。
- 从 zones + corridors 生成 walkable mask / boundary cells / blocked area。
- 沿 playable area 外缘生成连续 visual boundary，并同步生成 collision / blocker。
- 把 first item drop、first level-up、skill unlock、hotbar skill use 和 elite pressure 放进生成规则，而不是写死在单个手工场景。
- 添加 seed debug、map payload debug、可达性检查、边界检查和 1080p screenshot 验证。

Acceptance:

- 通用 map generator 可以独立通过 3 个 seed 的 smoke test。
- `MainWorld` 中 fixed town 和 generated region 位于同一个 world coordinate space。
- 玩家离开 Town 后，回头仍能看到 Town；不通过传统 scene switching 进入 Wilderness。
- 第一张 outdoor / wilderness region 可以通过 config 使用通用 generator 从 Town socket 附近生成。
- Player 可以从 fixed Town 走到 dungeon entrance 和 next area exit。
- 至少 3 个固定 seed 都能生成不同但结构正确的第一张图。
- Outdoor section 调参后可支持约 5-10 分钟游玩。
- Player 至少获得一次明显 early power gain。
- 主路、分岔、奖励点、怪物群落和边界在 1080p 下可读。
- 生成地图不能出现大片黑色 void 贴着可玩路线；可走区域外缘必须被连续素材封住。
- Prop collision 基于 object definition 的 foot point / footprint，不再靠 texture size 粗略推导。
- Outdoor flow 复用 sandbox 已验证系统，不发明新系统。
- 后续替换素材时不需要重写地图生成规则。

## Milestone 5: Horizontal Prototype Expansion

Goal:

在 vertical loop 可用后，再扩横向内容。

Tasks:

- 规划并实现 mage prototype。
- 增加 second enemy family。
- 在 weapon slot 证明 item loop 后，激活更多 equipment slots。
- 增加更多 skill variants。
- 增加更多 item stat types。

Acceptance:

- 新职业或敌人内容使用现有 item、XP、skill、combat systems。
- 横向扩展不迫使 vertical loop 重写。

## Milestone 6: Dungeon And Small Boss

Goal:

创建 demo 后半段：dungeon pressure 和 small boss。

Tasks:

- 创建 dungeon greybox。
- 增加入口和出口流程。
- 添加 dungeon enemy groups。
- 添加一个 small boss arena。
- Boss 有 2-3 个 readable attacks。
- 增加 boss health bar。
- 增加 boss reward。

Acceptance:

- Player 可以进入 dungeon。
- Dungeon 压力高于 outdoor map。
- Boss 能卡住过弱构筑，但在成长后可击败。
- Boss kill 完成 demo loop。

## Milestone 7: UI And Quest Pass

Goal:

加入足够 UI，让 vertical slice 不需要解释也能玩懂。

Tasks:

- Player health display。
- Skill cooldown display。
- Experience / level display。
- Loot pickup feedback。
- 简单 equipment comparison 或 stat display。
- Quest objective text。
- Boss health bar。
- Death and completion screens。

Acceptance:

- Player 能理解 health、skills、loot、当前 objective。
- UI 功能足够 demo 使用，但不超出当前 demo 需要。

## Milestone 8: Art Replacement And Animation Stability

Goal:

用一致的 AI-assisted pixel art 替换临时视觉，并保证动画稳定。

Tasks:

- Generate 或 select player class sprites。
- Generate 或 select enemy sprites。
- Generate 或 select boss sprites。
- Generate skill effects。
- Generate item icons。
- 验证 canvas size、frame counts、transparency、feet baselines、style consistency。
- 把 accepted assets 接入 Godot `SpriteFrames`。

Acceptance:

- Player 和 enemies 视觉风格一致。
- Animation swaps 不 jitter。
- Hit timing 匹配 visible frames。
- Temporary assets 被清楚标记或从 active scenes 移除。

## Milestone 9: Full 15-20 Minute Run

Goal:

调完整 demo，从出生点到 boss reward。

Tasks:

- 调 enemy density。
- 调 enemy health and damage。
- 调 experience curve。
- 调 drop rates。
- 调 item stat ranges。
- 调 skill cooldowns。
- 调 boss difficulty。
- 重复跑完整 demo。

Acceptance:

- Full run 大约 15-20 分钟。
- Player 至少获得两次明显 power jumps。
- Combat、loot、growth 支撑同一个核心循环。

## Milestone 10: Demo Polish And Export

Goal:

准备可玩的 Windows demo build。

Tasks:

- 补齐缺失 sound placeholders 或 final sounds。
- 加强 hit、pickup、boss feedback。
- 修 blocking bugs。
- 检查 performance。
- 检查 input defaults。
- 检查 window and resolution behavior。
- Export Windows build。

Acceptance:

- Demo 可以从头玩到尾。
- Windows export 可以运行。
- Known issues 已记录。
