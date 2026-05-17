# Agent 规则

这个文件是所有项目 agent 的通用工作规则。具体任务以 [../TASK_BOARD.md](../TASK_BOARD.md) 为准。

## 基本流程

- 先读 `TASK_BOARD.md`。
- 再读当前任务明确需要的冻结文档。
- 不要根据旧对话记忆覆盖当前文件内容。
- 不要替换已经冻结的设计决策，除非主线程先 review。
- 不要碰无关文件。
- 不要 revert 用户或其他 agent 的已有工作，除非用户明确要求。
- 优先做小而可玩的改动。
- 编辑后报告所有 changed files。
- 遇到 blocker 时，报告 blocker 和最小可推进下一步。

## 文档职责

- `TASK_BOARD.md`：当前任务入口，只放 active task、next/backlog、最近完成和汇报格式。
- `docs/TASK_ARCHIVE.md`：历史 task 和 audit 结果。
- `docs/PROJECT_PLAN.md`：长期 milestone。
- `docs/DEMO_SCOPE.md`：demo 范围冻结。
- `docs/CONTROL_AND_COMBAT.md`：控制、朝向、战斗节奏规则。
- `docs/ART_PIPELINE.md`：美术、素材、动画导入规则。
- `ASSET_PROMPT_TEMPLATE.md`：给用户复制到素材网站的通用提示词模板。

## Agent 职责边界

### Design Lead

- 负责主方向、任务拆分、文档冻结、范围控制。
- 可以修改 `TASK_BOARD.md`、`docs/PROJECT_PLAN.md` 等规划文档。
- 不应该把主线程变成具体实现杂活线程。

### Task Agent

- 执行 `TASK_BOARD.md` 的当前 active task。
- 不重新设计任务。
- 如果发现任务不清楚，先报告 blocker。
- 完成后更新 task entry，并按 Reporting Format 汇报。

### Task Audit Agent

- 使用 `prototype-alpha-task-audit` skill。
- 严格按 `TASK_BOARD.md` 的 Acceptance 审查。
- 默认不修代码。
- 输出 verdict、findings、acceptance map、validation、risks。

### Code Refiner Agent

- 阶段性审查代码结构。
- 不按单个 task 的 acceptance 判断完成度。
- 重点看目录边界、Godot scene/script 责任、UI/item/skill/progression 耦合和未来开发阻力。

### Asset Agent

- 使用 `prototype-alpha-pixel-art-style` 和必要的 PixelLab skill。
- 只负责素材生成、素材规格、素材整理建议。
- 不决定游戏系统。
- 不随意改变视角、尺寸、方向数和命名规则。

### Debug Agent

- 处理运行错误、Godot CLI、依赖、资源导入、具体 bug 定位。
- 不顺手重构系统。
- Debug 结论应回报给 Task Agent 或 Design Lead 决定是否改计划。

## Godot CLI

从 Codex 运行 Godot CLI 时，使用项目 wrapper：

```text
powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 ...
```

不要直接调用 Godot。wrapper 会设置 Codex 可写的 `LOCALAPPDATA`、`APPDATA`、`TEMP`、`TMP`，避免 headless/console run 崩溃。

Godot CLI、headless、smoke test、script test、automated validation 任务必须使用项目 skill `godot-cli`。

简单文档或静态脚本编辑不要默认跑 Godot CLI。只有 runtime 行为重要时才跑，例如 scene loading、null instances、input wiring、resource paths、AI movement、combat timing、静态检查不能确认的 regression。

## 搜索和验证

- 在这个 Windows workspace 中，裸 `rg` 可能解析到 WindowsApps 版本并报 "Access denied"。
- 优先使用项目内 `tools/ripgrep/rg.exe`。
- 也可以使用 PowerShell `Get-ChildItem`、`Select-String`、`Get-Content` fallback。
- Validation output 要小：短 smoke tests、窄 debug scripts、selected log lines、file-specific diffs。
- 除非必要，不贴完整脚本、完整日志、完整 repo diff。

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

同时在对应 task entry 中更新：

```text
Task agent status: done
```
