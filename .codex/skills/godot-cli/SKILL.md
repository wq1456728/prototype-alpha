---
name: godot-cli
description: Use when Codex needs to run Godot CLI, Godot headless, console executable checks, smoke tests, GDScript script tests, or automated validation for this prototype-alpha Godot project. This skill is required because direct Godot CLI calls from Codex can crash when the sandbox cannot write the default LOCALAPPDATA.
---

# Godot CLI Workflow

Always run Godot through the project wrapper:

```powershell
powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 --headless --path . --quit-after 90
```

Do not call `Godot_v4.6.2-stable_win64_console.exe` directly from Codex. In this workspace, the Codex sandbox cannot write the default `%LOCALAPPDATA%`, which can make console/headless Godot crash with signal 11.

The wrapper:

- prefers `E:\GameDev\Godot_v4.6.2-stable_win64_console.exe`
- falls back to `E:\GameDev\Godot_v4.6.2-stable_win64.exe`
- redirects `LOCALAPPDATA`, `APPDATA`, `TEMP`, and `TMP` to `.codex_godot_env/`
- forwards all arguments to Godot
- returns Godot's exit code

Common commands:

```powershell
powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 --version
powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 --headless --path . --quit-after 90
powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 --headless --path . --script res://tools/debug_combat_sandbox.gd
powershell -ExecutionPolicy Bypass -File tools\run_godot.ps1 --headless --path . --script res://tools/debug_player_inputs.gd
```

Use headless checks for script errors, scene startup, state sampling, and deterministic input simulations. Use normal Godot/editor playtesting only when visual framing or feel cannot be judged from logs.

## Output Discipline

Use Godot CLI only when runtime validation is likely to catch something static inspection cannot.

- For small code edits, prefer targeted file reads and static checks.
- For scene/resource/null-instance/input bugs, run one short headless smoke test.
- For feel/AI questions, use narrow debug scripts with a few sampled frames.
- Keep debug script output compact; print only key state, not full node dumps.
- Prefer `git diff --stat` or file-specific diffs over full repository diffs.
- In final reports, summarize the important Godot output instead of pasting long logs.
