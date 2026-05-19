# TASK-019: First Outdoor Greybox Plan

> 历史参考：这个文档记录的是旧的手工 outdoor greybox 计划。2026-05-18 之后，第一张 outdoor map 的当前方向已经改为 seed 可复现的半随机生成系统；当前任务入口以 [../TASK_BOARD.md](../TASK_BOARD.md) 为准。

这个文档定义第一张 outdoor map 的 greybox 计划。它不是实现任务；实现从 `TASK-020` 开始。

## 设计参考

参考 Diablo II Act I 的 Blood Moor / Den of Evil 教学结构，但不照抄 45 度 isometric 表现。

可借鉴点：

- 从安全营地离开，立刻进入弱敌区域。
- 主路清楚，玩家即使不看地图也能顺着路找到第一个目标。
- 第一张野外图里放一个近距离 dungeon entrance。
- 通往下一片区域的位置可以作为软门槛，提醒玩家先完成当前目标。
- 第一批敌人弱、慢、数量可控，让玩家先理解攻击、掉落和升级。
- 第一个任务目标要简单明确：清理一处被污染的小区域。

参考 Chronicon 的修正方向：

- WASD 直接移动，鼠标用于 action aim。
- 伪 top-down / 平面可读优先，不追求 Diablo II 45 度空间层次。
- Hotbar 常驻底部，玩家通过 slot 使用 learned active skill。
- 早期路线要短、密度清楚、反馈频繁，让玩家快速经历 loot、level、skill 和 active slot 使用。

## Outdoor Route 总览

目标时长：5-10 分钟。

路线结构：

```text
Camp Gate
-> Training Verge
-> Broken Road
-> First Loot Clearing
-> Shrine Fork
-> Corrupted Hollow Entrance
-> Gate Scout / Dungeon Hook
```

玩家体验链路：

```text
spawn / camp
-> receive light quest prompt
-> kill weak enemies
-> see first item drop
-> open Inventory with B
-> equip weapon
-> kill faster
-> gain XP and level up
-> open Skill Tree with K
-> unlock heavy_strike
-> unlock shield_charge
-> assign shield_charge through Hotbar
-> use shield_charge in pressure encounter
-> reach dungeon entrance
```

## 区域设计

### 1. Camp Gate

Purpose:

- 安全出生点。
- 展示玩家初始 UI：health、objective、Hotbar。
- 给玩家一个轻量 quest prompt。

Greybox:

- 小 camp 区域，不能被敌人进入。
- 出口只有一个，通向 `Training Verge`。
- 出口处可以放一个 sign / scout marker，之后作为软门槛提示。

Objective:

```text
Leave camp and investigate the corrupted road.
```

Systems verified:

- Player spawn。
- Objective panel。
- Bottom-center Hotbar visible。
- Movement / facing 基础可读。

### 2. Training Verge

Purpose:

- 让玩家在低风险下完成第一次攻击和第一次击杀。
- 不在这里强迫背包、技能树或复杂 UI。

Greybox:

- 宽一点的空地。
- 2-3 个弱 melee enemy。
- 敌人离 camp 出口有一点距离，避免出生点立刻受压。

Enemy:

- 使用当前 mummy family 或临时 outdoor equivalent。
- 低血量、慢接近、低伤害。

Objective:

```text
Defeat the enemies near the road.
```

Systems verified:

- WASD movement。
- Mouse-aimed attack direction。
- Hit feedback。
- Enemy death。
- XP gain。

### 3. Broken Road

Purpose:

- 给玩家一个清楚方向感。
- 借鉴 Blood Moor 的路：路本身就是引导，不需要复杂导航 UI。

Greybox:

- 一条弯曲主路。
- 两侧有少量树桩、石头、破车、围栏，形成软边界。
- 允许玩家离开主路一点点，但不要大到迷路。

Encounter:

- 2 个小敌人分散巡逻。
- 不放强敌。

Systems verified:

- Camera / player readability。
- Y-sort / world object readability。
- Outdoor navigation。

### 4. First Loot Clearing

Purpose:

- 第一处明确掉落点。
- 让玩家从“杀敌”进入“掉落 -> 背包 -> 装备 -> 变强”。

Greybox:

- 路边小空地。
- 3-4 个弱敌。
- 其中最后一个或小队长保证掉落一个 weapon item instance。

Drop rule:

- 使用当前 `ItemDatabase` / drop table。
- 可以临时提高这里的 first useful weapon drop chance，但不要写死成 debug bonus。

Objective:

```text
Pick up the dropped weapon and equip it.
```

Systems verified:

- Item drop。
- Ground item visibility。
- Inventory `B`。
- Cursor pickup。
- Bag placement。
- Weapon equip。
- Stat increase。
- Combat becomes faster / clearer after equip。

### 5. Shrine Fork

Purpose:

- 第一次小分叉，测试玩家是否能读懂路。
- 给 level-up / skill unlock 留空间。

Greybox:

- 主路分叉：
  - 左路：小 shrine clearing，提供 combat + XP。
  - 右路：通向 dungeon entrance，但先被 pressure encounter 或 scout marker 阻挡节奏。

Encounter:

- Shrine clearing 放 4-5 个普通敌人。
- XP 设计目标：清掉这里后玩家达到 level 2，获得 skill point。

Objective:

```text
Gain enough experience to learn a new skill.
```

Systems verified:

- XP threshold。
- Level-up feedback。
- Skill point display。
- Skill Tree `K`。
- `heavy_strike` prerequisite path 可见。

### 6. Skill Unlock Moment

Purpose:

- 把 `Skill Tree` 和 `Hotbar` 放进 outdoor 正常路线，而不是 sandbox debug 行为。

Flow:

1. 玩家 level up。
2. Objective 提示 open `K`。
3. 玩家学习 `heavy_strike`。
4. 如果当前 config 需要，继续通过后续 XP 或奖励学习 `shield_charge`。
5. 玩家点击 Hotbar slot，把 learned active skill 装入可用 slot。

Recommended demo shortcut:

- `heavy_strike` 在 level 2 可学。
- `shield_charge` 仍要求 `heavy_strike`。
- 为了 outdoor 5-10 分钟可验证，可以在 Shrine clearing 或 elite 前安排足够 XP，让玩家在进入 pressure encounter 前学到 `shield_charge`。

Systems verified:

- Skill point gain。
- Skill Tree unlock。
- Prerequisite validation。
- Hotbar slot click。
- Skill icon picker。
- Learned active skill assignment。

### 7. Corrupted Hollow Entrance

Purpose:

- 第一张 outdoor map 的终点。
- 这是 dungeon entrance hook，不进入 dungeon 实现。

Greybox:

- 洞口 / 地窖门 / 腐化裂口。
- 入口前有一个小战斗空间。
- 入口暂时可以是 blocked transition marker。

Encounter:

- 1 个 tougher enemy 或 mini-elite。
- 2-3 个普通敌人。
- 这个 encounter 要鼓励玩家用刚装到 Hotbar 的 `shield_charge`。

Objective:

```text
Use your new skill to break through the corrupted guard.
Reach the dungeon entrance.
```

Systems verified:

- Hotbar skill use。
- New skill changes combat behavior。
- Elite pressure。
- Objective completion / next-stage hook。

### 8. Gate Scout / Soft Boundary

Purpose:

- 借鉴 Diablo II Blood Moor 里 Flavie 的软门槛作用。
- 在玩家没完成 outdoor objective 前，不鼓励继续进入 dungeon 或下一图。

Implementation idea:

- 放一个 scout marker、sealed gate、corrupted roots 或 simple interact label。
- 如果 objective 未完成，提示玩家先处理附近腐化。
- 如果 objective 完成，提示 dungeon entrance will be available in next task。

不要在 `TASK-019` 实现逻辑；这里只记录设计意图。

## 路线节点和系统验证表

| Route Node | Player Action | System Verified | Pass Signal |
| --- | --- | --- | --- |
| Camp Gate | 出生、看 objective、离开 camp | spawn, objective, Hotbar | 玩家知道往哪里走 |
| Training Verge | 击杀弱敌 | movement, facing, hit feedback, XP | 敌人死亡反馈清楚 |
| Broken Road | 顺路前进 | route readability, camera, world layout | 不需要地图也能找到下一处 |
| First Loot Clearing | 击杀并拾取 weapon | drop table, ItemInstance, ground item | 掉落可见且可拾取 |
| Inventory Moment | `B` 打开并装备 | inventory/equipment/stat modifiers | 装备后 damage 变化 |
| Shrine Fork | 清小分叉敌人 | XP curve, level-up | 玩家达到 level 2 |
| Skill Moment | `K` 学 skill | Skill Tree, prerequisites, skill points | 学会 `heavy_strike` / `shield_charge` |
| Hotbar Moment | 点击 slot 装 skill | Hotbar assignment, icon picker | skill icon 出现在 slot |
| Entrance Fight | 用 skill 打 tougher enemy | skill use, combat pressure | 新 skill 明显有用 |
| Dungeon Hook | 到达入口 | objective completion, next task hook | outdoor segment 完成 |

## 第一版地图形状

推荐用一条主路加一个小分叉，避免第一版地图过散。

```text
[Camp]
  |
  |  weak enemies
  v
[Training Verge]
  |
  |  broken road, small patrols
  v
[First Loot Clearing] -- small side space
  |
  v
[Shrine Fork] -- optional short branch for XP / skill point
  |
  v
[Corrupted Hollow Entrance]
```

地图原则：

- 主路必须清楚。
- 分叉只能有一个。
- 每段路的目的要不同：教学、掉落、升级、学技能、用技能、到入口。
- 不要做开放大地图。
- 不要做随机生成。
- 不要做真正 dungeon interior。

## 素材需求清单

这一节给 Asset Agent 使用。目标是为第一张 outdoor greybox 准备一套风格统一的临时可用素材，不追求最终完整美术。

### 通用风格

所有素材遵守项目统一风格：

- 2D dark fantasy ARPG。
- Chronicon-like retro 16-bit pixel art。
- Pseudo top-down / slightly angled side view。
- 地面和路线以 top-down readability 为主。
- 角色、敌人、洞口和重要 props 要有一点 front/side body 或 front face，方便读身份和体积。
- Crisp pixels。
- Clean 1px dark outline where suitable。
- Limited palette with strong contrast。
- Transparent PNG。
- No background。
- No watermark。
- No preview text。
- No blur。
- No anti-aliasing。
- No soft painterly shading。
- No realistic lighting。

### 输出和目录

建议目录：

```text
assets/raw/outdoor_01/
assets/sprites/tiles/outdoor_01/
assets/sprites/props/outdoor_01/
assets/sprites/enemies/outdoor_01/
assets/sprites/effects/outdoor_01/
assets/ui/icons/
```

`assets/ui/icons/` 可以和当前已有的 `assets/ui/skills/` 并存。Skill icon 继续放 `assets/ui/skills/`；地图 marker、objective marker、通用 UI icon 可以放 `assets/ui/icons/`。

命名示例：

```text
tile_outdoor01_dead_grass_32.png
tile_outdoor01_dirt_road_32.png
prop_outdoor01_broken_cart_96.png
prop_outdoor01_camp_gate_128.png
prop_outdoor01_corrupted_hollow_128.png
enemy_outdoor01_corrupted_thrall_walk_side.png
enemy_outdoor01_hollow_guard_attack_down.png
vfx_outdoor01_corruption_pulse_64.png
```

### P0：实现 outdoor greybox 必需

这些素材优先级最高。没有它们也能用纯色块 placeholder 做地图，但有了以后 `TASK-020` 的可读性会明显提高。

P0 variations 要克制：第一轮每类最多 2 个 variation，先保证可用，不追求完整美术库。

| Asset | 用途 | 尺寸 / 帧 | 备注 |
| --- | --- | --- | --- |
| `tileset_outdoor01_ground_32.png` | 主地面 + 主路 tileset sheet | 32x32 tiles；建议 4 columns x 2 rows 或更小 | 推荐交付为一个 tileset sheet，而不是零散 PNG。至少包含 dead grass 2 tiles、dirt road straight 1、corner 1、fork/T-junction 1、road edge/transition 1。TASK-020 用 sheet 做 TileMap 更方便 |
| `tile_outdoor01_corrupted_ground_32.png` | 腐化区域 | 32x32 tile，最多 2 variations | 靠近 entrance 和 shrine 使用；如果方便，也可以并入 `tileset_outdoor01_ground_32.png` |
| `prop_outdoor01_camp_gate_128.png` | 出生点出口 | 128x96 或 128x128 static prop | 木门 / 破旧栅门，读作安全区出口 |
| `prop_outdoor01_signpost_64.png` | 路线提示 | 64x64 static prop | 可放在 camp 出口或 fork |
| `prop_outdoor01_corrupted_hollow_128.png` | dungeon entrance marker | 128x128 static prop | 腐化洞口 / 地窖门 / hollow entrance，第一版不进入 |
| `prop_outdoor01_rock_small_32.png` | 路线软边界 | 32x32 static prop，最多 2 variations | 用于路边自然阻挡 |
| `prop_outdoor01_dead_tree_64.png` | 路线软边界 | 64x64 static prop，最多 2 variations | 枯树 / 树桩，注意不要遮挡 player |
| `prop_outdoor01_broken_fence_64.png` | camp / road 边界 | 64x64 static prop，最多 2 variations | 形成安全区和道路边界 |

### P1：建议为 TASK-020 准备

这些素材用于把 route 的关键节点读出来。如果时间紧，可以先用 P0 + 现有 enemy 完成实现。

| Asset | 用途 | 尺寸 / 帧 | 备注 |
| --- | --- | --- | --- |
| `prop_outdoor01_broken_cart_96.png` | Broken Road 视觉锚点 | 96x96 static prop | 破车 / 货箱，让路段更像被袭击过 |
| `prop_outdoor01_shrine_96.png` | Shrine Fork 目标点 | 96x96 static prop | 小型 corrupted shrine，轮廓清楚 |
| `prop_outdoor01_corrupted_roots_64.png` | dungeon soft boundary | 64x64 static prop，2 variations | 可作为入口阻挡或腐化装饰 |
| `vfx_outdoor01_shrine_pulse_64.png` | shrine feedback | 64x64，4 frames | 可选动画，低亮度，不要遮挡战斗 |
| `vfx_outdoor01_corruption_pulse_64.png` | entrance feedback | 64x64，4 frames | 腐化脉冲 / 黑红小特效 |

### P1：敌人素材

第一版可以继续复用当前 mummy family。如果要替换为 outdoor 风格，先做两个敌人，不要扩成完整怪物库。

| Enemy | 用途 | 尺寸 / 动画 | 备注 |
| --- | --- | --- | --- |
| `enemy_outdoor01_corrupted_thrall` | Training / road / loot clearing 普通弱敌 | 64x64 per frame；idle 4、walk 6、attack 6、hurt 2、death 6 | 人形或半腐化村民，慢、弱、轮廓清楚 |
| `enemy_outdoor01_hollow_guard` | Entrance pressure tougher enemy | 96x96 per frame；idle 4、walk 6、attack 6、hurt 2、death 6 | 比普通敌人大一圈，武器或盾牌轮廓明显 |

方向要求：

- Phase 1 最低要求：side + down。
- 如果 PixelLab 成本可接受，优先 4 directions：down、up、side-left、side-right/mirrored side。
- Feet baseline 必须稳定。
- Attack animation 需要标注 visible active hit frame。

### P2：可选 polish

这些不阻塞 `TASK-020`，但可以让 outdoor 第一版更有区域感。

| Asset | 用途 | 尺寸 / 帧 | 备注 |
| --- | --- | --- | --- |
| `prop_outdoor01_camp_crate_32.png` | camp 装饰 | 32x32 static prop | 安全区小物件 |
| `prop_outdoor01_torch_64.png` | camp / entrance 装饰 | 64x64，static 或 4 frames | 火焰不要太亮 |
| `prop_outdoor01_bone_pile_32.png` | 腐化区域装饰 | 32x32 static prop | 少量使用 |
| `item_outdoor01_weapon_drop_icon_32.png` | first useful weapon icon | 32x32 icon | 如果当前 item icon 不够统一再做 |
| `ui_outdoor01_dungeon_marker_icon_32.png` | objective marker | 32x32 icon | UI / minimap 以后可能用，当前不阻塞 |

### 资产验收

Asset Agent 交付前至少检查：

- PNG 透明背景。
- 没有水印、预览文字、背景图。
- pixel 边缘清晰，无 blur / anti-aliasing。
- 角色和敌人 body pixels fully opaque。
- 同一 animation set frame size 一致。
- 敌人 feet baseline 稳定。
- 地面 tile 不抢角色轮廓。
- 重要 props 在 `1920x1080` 主目标窗口下能读出来；在 `1280x720` 最小验证窗口下不能完全失去可读性。
- 命名能看出区域、用途、尺寸。

## TASK-020 实现建议

`TASK-020` 应该只实现 outdoor greybox 的最小可玩版本：

- 新建或复用一个 outdoor scene。
- 放 camp spawn、主路、clearing、shrine fork、dungeon entrance marker。
- 使用 placeholder collision / tile / simple shapes。
- 接入现有 player、enemy、loot、inventory、XP、skill、Hotbar。
- 目标是能从 camp 走到 entrance，并经历一次 loot/equip/level/skill/hotbar loop。

不要在 `TASK-020` 做：

- dungeon interior。
- 第二职业。
- 新大系统。
- 完整美术替换。
- 大范围数值平衡。

## 风险和后续

- 如果 outdoor route 太长，会稀释当前已验证的 sandbox loop。第一版宁可短。
- 如果 first weapon drop 不够稳定，玩家可能无法感知 power gain。第一版可以使用高概率配置，但仍走真实 drop table。
- 如果 XP 不够稳定，skill unlock moment 会漂移。第一版可以通过 route encounter XP 保证 level-up。
- 如果 Hotbar skill use 没有压力场景，玩家会觉得装 skill 是 UI 任务，不是战斗成长。入口前需要一个 tougher encounter。
- 如果地图太开放，solo 开发成本会上升。第一张图用清楚主路和一个小分叉即可。
