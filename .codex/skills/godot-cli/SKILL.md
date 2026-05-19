---
name: godot-cli
description: Use when Codex needs to run Godot CLI, Godot headless, console executable checks, smoke tests, GDScript script tests, or automated validation for this prototype-alpha Godot project. This skill is required because direct Godot CLI calls from Codex can crash when the sandbox cannot write the default LOCALAPPDATA.
---

# Godot CLI Workflow

## 必须使用 wrapper

从 Codex 运行 Godot 时，始终通过项目 wrapper：

```powershell
powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 --headless --path . --quit-after 90
```

不要直接调用 `Godot_v4.6.2-stable_win64_console.exe`。在这个 workspace 中，Codex sandbox 可能无法写入默认 `%LOCALAPPDATA%`，直接运行 Godot console/headless 有机会 signal 11 crash。

wrapper 会：

- 优先使用 `E:\GameDev\Godot_v4.6.2-stable_win64_console.exe`
- fallback 到 `E:\GameDev\Godot_v4.6.2-stable_win64.exe`
- 把 `LOCALAPPDATA`、`APPDATA`、`TEMP`、`TMP` 重定向到 `.codex_godot_env/`
- 转发所有参数给 Godot
- 返回 Godot exit code

## 常用命令

```powershell
powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 --version
powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 --headless --path . --quit-after 90
powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 --headless --path . --script res://tools/debug_combat_sandbox.gd
powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 --headless --path . --script res://tools/debug_player_inputs.gd
```

## 什么时候运行

Use headless checks for:

- script errors
- scene startup
- resource path errors
- null instance bugs
- input wiring
- deterministic state sampling
- combat / inventory / skill flow validation

只有视觉 framing、UI 观感或手感无法从日志判断时，才需要正常 Godot/editor playtesting。

## 输出纪律

Godot CLI 只在 runtime validation 可能发现静态检查看不到的问题时使用。

- 小代码改动优先 static inspection。
- scene/resource/null/input 问题跑一个短 headless smoke test。
- feel/AI 问题用窄 debug script 抽样关键帧。
- debug output 保持小，只打印关键状态，不打印完整 node dump。
- 最终报告总结关键 Godot output，不贴长日志。
