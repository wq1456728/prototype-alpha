# Outdoor Terrain Asset List

这个文档给用户和素材 agent 使用，目标是先补齐第一张 outdoor map 的 P0 地表词汇表。它不是最终美术清单，也不是要求一次性生成全部素材。

从 `TASK-027` 开始，task agent 就要盘点当前素材，并把能拿到的 P0 Camp / outdoor / terrain 素材先纳入项目。`TASK-029` 负责补齐缺口和冻结状态，不再从零开始盘点。`TASK-028` 已调整为 persistent `MainWorld` / `FixedTown` / `GeneratedRegion` 结构重构。

## 设计原则

第一张 outdoor map 的视觉目标是 dark fantasy ARPG outdoor，不直接复制 Diablo II，但参考它第一幕野外的阅读方式：

- 玩家看到的是一片野外，不是一串 debug 方块。
- Road 是视觉引导，不是唯一可走区域。
- Logic corridor 可以宽，visual road 应该窄。
- 地面需要 base + transition + patch + decal，不要整块纯色铺满。
- 腐化区域要像局部侵蚀，不要整块矩形。
- Boundary 用石头、枯树、断栅栏、腐化根须等形成软封边。
- 第一轮每类素材最多 1-2 个 variation，先保证风格统一。

## 通用规格

Style:

```text
dark fantasy pixel art, pseudo top-down / high top-down compatible, readable ground silhouettes, muted natural colors, low saturation, no cute style, no modern objects, no UI frame baked into the asset
```

Sizes:

```text
Terrain tiles: 32x32 per tile
Small decals: 32x32 or 64x64 transparent PNG
Medium props: 64x64 or 96x96 transparent PNG
Large landmarks: 128x128 or 160x160 transparent PNG
Tileset sheet: 32px grid, no padding unless documented
```

Delivery:

```text
Terrain tile groups: tileset sheet preferred
Props / landmarks / decals: transparent background single PNG preferred
Raw AI output: put under raw area first
Accepted gameplay assets: put under assets/sprites with project naming
```

Status labels:

```text
available: 项目里已有，可直接暂用
placeholder: 项目里已有，但质量 / 风格 / 用途只是临时占位
missing: 当前没有，需要用户或素材 agent 获取
accepted: 用户确认可作为当前阶段 gameplay asset
```

Naming pattern:

```text
tile_outdoor01_<name>_32.png
tileset_outdoor01_<name>_32.png
decal_outdoor01_<name>_<size>_<variant>.png
prop_outdoor01_<name>_<size>_<variant>.png
```

## Current Available Assets

当前仓库里已经能看到这些 outdoor P0 可暂用素材：

```text
assets/sprites/tiles/outdoor_01/tileset_outdoor01_ground_32.png
assets/sprites/tiles/outdoor_01/tile_outdoor01_corrupted_ground_32.png
assets/sprites/props/outdoor_01/prop_outdoor01_camp_gate_128.png
assets/sprites/props/outdoor_01/prop_outdoor01_corrupted_hollow_128.png
assets/sprites/props/outdoor_01/prop_outdoor01_signpost_64.png
assets/sprites/props/outdoor_01/prop_outdoor01_shrine_96.png
assets/sprites/props/outdoor_01/prop_outdoor01_broken_cart_96.png
assets/sprites/props/outdoor_01/prop_outdoor01_rock_small_32_a.png
assets/sprites/props/outdoor_01/prop_outdoor01_rock_small_32_b.png
assets/sprites/props/outdoor_01/prop_outdoor01_dead_tree_64_a.png
assets/sprites/props/outdoor_01/prop_outdoor01_dead_tree_64_b.png
assets/sprites/props/outdoor_01/prop_outdoor01_broken_fence_64_a.png
assets/sprites/props/outdoor_01/prop_outdoor01_broken_fence_64_b.png
assets/sprites/props/outdoor_01/prop_outdoor01_corrupted_roots_64_a.png
assets/sprites/props/outdoor_01/prop_outdoor01_corrupted_roots_64_b.png
```

Current read after TASK-029 asset follow-up:

- Boundary / landmark placeholders are enough to start Camp and outdoor rough layout.
- Road / transition / decal vocabulary now has named `available` files for the first terrain paint pass.
- New PixelLab Camp support props and decals are in `assets/sprites`, but they are `available`, not `accepted`; user review is still required before treating them as final gameplay art.
- `TASK-029` uses the table below as the frozen current contract. Older TASK-027 tables are retained for history and rough category notes.

## TASK-029 Frozen Inventory

`accepted` 仍只表示用户明确确认。下面新补入的素材全部标为 `available`，供后续 `TASK-031` terrain paint / Camp polish 使用。

| ID | Priority | Use case | Asset type | Required form | Size | Transparency | Naming pattern | Current path | Fallback path | Status | Blocks TASK-031 | Owner / next action |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `grass_dead_base` | P0 | outdoor base ground | terrain | single tile / tileset | 32x32 | no | `tile_outdoor01_grass_dead_base_32_a.png` | `assets/sprites/tiles/outdoor_01/tile_outdoor01_grass_dead_base_32_a.png` | `assets/sprites/tiles/outdoor_01/tileset_outdoor01_ground_32.png` | available | no | user review visual quality |
| `dirt_base` | P0 | dry dirt field / camp floor | terrain | tileset fallback | 32x32 | no | `tileset_outdoor01_ground_32.png` | `assets/sprites/tiles/outdoor_01/tileset_outdoor01_ground_32.png` | none | placeholder | no | replace with dedicated tile later |
| `mud_trampled_base` | P0 | trampled camp / pressure areas | terrain/decal | decal first pass | 64x64 | yes | `decal_camp01_trampled_ground_64_a.png` | `assets/sprites/decals/outdoor_01/decal_camp01_trampled_ground_64_a.png` | none | available | no | user review visual quality |
| `dirt_road_center` | P0 | readable road spine | terrain | single tile variations | 32x32 | no | `tile_outdoor01_dirt_road_center_32_<variant>.png` | `assets/sprites/tiles/outdoor_01/tile_outdoor01_dirt_road_center_32_a.png`, `assets/sprites/tiles/outdoor_01/tile_outdoor01_dirt_road_center_32_b.png` | none | available | no | TASK-031 integrate into paint rules |
| `dirt_road_edge_blend` | P0 | road edge into field | terrain | single tile variations | 32x32 | no | `tile_outdoor01_dirt_road_edge_32_<variant>.png` | `assets/sprites/tiles/outdoor_01/tile_outdoor01_dirt_road_edge_32_a.png`, `assets/sprites/tiles/outdoor_01/tile_outdoor01_dirt_road_edge_32_b.png` | none | available | no | TASK-031 integrate into paint rules |
| `dirt_road_corner_blend` | P0 | road bends / forks | terrain | single tile variations | 32x32 | no | `tile_outdoor01_dirt_road_corner_32_<variant>.png` | `assets/sprites/tiles/outdoor_01/tile_outdoor01_dirt_road_corner_32_a.png`, `assets/sprites/tiles/outdoor_01/tile_outdoor01_dirt_road_corner_32_b.png` | none | available | no | TASK-031 integrate into paint rules |
| `dirt_road_end_fade` | P0 | road end / fade into field | terrain | single tile | 32x32 | no | `tile_outdoor01_dirt_road_end_fade_32_a.png` | `assets/sprites/tiles/outdoor_01/tile_outdoor01_dirt_road_end_fade_32_a.png` | none | available | no | TASK-031 integrate into paint rules |
| `road_noise_decal` | P0 | break up road repetition | decal | transparent PNG | 64x64 | yes | `decal_outdoor01_road_noise_64_a.png` | `assets/sprites/decals/outdoor_01/decal_outdoor01_road_noise_64_a.png` | none | available | no | use sparingly in terrain paint |
| `grass_to_dirt_transition` | P0 | soft field to dirt edge | terrain | single transition tile | 32x32 | no | `tile_outdoor01_grass_to_dirt_blend_32_a.png` | `assets/sprites/tiles/outdoor_01/tile_outdoor01_grass_to_dirt_blend_32_a.png` | none | available | no | TASK-031 integrate into paint rules |
| `dirt_to_corruption_blend` | P0 | corrupted approach | terrain | single transition tile | 32x32 | no | `tile_outdoor01_dirt_to_corruption_blend_32_a.png` | `assets/sprites/tiles/outdoor_01/tile_outdoor01_dirt_to_corruption_blend_32_a.png` | none | available | no | TASK-031 integrate into paint rules |
| `corruption_edge_blend` | P0 | irregular corruption edge | terrain | single transition tile | 32x32 | no | `tile_outdoor01_corruption_edge_blend_32_a.png` | `assets/sprites/tiles/outdoor_01/tile_outdoor01_corruption_edge_blend_32_a.png` | none | available | no | TASK-031 integrate into paint rules |
| `corrupted_ground_patch` | P0 | infected ground patch | terrain | single tile | 64x32 | mixed | `tile_outdoor01_corrupted_ground_32.png` | `assets/sprites/tiles/outdoor_01/tile_outdoor01_corrupted_ground_32.png` | none | placeholder | no | replace with better patch later |
| `root_stain_decal` | P0 | corruption detail | decal | transparent PNG | 64x64 | yes | `decal_outdoor01_root_stain_64_a.png` | `assets/sprites/decals/outdoor_01/decal_outdoor01_root_stain_64_a.png` | none | available | no | user review visual quality |
| `dark_crack_decal` | P0 | corruption detail | decal | transparent PNG | 64x64 | yes | `decal_outdoor01_dark_crack_64_a.png` | `assets/sprites/decals/outdoor_01/decal_outdoor01_dark_crack_64_a.png` | none | available | no | currently shares source generation with root stain |
| `thorn_weed_decal` | P1 | corrupted small detail | decal | transparent PNG | 32x32 | yes | `decal_outdoor01_thorn_weed_32_a.png` | `assets/sprites/decals/outdoor_01/decal_outdoor01_thorn_weed_32_a.png` | none | available | no | optional scatter pass |
| `rock_small` | P0 | boundary blocker | prop | transparent PNG | 32x32 | yes | `prop_outdoor01_rock_small_32_<variant>.png` | `assets/sprites/props/outdoor_01/prop_outdoor01_rock_small_32_a.png`, `assets/sprites/props/outdoor_01/prop_outdoor01_rock_small_32_b.png` | none | available | no | already used by boundary pass |
| `dead_tree` | P0 | soft boundary / landmark noise | prop | transparent PNG | 64x64 | yes | `prop_outdoor01_dead_tree_64_<variant>.png` | `assets/sprites/props/outdoor_01/prop_outdoor01_dead_tree_64_a.png`, `assets/sprites/props/outdoor_01/prop_outdoor01_dead_tree_64_b.png` | none | available | no | already used by boundary pass |
| `broken_fence` | P0 | outdoor/camp rough boundary | prop | transparent PNG | 64x64 | yes | `prop_outdoor01_broken_fence_64_<variant>.png` | `assets/sprites/props/outdoor_01/prop_outdoor01_broken_fence_64_a.png`, `assets/sprites/props/outdoor_01/prop_outdoor01_broken_fence_64_b.png` | none | available | no | already used by boundary pass |
| `corrupted_root_wall` | P0 | dungeon-side blocker | prop | transparent PNG | 64x64 | yes | `prop_outdoor01_corrupted_roots_64_<variant>.png` | `assets/sprites/props/outdoor_01/prop_outdoor01_corrupted_roots_64_a.png`, `assets/sprites/props/outdoor_01/prop_outdoor01_corrupted_roots_64_b.png` | none | available | no | already used by boundary pass |
| `camp_gate` | P0 | town/camp exit marker | prop | transparent PNG | 128x128 | yes | `prop_outdoor01_camp_gate_128.png` | `assets/sprites/props/outdoor_01/prop_outdoor01_camp_gate_128.png` | none | available | no | current camp exit marker |
| `dungeon_entrance` | P0 | first quest hook | prop | transparent PNG | 128x128 | yes | `prop_outdoor01_corrupted_hollow_128.png` | `assets/sprites/props/outdoor_01/prop_outdoor01_corrupted_hollow_128.png` | none | available | no | current dungeon hook |
| `next_area_marker` | P1 | route/soft gate marker | prop | transparent PNG | 64x64 | yes | `prop_outdoor01_signpost_64.png` | `assets/sprites/props/outdoor_01/prop_outdoor01_signpost_64.png` | none | available | no | optional outdoor marker |
| `shrine_or_loot_marker` | P1 | optional reward marker | prop | transparent PNG | 96x96 | yes | `prop_outdoor01_shrine_96.png` | `assets/sprites/props/outdoor_01/prop_outdoor01_shrine_96.png` | none | available | no | optional pocket / placeholder waypoint |
| `camp_palisade_wall` | P1 | camp defensive silhouette | prop | transparent PNG | 96x96 | yes | `prop_camp01_palisade_wall_96_a.png` | `assets/sprites/props/camp_01/prop_camp01_palisade_wall_96_a.png` | broken fence | available | no | user review; add collisions before placement |
| `camp_wood_fence_straight` | P1 | camp fence run | prop | transparent PNG | 96x64 | yes | `prop_camp01_wood_fence_straight_96_a.png` | `assets/sprites/props/camp_01/prop_camp01_wood_fence_straight_96_a.png` | broken fence | available | no | user-requested camp material |
| `camp_wood_fence_corner` | P1 | camp fence turn | prop | transparent PNG | 96x96 | yes | `prop_camp01_wood_fence_corner_96_a.png` | `assets/sprites/props/camp_01/prop_camp01_wood_fence_corner_96_a.png` | broken fence | available | no | user-requested camp material |
| `camp_wood_fence_broken` | P1 | damaged camp fence | prop | transparent PNG | 96x64 | yes | `prop_camp01_wood_fence_broken_96_a.png` | `assets/sprites/props/camp_01/prop_camp01_wood_fence_broken_96_a.png` | broken fence | available | no | user-requested camp material |
| `camp_wood_fence_gate_side` | P1 | camp entrance side post | prop | transparent PNG | 96x96 | yes | `prop_camp01_wood_fence_gate_side_96_a.png` | `assets/sprites/props/camp_01/prop_camp01_wood_fence_gate_side_96_a.png` | `prop_outdoor01_camp_gate_128.png` | available | no | user-requested camp material |
| `camp_tent` | P1 | camp identity prop | prop | transparent PNG | 128x128 | yes | `prop_camp01_tent_128_a.png` | `assets/sprites/props/camp_01/prop_camp01_tent_128_a.png` | none | available | no | user review; add collisions before placement |
| `campfire` | P1 | camp identity / interactable marker | prop | transparent PNG | 64x64 | yes | `prop_camp01_campfire_64_a.png` | `assets/sprites/props/camp_01/prop_camp01_campfire_64_a.png` | shrine fallback | available | no | later can animate |
| `crate_barrel_stack` | P1 | supply cluster | prop | transparent PNG | 96x96 | yes | `prop_camp01_crate_barrel_stack_96_a.png` | `assets/sprites/props/camp_01/prop_camp01_crate_barrel_stack_96_a.png` | `prop_outdoor01_broken_cart_96.png` | available | no | user review; add collisions before placement |
| `stash_chest` | P1 | stash placeholder | prop | transparent PNG | 64x64 | yes | `prop_camp01_stash_chest_64_a.png` | `assets/sprites/props/camp_01/prop_camp01_stash_chest_64_a.png` | ColorRect placeholder | available | no | connect to stash logic later |
| `waypoint_marker` | P1 | waypoint / return marker | prop | transparent PNG | 96x96 | yes | `prop_camp01_waypoint_marker_96_a.png` | `assets/sprites/props/camp_01/prop_camp01_waypoint_marker_96_a.png` | shrine fallback | available | no | connect to travel UI later |
| `npc_placeholder` | P1 | neutral quest giver stand-in | sprite | transparent PNG | 64x96 | yes | `npc_camp01_quest_giver_idle_64_a.png` | `assets/sprites/npc/camp_01/npc_camp01_quest_giver_idle_64_a.png` | ColorRect placeholder | available | no | replace with animated NPC later |
| `camp_trampled_ground_decal` | P1 | camp floor wear | decal | transparent PNG | 64x64 | yes | `decal_camp01_trampled_ground_64_a.png` | `assets/sprites/decals/outdoor_01/decal_camp01_trampled_ground_64_a.png` | none | available | no | scatter under camp props |

## TASK-027 P0 Audit

This table is the current source for TASK-027 reporting. `blocker_for_task_030` means the missing or placeholder quality will directly weaken the first terrain paint pass.

| ID | Status | current_path / current_fallback | blocker_for_task_030 | note |
| --- | --- | --- | --- | --- |
| `grass_dead_base` | placeholder | `assets/sprites/tiles/outdoor_01/tileset_outdoor01_ground_32.png` | no | usable as rough base, but needs better variation later |
| `dirt_base` | placeholder | `assets/sprites/tiles/outdoor_01/tileset_outdoor01_ground_32.png` | no | usable as rough base, not a real road vocabulary |
| `mud_trampled_base` | missing | none | yes | needed for camp wear and field pressure areas |
| `dirt_road_center` | missing | none | yes | highest priority before terrain paint |
| `dirt_road_edge` | missing | none | yes | required to avoid rectangular road blocks |
| `dirt_road_corner` | missing | none | yes | required for readable bends and forks |
| `road_noise_decal` | missing | none | yes | needed for small-scale road breakup |
| `grass_to_dirt_blend` | missing | none | yes | required to make walkable field read naturally |
| `dirt_to_corruption_blend` | missing | none | yes | required before corruption patch paint |
| `corruption_edge_blend` | missing | none | yes | required to avoid rectangular corruption zones |
| `corrupted_ground_patch` | placeholder | `assets/sprites/tiles/outdoor_01/tile_outdoor01_corrupted_ground_32.png` | no | usable as temporary patch, not enough alone |
| `root_stain_decal` | missing | none | yes | important for corrupted approach and dungeon entrance |
| `dark_crack_decal` | missing | none | yes | important for corruption detail pass |
| `thorn_weed_decal` | missing | none | no | useful detail, less blocking than road/transition |
| `rock_small` | available | `assets/sprites/props/outdoor_01/prop_outdoor01_rock_small_32_a.png`, `assets/sprites/props/outdoor_01/prop_outdoor01_rock_small_32_b.png` | no | already used by boundary pass |
| `rock_medium` | missing | scaled small rock fallback | no | nice-to-have; small rocks can carry P0 |
| `dead_tree` | available | `assets/sprites/props/outdoor_01/prop_outdoor01_dead_tree_64_a.png`, `assets/sprites/props/outdoor_01/prop_outdoor01_dead_tree_64_b.png` | no | usable for soft boundary |
| `broken_fence` | available | `assets/sprites/props/outdoor_01/prop_outdoor01_broken_fence_64_a.png`, `assets/sprites/props/outdoor_01/prop_outdoor01_broken_fence_64_b.png` | no | usable for camp and outdoor boundary |
| `corrupted_root_wall` | available | `assets/sprites/props/outdoor_01/prop_outdoor01_corrupted_roots_64_a.png`, `assets/sprites/props/outdoor_01/prop_outdoor01_corrupted_roots_64_b.png` | no | usable for dungeon/exit pressure |
| `camp_gate` | available | `assets/sprites/props/outdoor_01/prop_outdoor01_camp_gate_128.png` | no | used by Camp and outdoor start |
| `dungeon_entrance` | available | `assets/sprites/props/outdoor_01/prop_outdoor01_corrupted_hollow_128.png` | no | usable as primary hook |
| `next_area_marker` | available | `assets/sprites/props/outdoor_01/prop_outdoor01_signpost_64.png` | no | temporary soft-gate/readability marker |
| `shrine_or_loot_marker` | available | `assets/sprites/props/outdoor_01/prop_outdoor01_shrine_96.png` | no | usable for optional pocket |
| `camp_palisade_wall` | missing | broken fence fallback | no | needed for Rogue Encampment-like silhouette, not blocking contract |
| `camp_tent` | missing | none | no | important for camp identity |
| `campfire` | missing | none | no | important for camp identity |
| `crate_barrel_stack` | missing | `prop_outdoor01_broken_cart_96.png` fallback | no | broken cart can temporarily mark supplies |
| `stash_chest` | missing | ColorRect placeholder in `camp_scene.tscn` | no | gameplay contract has placeholder |
| `waypoint_marker` | missing | `prop_outdoor01_shrine_96.png` fallback in `camp_scene.tscn` | no | contract placeholder exists |
| `npc_placeholder` | missing | ColorRect placeholder in `camp_scene.tscn` | no | avoid reusing enemy sprite until accepted |
| `camp_trampled_ground_decal` | missing | ColorRect patch fallback in `camp_scene.tscn` | yes | needed for visual camp floor quality |

## P0 Required

### Ground Base

| ID | Needed | Form | Size | Transparency | Status | Current fallback |
| --- | --- | --- | --- | --- | --- | --- |
| `grass_dead_base` | dead grass / dry grass base | tileset or tile group | 32x32 | no | placeholder | `tileset_outdoor01_ground_32.png` |
| `dirt_base` | dry dirt base | tileset or tile group | 32x32 | no | placeholder | `tileset_outdoor01_ground_32.png` |
| `mud_trampled_base` | darker trampled ground | tileset or tile group | 32x32 | no | missing | none |

Notes:

- These are background ground tiles.
- They should tile without visible seams.
- Do not make them high contrast; monsters and loot need to read on top.

### Road

| ID | Needed | Form | Size | Transparency | Status | Current fallback |
| --- | --- | --- | --- | --- | --- | --- |
| `dirt_road_center` | narrow dirt road center | tileset sheet preferred | 32x32 | no | missing | none |
| `dirt_road_edge` | grass-to-road edge blend | tileset sheet preferred | 32x32 | mixed, depends on sheet | missing | none |
| `dirt_road_corner` | road turn / corner blend | tileset sheet preferred | 32x32 | mixed, depends on sheet | missing | none |
| `road_noise_decal` | pebbles / wheel marks / worn patches | single PNG | 32x32 or 64x64 | yes | missing | none |

Notes:

- The visual road should be narrower than the logical corridor.
- It should point forward like a readable outdoor path, not fill the whole corridor rectangle.
- For implementation, a tileset sheet is better than scattered straight/corner PNGs.

### Transitions

| ID | Needed | Form | Size | Transparency | Status | Current fallback |
| --- | --- | --- | --- | --- | --- | --- |
| `grass_to_dirt_blend` | soft edge from grass to dirt | tileset sheet or transparent overlay | 32x32 | preferably yes if overlay | missing | none |
| `dirt_to_corruption_blend` | dirt to corrupted ground edge | tileset sheet or transparent overlay | 32x32 | preferably yes if overlay | missing | none |
| `corruption_edge_blend` | irregular corrupted edge | transparent overlay | 32x32 or 64x64 | yes | missing | none |

Notes:

- These assets are important because current map reads as blocks.
- P0 only needs a few usable transition pieces, not a complete professional autotile set.

### Corruption

| ID | Needed | Form | Size | Transparency | Status | Current fallback |
| --- | --- | --- | --- | --- | --- | --- |
| `corrupted_ground_patch` | dark corrupted ground patch | single PNG or tile | 32x32 / 64x64 | yes if decal | placeholder | `tile_outdoor01_corrupted_ground_32.png` |
| `root_stain_decal` | root stain / black crack | single PNG | 64x64 | yes | missing | none |
| `dark_crack_decal` | dark crack / scar in ground | single PNG | 64x64 | yes | missing | none |
| `thorn_weed_decal` | small corrupted weed / thorn | single PNG | 32x32 | yes | missing | none |

Notes:

- Corruption should appear as local infection, not a whole rectangle.
- Use low saturation dark red / purple / black-green, avoid bright purple.

### Boundary Props

| ID | Needed | Form | Size | Transparency | Status | Current fallback |
| --- | --- | --- | --- | --- | --- | --- |
| `rock_small` | small boundary rock | single PNG | 32x32 or 64x64 | yes | available | `prop_outdoor01_rock_small_32_a/b.png` |
| `rock_medium` | medium boundary rock | single PNG | 64x64 | yes | missing | small rock can scale temporarily |
| `dead_tree` | dead tree / trunk boundary | single PNG | 64x64 or 96x96 | yes | available | `prop_outdoor01_dead_tree_64_a/b.png` |
| `broken_fence` | broken fence segment | single PNG | 64x64 or 96x64 | yes | available | `prop_outdoor01_broken_fence_64_a/b.png` |
| `corrupted_root_wall` | root wall / blocked root mass | single PNG | 64x64 or 96x64 | yes | available | `prop_outdoor01_corrupted_roots_64_a/b.png` |

Notes:

- These props need per-object collision footprint later.
- Do not generate huge full-image blockers; bottom footprint should be visually clear.
- Prefer 1-2 variations per type first.

### Landmarks

| ID | Needed | Form | Size | Transparency | Status | Current fallback |
| --- | --- | --- | --- | --- | --- | --- |
| `camp_gate` | camp exit marker | single PNG | 128x128 or 160x128 | yes | available | `prop_outdoor01_camp_gate_128.png` |
| `dungeon_entrance` | corrupted hollow / cellar entrance | single PNG | 128x128 or 160x160 | yes | available | `prop_outdoor01_corrupted_hollow_128.png` |
| `next_area_marker` | blocked next-area sign / scout marker | single PNG | 64x64 or 96x96 | yes | available | `prop_outdoor01_signpost_64.png` |
| `shrine_or_loot_marker` | optional reward hook | single PNG | 96x96 | yes | available | `prop_outdoor01_shrine_96.png` |

Notes:

- Dungeon entrance must read as a primary hook, similar in function to a Den-like first quest entrance.
- Next-area marker should be visible but less attractive than dungeon entrance in the first outdoor phase.

### Camp Support Assets

| ID | Needed | Form | Size | Transparency | Status | Current fallback |
| --- | --- | --- | --- | --- | --- | --- |
| `camp_palisade_wall` | camp fence / wooden wall | single PNG or tileable segment | 64x64 or 96x64 | yes | missing | broken fence can temporarily mark edge |
| `camp_tent` | tent / cloth shelter | single PNG | 96x96 or 128x128 | yes | missing | none |
| `campfire` | campfire / fire pit | single PNG, optional animation later | 64x64 | yes | missing | shrine can mark interactable only |
| `crate_barrel_stack` | supplies / crates / barrels | single PNG | 64x64 or 96x96 | yes | missing | broken cart can temporarily mark supplies |
| `stash_chest` | stash placeholder | single PNG | 64x64 | yes | missing | shrine or chest placeholder if created |
| `waypoint_marker` | waypoint / return marker | single PNG | 64x64 or 96x96 | yes | missing | signpost can temporarily mark |
| `npc_placeholder` | neutral NPC stand-in | single PNG or sprite | 64x64 | yes | missing | player/enemy sprite should not be reused unless explicitly accepted |
| `camp_trampled_ground_decal` | camp floor wear / ash / mud | single PNG | 64x64 | yes | missing | none |

## P1 Later

Do not block P0 on these:

```text
additional grass variants
flower / mushroom / bone decals
camp tents / barrels / crates
NPC-specific props
more fence directions
more root wall shapes
water / puddle tiles
animated fire / torch
```

## Current Collaboration Flow

User:

```text
1. Review this list.
2. During TASK-027, generate or choose the highest priority P0 assets.
3. Prioritize road / transition / decal and Camp support props.
4. Put raw outputs in the raw asset area.
5. Tell an agent which generated files are accepted.
```

Asset agent:

```text
1. Use this list as the source of truth.
2. Generate only P0 unless asked otherwise.
3. Keep variations controlled.
4. Return filenames mapped to IDs.
```

Task agent:

```text
1. Start asset inventory in TASK-027, not TASK-029.
2. Use available assets immediately for Camp rough layout.
3. Mark each P0 asset as available / placeholder / missing / accepted.
4. Do not implement terrain paint in TASK-029.
5. Later TASK-031 will integrate terrain paint into generated outdoor.
```


