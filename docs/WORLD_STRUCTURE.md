# World Structure

这个文档冻结当前 world / map 结构方向。若它和旧任务描述冲突，以本文档为准。

## Core Decision

Prototype Alpha 采用类似 Diablo II 的“固定基地 + 半随机野外”体感，但不是传统 scene switching。

不要使用：

```text
Town.tscn -> 切换 -> Wilderness.tscn
```

当前目标结构是：

```text
MainWorld
  Player
  Camera2D
  FixedTown
  GeneratedRegion
```

Town / Base 应始终存在于同一个 world 坐标系里。玩家离开基地后，回头仍然能看到基地。

## Fixed Town

Town 是固定区域，不走 procedural generator。

Town 负责：

- 玩家出生点。
- 安全区。
- NPC / stash / quest placeholder。
- 营地出口。
- 与 wilderness 的视觉连续感。

Town 可以由用户手动调整布局和美术，但工程接口由 agent 固定：

```text
FixedTown
  TownSpawn
  TownBounds
  TownExitSocket
  Props
  NPCPlaceholders
  Interactables
```

## Generated Wilderness

Wilderness 不应作为独立地图 scene 切换进入。

它应该：

- 从 `TownExitSocket` 附近开始生成。
- instantiate 到同一个 `MainWorld` world space。
- 与 Town 无缝连接。
- 靠近 Town 的区域半固定，保证视觉连续。
- 离 Town 越远，随机性越强。

推荐层次：

```text
FixedTown
-> fixed transition chunk
-> wilderness entry chunk
-> random combat chunks
```

## Chunk Contract

第一版不要做超大开放世界，也不要过度工程化无限流式系统。

推荐先实现一次性 room / chunk graph assembly：

```text
TownExitSocket
-> TransitionChunk
-> EntryChunk
-> CombatChunk
-> ForkChunk
-> DungeonEntranceChunk
-> ElitePressureChunk
-> NextAreaHookChunk
```

每个 chunk 可以是单独 `.tscn`，并提供 connection markers：

```text
ChunkRoot
  NorthSocket
  EastSocket
  SouthSocket
  WestSocket
  GameplayBounds
  SpawnMarkers
  PropMarkers
```

Socket 命名可以按实际需要缩小，但必须数据可读、可测试、可复用。

## Generation Rule

优先保证 combat pacing，而不是追求巨大随机地图。

第一版生成策略：

- MainWorld 启动时生成一次 wilderness。
- 不做运行时无限 streaming。
- 不做远距离卸载 / 加载。
- 使用固定 anchor / socket 作为生成起点。
- 生成结果必须 deterministic by seed。
- Town 附近 chunk 半固定。
- 远离 Town 的 combat chunks 才做随机选择和随机组合。

## Anti-Goals

- 不使用 Town scene -> Wilderness scene 的传统切换作为主流程。
- 不 teleport 玩家到另一张地图。
- 不让 fixed town 变成 procedural start zone。
- 不为了“开放世界”牺牲 15-20 分钟 vertical slice。
- 不在当前阶段做复杂无限流式加载。

## Current Impact

旧的 `camp_scene -> first_outdoor_generated` transition 方案只能作为 rough layout / placeholder 参考。

后续任务必须把它收束到：

```text
MainWorld persistent scene
FixedTown child
GeneratedRegion child
same world coordinates
anchor-based wilderness expansion
```

