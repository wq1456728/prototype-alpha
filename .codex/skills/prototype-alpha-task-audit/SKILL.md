---
name: prototype-alpha-task-audit
description: Strict task-completion audit for this Godot 4.6 2D dark fantasy ARPG prototype. Use when Codex is asked to review whether a TASK_BOARD.md task is truly complete, verify acceptance criteria, audit implementation quality after a task agent reports done, or judge whether a change fits the project's Diablo II-like loot/progression logic and Chronicon-like control/UI/readability direction.
---

# Prototype Alpha Task Audit

## 目的

严格审查 task 是否真的完成。这个 skill 不是用来鼓励 task agent，也不是用来顺手修代码；它的目标是防止“看起来 done 但实际没有满足验收”的情况进入主线。

审查时只输出判断、证据、风险和下一步建议。除非用户明确要求，否则不要实现修复、不要改代码、不要重写任务。

## 必读上下文

审查任何任务前，必须读取：

1. `TASK_BOARD.md`
2. 目标 task 的完整条目，尤其是 `Goal`、`Focus`、`Acceptance`
3. 任务相关的冻结文档，通常包括：
   - `docs/PROJECT_PLAN.md`
   - `docs/DEMO_SCOPE.md`
   - `docs/CONTROL_AND_COMBAT.md`
   - `docs/ART_PIPELINE.md`
4. 当前改动：
   - `git status --short`
   - 目标 task 相关文件的 `git diff`

不要只相信 task agent 的总结。总结只能作为线索，不能作为完成证据。

如果审查涉及 runtime 行为、Godot scene loading、input、UI wiring、combat、inventory、skill usage、resource path，必须结合项目的 `godot-cli` skill，并通过 wrapper 运行验证：

```text
powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 ...
```

不要直接调用 Godot。

## 审查边界

这是 Task Audit，不是 Code Refiner。

Task Audit 只回答：

- 当前 task 是否满足 `TASK_BOARD.md` 中记录的验收标准？
- 实现是否存在会导致该 task 不能算完成的 bug、遗漏或回归？
- 任务声明的系统骨架是否真实存在，而不是临时 hardcoded shortcut？

Task Audit 不负责：

- 大范围重构建议
- 未来架构设计
- 目录和模块边界的阶段性体检
- 顺手整理代码风格
- 重新规划 task scope

如果发现结构问题，只在它影响当前 task 验收、运行稳定性或后续必须立即接上的系统路径时提出。否则把它标为 `Code Refiner follow-up`，不要让审查报告跑题。

## 参考标准

Diablo II 和 Chronicon 是方向参考，不是照抄要求。审查时用它们判断“这个实现是否符合项目精神”。

### Diablo II-like 逻辑

审查 item、progression、combat-growth、skill、quest、pacing 时，检查这些点：

- 玩家循环要形成清楚链路：kill enemies -> loot drops -> evaluate item -> equip/use -> stats or options improve -> kill faster or survive better -> gain XP -> level/skill growth。
- 掉落奖励应该像具体 `ItemInstance`，不是抽象 debug bonus。只要 task 涉及 loot，item 就应有 identity、rarity/quality、stats，以及进入 inventory/equipment 的路径。
- 系统内容可以很少，但骨架不能是假的。task 如果声称做 `Item System`、`Progression System`、`Skill Tree`、`Hotbar`，就必须有后续横向扩展时不推倒重写的核心路径。
- 变强必须可读。玩家应能知道自己为什么变强：装备了 item、level-up、skill unlock、active skill use。
- Skill progression 必须尊重要求：level gates、prerequisites、rank/cost、learned/unlearned state。基础攻击是 baseline action，不是 learned tree skill，除非主计划明确改变。
- Combat 应该保持 ARPG demo 的可读节奏。不要让 sandbox 变成高速动作乱斗，除非 task 明确要求。
- Boss、elite、objective 应该测试成长链路。强敌应该奖励玩家使用已获得的成长，而不是只用不透明数值惩罚玩家。

### Chronicon-like 修正方向

审查 controls、camera/view、UI、hotbar、skill use、readability、asset integration 时，检查这些点：

- WASD 是基础移动方式。鼠标方向主要服务于 aiming/casting/attacking，不是 click-to-move。
- 项目选择 pseudo top-down / flat readable presentation，避免 Diablo II 45 度 isometric 对美术资源的高消耗。
- 正常移动时，角色朝向应跟随移动方向；attack/cast/action 期间可以临时朝向 mouse/aim direction。
- Active skills 应该属于底部可见 `Hotbar` 或等价 action surface。只要 task 涉及 loadout，learned active skill 应先安装到 slot 再使用。
- UI 必须足够大、screen-safe，并且默认窗口可用。task 如果声明做 playable UI，debug-sized panel 不能算通过。
- Icon、slot frame、cooldown、label、tooltip 应该服务于快速可读。placeholder art 可以接受，但信息结构必须是真的。
- `Skill Tree`、`Inventory`、`Equipment`、`Hotbar`、`Objective` 应该职责清楚。不要用一个临时 debug panel 控制所有东西。

## 审查流程

1. 确认 task id 和完整 acceptance criteria。
2. 把每一条 acceptance 映射到证据：
   - code path
   - scene/resource path
   - config/data path
   - runtime validation result
   - 或明确写 `not verified`
3. 检查实现 diff 和相关已有代码。
4. 行为相关任务必须做窄验证。优先使用已有 smoke/debug scripts，再考虑补临时检查。
5. 按严重程度分类问题。
6. 给出明确 verdict：
   - `pass`
   - `pass with risks`
   - `fail`
   - `blocked / cannot verify`

## 严格判定规则

- 只要有一个 acceptance criterion 没满足，默认不能给 `pass`。
- 如果 acceptance 明确失败，verdict 应为 `fail`，除非失败项确实是非核心且用户接受风险，此时最多 `pass with risks`。
- `not verified` 不是成功。未验证项必须进入 `Risks` 或导致 `blocked / cannot verify`。
- “大部分完成”不能等于完成。必须逐条对照验收。
- 如果 task 要求 reusable skeleton，但实现只是 hardcoded shortcut，必须列为 finding。
- 如果 task 要求 playable UI，但功能只能通过 debug controls 使用，必须判定相关 UI acceptance 失败。
- 如果 task 说 config-backed / data-driven，必须确认 config 被实际加载和使用，不能只看见 JSON 文件就算通过。
- 如果没有运行 runtime validation，必须说明为什么没跑，以及哪些内容因此仍未证明。
- 不要在 audit 中改写 task scope。如果 task 本身过大或不合理，可以单独作为风险说明，但仍然按已记录的 acceptance 审查。
- 不要擅自修改 `TASK_BOARD.md` 状态。只有用户明确要求记录审查结果时，才添加简短 `Audit Status`，并且不能掩盖失败项。

## 严重程度

- `P0`：项目无法运行、数据损坏、主流程阻断、破坏之前已工作的核心 loop。
- `P1`：明确 acceptance 失败、造成虚假完成、破坏主要玩家可见行为。
- `P2`：风险、缺少验证、粗糙问题、可维护性问题、demo 质量问题，但不阻断主任务。
- `P3`：小清理或 polish 建议。

Finding 尽量附上文件路径和行号。没有行号时，也要给出可定位的文件、节点、函数、config key 或 scene path。

## 输出格式

输出必须先给 findings。不要先写鼓励性总结。

使用这个格式：

```text
Verdict: pass | pass with risks | fail | blocked / cannot verify

Findings:
- [P1] 标题
  Evidence:
  Impact:
  Required fix:

Acceptance Map:
- Criterion:
  Status: pass | fail | not verified
  Evidence:

Validation:
- Commands run:
- Result:
- Not run / why:

Diablo II / Chronicon Fit:
- Diablo II-like loop fit:
- Chronicon-like control/UI/readability fit:

Risks:
- ...

Recommended Next Action:
- ...
```

如果没有 findings，必须明确写“没有发现阻断问题”，但仍然列出残余风险或未验证区域。
