---
name: demo-stage-game-dev
description: Use for this Godot 2D ARPG prototype when making gameplay, combat, enemy, skill, progression, or demo-scope decisions. Prioritize a small playable demo, combat feel, readable action, animation stability, hit feedback, and fast iteration over large systems or future-proof architecture.
---

# Demo Stage Game Development

## 目的

这个 skill 用来做 demo 阶段的玩法取舍，不是长期架构文档。

目标是做一个小而完整的 2D pixel ARPG demo，让玩家快速理解核心循环，并觉得 combat、loot、short-term growth 值得继续玩。

核心循环：

```text
move -> attack/cast -> hit feedback -> defeat enemies -> gain loot/XP/power -> continue fighting
```

## 和项目文档的关系

- `TASK_BOARD.md` 决定当前要做什么。
- `docs/PROJECT_PLAN.md` 决定长期 milestone。
- `docs/DEMO_SCOPE.md` 决定 demo 范围。
- `docs/AGENT_RULES.md` 决定通用 agent 工作规则，包括中文文档编码要求。
- 本 skill 只帮助 agent 在具体实现中做 demo-stage 取舍。

如果本 skill 和冻结文档冲突，以冻结文档为准。

## 文档编码要求

含中文的 Markdown 文档和项目 `SKILL.md` 必须保存为 UTF-8 with BOM。Windows PowerShell 读取 UTF-8 no BOM 中文文件时可能显示乱码，影响后续 agent 执行。

## 当前项目原则

优先做小范围、可试玩、可验证的改动。

但当前项目已经明确：核心系统不能是假系统。对于 `Item System`、`Progression System`、`Skill Tree`、`Hotbar` 这类已进入主线的系统，可以内容很少，但骨架必须真实，后续横向扩展时不应推倒重写。

也就是说：

- 不做无计划的大系统扩张。
- 不用 hardcoded shortcut 假装完成核心系统。
- 先纵向跑通一个职业和一条路线，再横向加内容。

## 优先级

优先做能改善这些点的改动：

- combat feel
- responsiveness
- readable gameplay
- stable animation
- satisfying hit feedback
- enemy pressure
- short-term power growth
- loot clarity
- fast in-game iteration

当取舍冲突时，选择能让 demo 更快变成可玩闭环的方案。

## 范围控制

除非用户或 `TASK_BOARD.md` 明确要求，不要主动扩展到：

- multiplayer
- procedural generation
- full save/load architecture
- economy
- crafting
- large UI framework
- ECS migration
- broad architecture rewrite

对于过大的需求，先收缩成 demo-stage 版本。但如果当前 task 明确要求系统骨架，就做真实骨架，不做一次性假实现。

## 实现倾向

Godot 代码保持简单、局部、可测试。

Prefer:

- 直接、清楚的 `CharacterBody2D` prototype 行为。
- 明确常量用于 timing、speed、damage、range、cooldown 调整。
- 小型 helper，只在减少真实重复时添加。
- 能在游戏里快速验证的实现。

Avoid:

- 不必要的 manager/singleton。
- 为未来猜测而做的抽象。
- 调手感时顺手改无关系统。
- 为了“架构漂亮”阻塞 playable demo。

## 验证问题

玩法改动完成前，至少回答：

- 新玩家能否在 30 秒内理解动作？
- 改动是否让 combat 更清楚或更 responsive？
- animation timing 和 hit timing 是否对齐？
- 是否能快速在 sandbox 或当前 demo 路线里验证？
