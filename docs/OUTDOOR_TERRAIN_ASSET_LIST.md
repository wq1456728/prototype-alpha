# Outdoor Terrain Asset List

这个文档给用户和素材 agent 使用，目标是先补齐第一张 outdoor map 的 P0 地表词汇表。它不是最终美术清单，也不是要求一次性生成全部素材。

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

Naming pattern:

```text
tile_outdoor01_<name>_32.png
tileset_outdoor01_<name>_32.png
decal_outdoor01_<name>_<size>_<variant>.png
prop_outdoor01_<name>_<size>_<variant>.png
```

## P0 Required

### Ground Base

| ID | Needed | Form | Size | Transparency | Current fallback |
| --- | --- | --- | --- | --- | --- |
| `grass_dead_base` | dead grass / dry grass base | tileset or tile group | 32x32 | no | existing outdoor ground may be temporary |
| `dirt_base` | dry dirt base | tileset or tile group | 32x32 | no | existing ground tileset may be temporary |
| `mud_trampled_base` | darker trampled ground | tileset or tile group | 32x32 | no | missing |

Notes:

- These are background ground tiles.
- They should tile without visible seams.
- Do not make them high contrast; monsters and loot need to read on top.

### Road

| ID | Needed | Form | Size | Transparency | Current fallback |
| --- | --- | --- | --- | --- | --- |
| `dirt_road_center` | narrow dirt road center | tileset sheet preferred | 32x32 | no | missing |
| `dirt_road_edge` | grass-to-road edge blend | tileset sheet preferred | 32x32 | mixed, depends on sheet | missing |
| `dirt_road_corner` | road turn / corner blend | tileset sheet preferred | 32x32 | mixed, depends on sheet | missing |
| `road_noise_decal` | pebbles / wheel marks / worn patches | single PNG | 32x32 or 64x64 | yes | missing |

Notes:

- The visual road should be narrower than the logical corridor.
- It should point forward like a readable outdoor path, not fill the whole corridor rectangle.
- For implementation, a tileset sheet is better than scattered straight/corner PNGs.

### Transitions

| ID | Needed | Form | Size | Transparency | Current fallback |
| --- | --- | --- | --- | --- | --- |
| `grass_to_dirt_blend` | soft edge from grass to dirt | tileset sheet or transparent overlay | 32x32 | preferably yes if overlay | missing |
| `dirt_to_corruption_blend` | dirt to corrupted ground edge | tileset sheet or transparent overlay | 32x32 | preferably yes if overlay | missing |
| `corruption_edge_blend` | irregular corrupted edge | transparent overlay | 32x32 or 64x64 | yes | missing |

Notes:

- These assets are important because current map reads as blocks.
- P0 only needs a few usable transition pieces, not a complete professional autotile set.

### Corruption

| ID | Needed | Form | Size | Transparency | Current fallback |
| --- | --- | --- | --- | --- | --- |
| `corrupted_ground_patch` | dark corrupted ground patch | single PNG or tile | 32x32 / 64x64 | yes if decal | existing corrupted tile may be temporary |
| `root_stain_decal` | root stain / black crack | single PNG | 64x64 | yes | missing |
| `thorn_weed_decal` | small corrupted weed / thorn | single PNG | 32x32 | yes | missing |

Notes:

- Corruption should appear as local infection, not a whole rectangle.
- Use low saturation dark red / purple / black-green, avoid bright purple.

### Boundary Props

| ID | Needed | Form | Size | Transparency | Current fallback |
| --- | --- | --- | --- | --- | --- |
| `rock_small` | small boundary rock | single PNG | 32x32 or 64x64 | yes | existing rock usable |
| `rock_medium` | medium boundary rock | single PNG | 64x64 | yes | existing rock may be reused |
| `dead_tree` | dead tree / trunk boundary | single PNG | 64x64 or 96x96 | yes | existing dead tree usable |
| `broken_fence` | broken fence segment | single PNG | 64x64 or 96x64 | yes | existing fence usable |
| `corrupted_root_wall` | root wall / blocked root mass | single PNG | 64x64 or 96x64 | yes | existing root usable |

Notes:

- These props need per-object collision footprint later.
- Do not generate huge full-image blockers; bottom footprint should be visually clear.
- Prefer 1-2 variations per type first.

### Landmarks

| ID | Needed | Form | Size | Transparency | Current fallback |
| --- | --- | --- | --- | --- | --- |
| `camp_gate` | camp exit marker | single PNG | 128x128 or 160x128 | yes | existing camp gate usable |
| `dungeon_entrance` | corrupted hollow / cellar entrance | single PNG | 128x128 or 160x160 | yes | existing hollow usable |
| `next_area_marker` | blocked next-area sign / scout marker | single PNG | 64x64 or 96x96 | yes | existing signpost usable |
| `shrine_or_loot_marker` | optional reward hook | single PNG | 96x96 | yes | existing shrine usable |

Notes:

- Dungeon entrance must read as a primary hook, similar in function to a Den-like first quest entrance.
- Next-area marker should be visible but less attractive than dungeon entrance in the first outdoor phase.

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
2. Generate or choose P0 assets.
3. Put raw outputs in the raw asset area.
4. Tell an agent which generated files are accepted.
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
1. Do not implement terrain paint in TASK-028.
2. Only document / audit / organize the asset vocabulary.
3. Later TASK-030 will integrate terrain paint into generated outdoor.
```

