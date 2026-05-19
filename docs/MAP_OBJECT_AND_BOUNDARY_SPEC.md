# Map Object And Boundary Spec

这个文档定义第一张 outdoor 生成地图必须补齐的两个基础系统：

- Map object definition：每种地图物件自己声明 texture、显示偏移、y-sort 点和碰撞 footprint。
- Playable boundary pass：生成可走区域后，沿边缘自动铺连续封边素材和 collision，不允许留下大面积黑色未定义区域。

它不是美术 polish 文档，而是工程规格。当前任务入口仍以 [../TASK_BOARD.md](../TASK_BOARD.md) 为准。

## 当前问题

当前 `first_outdoor_generated` 已经能生成地图结构、路线、怪物和基础 props，但还有两个核心问题：

- 单个 prop 的 collision 仍然主要由 texture size、source 和比例推导。树、石头、栅栏、洞口等物体没有独立 footprint 定义。
- 地图是在一个大矩形背景里放 zone / corridor。zone 外大片黑色区域既不像真实边界，也没有明确表达“不可走区域”。

这会导致两个后果：

- 玩家走到树、石头、洞口旁边时，碰撞感觉怪，像撞到图片外框。
- 生成地图看起来像 debug 图或烂尾地图，不像一块被自然边界封住的 outdoor playable area。

## 目标模型

地图生成需要明确区分：

```text
walkable area      = zone + corridor + 少量边缘缓冲
boundary band      = 沿 walkable area 外缘生成的连续封边素材
blocked / void     = 不可走、不可进入、不可被当作游戏区域
```

黑色 void 不能被视为普通可走背景。第一版可以继续使用简单底色，但可玩路线外侧必须有可读边界和 collision。

## Object Definition Catalog

新增或等价实现一个 object definition catalog：

```text
data/maps/map_object_defs.json
```

每个 object definition 至少包含：

```json
{
  "dead_tree_a": {
    "texture": "res://assets/sprites/props/outdoor_01/prop_outdoor01_dead_tree_64_a.png",
    "scale": 1.45,
    "sprite_offset": {"x": 0, "y": -46},
    "y_sort_origin": {"x": 0, "y": 0},
    "collision": {
      "shape": "capsule",
      "offset": {"x": 0, "y": -12},
      "radius": 12,
      "height": 30
    },
    "blocks_player": true,
    "tags": ["boundary", "tree"]
  }
}
```

规则：

- Object node 的 `position` 表示地面接触点 / foot point / y-sort point。
- `Sprite2D.position` 使用 `sprite_offset`，让图片相对 foot point 往上显示。
- `CollisionShape2D.position` 使用 `collision.offset`。
- `collision.shape` 第一版必须支持 `rect`、`circle`、`capsule`。
- 后续可以支持 `polygon`，但第一版不要做复杂 concave polygon。
- 不允许继续用 texture size + blocker_ratio 作为主要碰撞来源；只能作为缺失配置时的临时 fallback，并且必须在 validation 中警告。
- 注意：这里不是要求 collision 跟整张 sprite 像素框一致。对树、洞口、门这类高物体，collision 应该跟脚底 footprint 一致；视觉图可以很高，但碰撞只挡地面接触部分。

## Collision Shape Schema

Rect:

```json
{
  "shape": "rect",
  "offset": {"x": 0, "y": -8},
  "size": {"w": 58, "h": 14}
}
```

Circle:

```json
{
  "shape": "circle",
  "offset": {"x": 0, "y": -8},
  "radius": 18
}
```

Capsule:

```json
{
  "shape": "capsule",
  "offset": {"x": 0, "y": -10},
  "orientation": "vertical",
  "radius": 12,
  "height": 30
}
```

Capsule 规则：

- 第一版只要求支持 `vertical` capsule。
- Godot 2D 的 `CapsuleShape2D` 默认适合竖向 footprint，适合树干、柱子、竖向根部。
- 横向根须、横向墙、栅栏、石墙优先使用 `rect`，不要强行用 capsule。

示例选择：

- Tree / dead_tree：`capsule` 或小 `rect`，只挡树干和根部。
- Rock：`circle`。
- Broken fence / stone wall：`rect`。
- Corrupted root：`capsule` 或长 `rect`。
- Dungeon entrance / camp gate：可以由一个或多个 `rect` 组成；第一版如果只支持单 shape，就先用底部较窄的 `rect`。

## Boundary Generation Pass

生成器或 first outdoor scene builder 必须增加 boundary pass：

```text
1. 从 zones + corridors 生成 walkable mask / walkable cells。
2. 给 walkable area 增加少量 buffer，避免边界贴脸。
3. 找出 walkable area 的外缘 cells / segments。
4. 按方向选择边界素材：north/south/east/west/corner。
5. 沿边缘连续摆放 boundary object。
6. 每个 boundary object 使用 object definition 生成 Sprite2D 和 collision。
7. blocked / void 区域不可走。
```

V1 可以使用 tile-grid mask，不需要复杂 polygon：

```text
walkable cell
boundary cell
blocked cell
```

第一版固定使用一个明确的 `cell_size`：

- 推荐默认值：`64`。
- 如果当前素材密度过高，可以改成 `96`，但必须在 config / payload 里写明。
- 不允许实现里隐式使用多个 cell size。

Boundary coverage 定义：

- 每个 walkable cell 的外缘相邻 blocked / void cell，必须满足以下二选一：
  - 有 boundary object 覆盖。
  - 属于明确 opening anchor，例如 camp exit、dungeon entrance、next area soft gate。
- 最大连续视觉缺口不能超过 `2` 个 cell。
- 如果缺口超过 `2` 个 cell，必须在 validation 里报错，不只是 warning。

## Boundary Visual Rules

- 边界不能只靠四个大矩形 blocker。
- 边界必须看起来像自然封起来的 outdoor 区域。
- 第一版边界素材可以是 dead tree、rock、broken fence、corrupted root、stone wall placeholder 的混合。
- 主路两侧的 soft boundary 可以稀疏一点，但地图外缘必须连续封闭。
- 大片黑色 void 不能直接贴着主路或 zone。
- 如果 void 仍可见，必须在视觉上被边界隔开。

## Payload Requirements

生成 debug payload 时需要新增或等价表达：

```text
cell_size
walkable_cells
boundary_cells
blocked_cells 或 blocked_rects
boundary_objects
object_defs_used
```

每个 boundary object 至少包含：

```text
id
object_def
position
zone_or_edge_source
collision_shape
visual_id
blocker_id
```

## Validation Requirements

Smoke test 至少验证：

- 每个 placed prop 都能找到 object definition。
- Tree 使用 capsule 或明确配置的小 footprint，不是整图大矩形。
- Rock 使用 circle 或明确配置的圆/近似圆 footprint。
- Fence / wall 使用 rect。
- Capsule shape 如果出现，必须声明 `orientation`；第一版只接受 `vertical`。
- Object node position 是 foot point，sprite 使用 offset。
- Boundary objects 和 blockers 一一对应。
- Payload 包含明确 `cell_size`，只能是当前实现选择的单一值。
- walkable area 外缘有连续 boundary coverage。
- 每个 walkable cell 外缘相邻 blocked / void cell，要么有 boundary object，要么属于 opening anchor。
- 最大连续 boundary visual gap 不超过 `2` 个 cell。
- 玩家不能从 zone/corridor 直接走进 void。
- 玩家通路验证可以先用 payload 检查 blocked cells；如果做 physics smoke，则把 player 放到边界附近朝 void 方向移动若干 physics frames，确认不能进入 blocked / void cell。
- 不再只有四个外圈大 blocker 负责阻挡。
- 黑色 void 不能被当作可玩背景区域。

## 非目标

- 不做最终美术 polish。
- 不做完整地形自动美化。
- 不做 dungeon 生成。
- 不做复杂 NavMesh。
- 不做像素级 collision。
- 不要求第一版边界完美自然，但必须比 debug 黑底和零散 prop 更像封闭地图。
