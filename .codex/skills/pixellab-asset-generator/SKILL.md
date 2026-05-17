---
name: pixellab-asset-generator
description: Generate, inspect, animate, and prepare game-ready pixel art assets through the configured PixelLab MCP server. Use when Codex needs to create characters, enemies, props, weapons, icons, skill effects, map objects, top-down/Wang tilesets, sidescroller tilesets, isometric tiles, object variants, or PixelLab animations for this Godot prototype; also use when checking PixelLab job status or downloading/importing generated assets.
---

# PixelLab Asset Generator

## Overview

Use the PixelLab MCP tools directly to create project assets, then prepare the completed PNG/ZIP output for Godot. PixelLab MCP creation tools are asynchronous: submit the job, keep the returned UUID, and check completion with the matching `get_*` tool.

## First Rules

- Use PixelLab MCP tools, not REST calls, for `/mcp` workflows. If PixelLab tools are unavailable, tell the user MCP is not loaded instead of trying to curl the MCP endpoint.
- Pair this skill with `prototype-alpha-pixel-art-style` before generating visual assets for this project. Rewrite vague or Chinese asset requests into an English production prompt that matches the project style.
- Pair with `godot-sprite-animation` when importing, slicing, aligning, or wiring character sprite sheets or animation frames.
- Keep API tokens out of generated files, logs, and final responses.
- For destructive PixelLab actions such as `delete_object` or `delete_character`, only proceed when the user explicitly asks.

## Workflow

1. Clarify the asset type from the request: character, animation, object, map object, top-down tileset, sidescroller tileset, isometric tile, or tile variations.
2. Rewrite the visual prompt using the project pixel-art style rules unless the user gave a strict prompt.
3. Choose the smallest suitable PixelLab tool. Prefer one-direction/static object generation for icons and props; use multi-direction assets only when gameplay needs rotation.
4. Submit the PixelLab MCP job and record the returned UUID in the response or implementation notes.
5. Poll with the matching `get_*` tool when the user asks for status, when importing into Godot, or after enough time has passed.
6. When complete, download or reference the returned PNG/ZIP URL and place assets under the existing project asset tree, usually `assets/raw`, `assets/processed`, `assets/sprites`, `assets/animations`, `assets/vfx`, or `assets/ui` based on usage.
7. Validate transparent background, canvas size, pixel readability, frame consistency, and Godot import readiness before wiring gameplay.

## Tool Selection

- Characters: use `create_character`, `get_character`, `animate_character`, `create_character_state`, `list_characters`.
- Static props, weapons, pickups, icons, and object rotations: use `create_object`, `get_object`, `create_object_state`, `animate_object`, `list_objects`.
- In-map decorations with transparent background and optional style matching: use `create_map_object`, `get_map_object`.
- Top-down terrain transitions for Godot TileMaps: use `create_topdown_tileset`, `get_topdown_tileset`, `list_topdown_tilesets`.
- Sidescroller platform terrain: use `create_sidescroller_tileset`, `get_sidescroller_tileset`.
- Individual isometric blocks/items: use `create_isometric_tile`, `get_isometric_tile`.
- Multiple shaped tile variations: use `create_tiles_pro`, `get_tiles_pro`.

See `references/pixellab-mcp.md` for a compact parameter guide.

## PixelLab Job Handling

- Creation tools return immediately. Do not assume the asset is complete until the matching `get_*` result says completed and provides image/download URLs.
- It is valid to queue template animations immediately after character creation if the character ID is available.
- For custom character animations without `template_animation_id`, first call without `confirm_cost` to inspect the generation cost, show the user the cost and cheaper template-animation option, then set `confirm_cost=true` only after explicit approval.
- For `create_object` with `directions=1` and `n_frames > 1`, expect review status. Use `get_object` to inspect candidates, then `select_object_frames` to keep chosen indices or `dismiss_review` if none are usable.
- Download URLs use UUIDs as access keys. Treat them as shareable but avoid posting unnecessary links in code or docs.

## Godot Import Guidance

- Keep originals separate from processed Godot-ready files. Use existing folders rather than creating a new asset hierarchy unless the task needs one.
- Prefer transparent PNGs and regular grids for sprite sheets.
- For characters, preserve stable frame size and bottom-center pivot expectations.
- For terrain, prefer PixelLab Wang/top-down tilesets when the request is for seamless TileMap transitions.
- When wiring assets into scenes or scripts, verify with project conventions before adding new loaders, resources, or naming schemes.

## Status Response Pattern

When reporting a PixelLab generation result to the user, include:

- Asset type and prompt summary.
- PixelLab UUID.
- Current status: queued, processing, review, completed, or failed.
- Next action: wait/check later, select review frames, download/import, or revise prompt.

Source documentation: https://api.pixellab.ai/mcp/docs
