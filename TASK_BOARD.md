# 任务板

这个文件是其他对话或 agent 的任务入口。它只保留当前任务和最近上下文；历史任务、通用规则和长期计划放在独立文档里。

## 必读入口

当前规划、范围和实现规则以这些文件为准：

- [README.md](README.md)
- [docs/PROJECT_PLAN.md](docs/PROJECT_PLAN.md)
- [docs/DEMO_SCOPE.md](docs/DEMO_SCOPE.md)
- [docs/CONTROL_AND_COMBAT.md](docs/CONTROL_AND_COMBAT.md)
- [docs/ART_PIPELINE.md](docs/ART_PIPELINE.md)
- [docs/AGENT_RULES.md](docs/AGENT_RULES.md)
- [docs/TASK_ARCHIVE.md](docs/TASK_ARCHIVE.md)
- [ASSET_PROMPT_TEMPLATE.md](ASSET_PROMPT_TEMPLATE.md)

如果旧笔记和上面文件冲突，以上面文件为准。

## 当前阶段

`combat_sandbox` 的纵向系统链路已经跑通：combat、loot、inventory/equipment、XP/level、skill unlock、Hotbar assignment、objective completion 都已有第一版。

当前进入第一张 outdoor map 前的规划阶段。

## 当前目标

把 sandbox 中已经证明可用的纵向链路翻译成第一张 outdoor map 的 5-10 分钟路线：

```text
spawn / camp
-> light quest prompt
-> outdoor combat
-> first item drop
-> equip / power gain
-> level-up
-> skill unlock
-> Hotbar skill use
-> elite or pressure moment
-> dungeon entrance
```

原则：先纵向拉通一个职业和一条路线，再横向扩职业、怪物、装备槽和技能数量。

## 当前任务

### TASK-019: First Outdoor Greybox Plan

Status: ready

Goal:

规划第一张 outdoor map。这个任务先做计划，不直接实现地图。计划要把当前 sandbox objective flow 翻译成真实 demo 路线，并明确哪些系统直接复用。

Focus:

- 设计 5-10 分钟 outdoor route。
- 定义 spawn / camp、combat zones、first item drop moment、level-up moment、first skill unlock moment、Hotbar skill-use moment、elite pressure moment、dungeon entrance。
- 明确如何复用当前 `Inventory`、`Skill Tree`、`Hotbar`、item、XP、objective 系统。
- 明确 outdoor route 中每个节点要验证的玩家体验。
- 暂时不加第二职业。
- 暂时不实现 dungeon。
- 暂时不做大范围数值平衡。

Acceptance:

- 计划能说明 sandbox vertical loop 如何变成 5-10 分钟 outdoor segment。
- 计划列出 outdoor map 的最小区域结构和玩家路线。
- 计划列出每个路线节点对应的系统验证点。
- 计划复用已验证系统，不重新发明新系统。
- 计划不依赖第二职业。
- 完成后在本任务条目下写入 `Task agent status: done`。

## Next / Backlog

### TASK-020: First Outdoor Greybox Implementation

Status: blocked by TASK-019

Goal:

按 `TASK-019` 的计划实现第一张 outdoor greybox 的最小可玩版本。

### TASK-021: Outdoor Objective And Dungeon Entrance Hook

Status: blocked by TASK-020

Goal:

把 outdoor route 接入 objective flow，并让 dungeon entrance 成为清晰的下一阶段入口。

### TASK-022: Outdoor Combat Feel And Route Pass

Status: blocked by TASK-021

Goal:

调整 outdoor 敌人密度、路线节奏、早期掉落和 skill 使用时机，让 5-10 分钟 outdoor 段落可读、可玩。

## Later / Horizontal Expansion

这些任务有意延后。先用一个职业把 outdoor vertical route 跑通，再横向扩内容。

- `LATER-001 Mage Prototype Plan`：第二职业，等 knight 路线跑通后再做。
- `LATER-002 Second Enemy Family`：当前 item/XP/route 节奏验证后再加。
- `LATER-003 More Equipment Slots`：`weapon` 已验证后，再激活 `chest`、`accessory` 等槽位。
- `LATER-004 Dungeon Greybox`：outdoor segment 证明后，再做 dungeon。

## 最近完成

### TASK-018: Diablo-like UI Scale, Skill Tree, And Hotbar Rework

Status: done

Task agent status: done

Audit Status:

- 2026-05-17 re-audit: pass with risks。
- Runtime validation passed for sandbox structure/UI、player inputs/loadout、combat/progression。
- `B` inventory 和 `K` skill tree 互斥；large panel 打开时 debug/objective UI 会隐藏；objective panel 在右上角。
- `Skill Tree` 已有 `heavy_strike -> shield_charge -> shield_training` 前置路径。
- `Hotbar` 已改为 bottom-center、config-backed、click slot -> icon picker -> choose learned active skill。
- 风险：当前 skill tree 仍是 vertical prerequisite-card path，不是真正 Diablo II-style icon grid/tree；如果之后追求更接近 Diablo II，需要单独任务。
- 风险：headless smoke 验证了 bounds/focus/overlap，但没有替代人工截图审查。

完整历史见 [docs/TASK_ARCHIVE.md](docs/TASK_ARCHIVE.md)。

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
