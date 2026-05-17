# Prototype Alpha

Prototype Alpha 是一个 Godot 4.6 2D dark fantasy ARPG demo。

当前目标是做一个 15-20 分钟 Windows vertical slice：Diablo II-like 的刷宝和成长节奏，Chronicon-like 的 WASD 控制，以及 pseudo top-down pixel-art 表现。

## 文档入口

当前 source of truth：

- [任务板](TASK_BOARD.md)：当前任务、下一步和最近完成。
- [项目计划](docs/PROJECT_PLAN.md)：长期 milestone。
- [Demo 范围](docs/DEMO_SCOPE.md)：15-20 分钟 demo 的冻结范围。
- [控制和战斗规则](docs/CONTROL_AND_COMBAT.md)：WASD、朝向、战斗节奏、反馈规则。
- [美术管线](docs/ART_PIPELINE.md)：视角、像素风格、动画和素材导入规范。
- [Agent 规则](docs/AGENT_RULES.md)：不同 agent 的通用工作规则。
- [任务归档](docs/TASK_ARCHIVE.md)：已完成任务和审查结果。
- [素材提示词模板](ASSET_PROMPT_TEMPLATE.md)：给素材网站复制使用的通用 prompt。

如果旧笔记和上面文件冲突，以上面文件为准。

## 当前 Demo 目标

- 一张 outdoor map。
- 一个可进入 dungeon。
- 一个 small boss。
- 一条轻量 quest thread。
- 两个职业原型：paladin-style melee 和 mage-style ranged。
- WASD movement，鼠标控制 attack/skill 方向。
- Loot、equipment、level growth、skill unlocks，以及支撑这些系统的 UI。

## 核心循环

```text
move
-> attack / cast
-> hit feedback
-> defeat enemies
-> gain experience and loot
-> equip or unlock power
-> push deeper
```

## 当前优先级

- Combat feel。
- Readable movement and facing。
- Stable sprite animation。
- Satisfying hit feedback。
- Enemy pressure。
- Short-term power growth。
- Loot clarity。
- Fast in-game iteration。

## 范围控制

除非 demo 明确重新定范围，否则不要做：

- Multiplayer。
- Procedural dungeon generation。
- Full save/load architecture。
- Large skill trees。
- Rune systems。
- Crafting。
- Economy。
- Large UI frameworks。
- Broad architecture rewrites。

## 每次加功能前检查

- 它是否改善 combat？
- 它是否改善 loot？
- 它是否改善 growth？
- 它能不能快速在游戏里验证？
