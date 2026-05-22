extends RefCounted
class_name AssetFootprintDraftTool

const ALPHA_THRESHOLD := 0.05
const PREVIEW_SCALE := 3
const PREVIEW_MARGIN := 14
const PREVIEW_GAP := 14
const PREVIEW_BACKGROUND := Color(0.055, 0.06, 0.055, 1.0)
const PREVIEW_PANEL := Color(0.12, 0.12, 0.105, 1.0)
const VISUAL_COLOR := Color(0.2, 1.0, 0.35, 0.9)
const COLLISION_COLOR := Color(0.15, 0.78, 1.0, 0.9)
const COLLISION_FILL := Color(0.15, 0.78, 1.0, 0.22)
const INTERACTION_COLOR := Color(1.0, 0.82, 0.18, 0.9)
const INTERACTION_FILL := Color(1.0, 0.82, 0.18, 0.18)
const FOOT_COLOR := Color(1.0, 0.24, 0.78, 1.0)


func analyze_image(image_path: String, asset_type: String, options: Dictionary = {}) -> Dictionary:
	var image := Image.new()
	var load_error := image.load(ProjectSettings.globalize_path(image_path))
	var warnings := []
	if load_error != OK:
		return _error_draft(image_path, asset_type, "image_load_error=%s" % load_error)
	var image_size := Vector2i(image.get_width(), image.get_height())
	var visible := _visible_bounds(image)
	if visible.size.x <= 0 or visible.size.y <= 0:
		visible = Rect2i(Vector2i.ZERO, image_size)
		warnings.append("no alpha-visible pixels; using full image bounds")
	var normalized_type := str(asset_type)
	var asset_id := str(options.get("asset_id", image_path.get_file().get_basename()))
	var orientation := str(options.get("orientation", _default_orientation(normalized_type, visible)))
	var behavior := str(options.get("intended_behavior", ""))
	var foot_point := _foot_point_for_type(normalized_type, visible)
	var sprite_offset := Vector2(float(image_size.x) * 0.5 - foot_point.x, float(image_size.y) * 0.5 - foot_point.y)
	var collision := _collision_for_type(normalized_type, visible, foot_point, orientation)
	var interaction := _interaction_for_type(normalized_type, visible, foot_point, collision)
	var confidence := _confidence_for_type(normalized_type, visible, image_size)
	if confidence < 0.82:
		warnings.append("low confidence draft; requires visual review")
	if behavior.is_empty():
		warnings.append("no intended_behavior provided; using asset_type defaults")
	return {
		"asset_id": asset_id,
		"image_path": image_path,
		"asset_type": normalized_type,
		"image_size": _image_size_payload(image_size),
		"sprite": {
			"visual_bounds": _rect_payload(Rect2(visible.position, visible.size)),
			"foot_point": _vector_payload(foot_point),
			"sprite_offset": _vector_payload(sprite_offset),
			"sort_y_offset": 0,
		},
		"collision": collision,
		"interaction": interaction,
		"analysis": {
			"confidence": snappedf(confidence, 0.01),
			"needs_review": true,
			"reason": _reason_for_type(normalized_type),
			"warnings": warnings,
		},
	}


func analyze_batch(items: Array) -> Array:
	var drafts := []
	for item in items:
		var data: Dictionary = item
		drafts.append(analyze_image(str(data.get("image_path", "")), str(data.get("asset_type", "")), data))
	return drafts


func write_json(path: String, payload) -> Error:
	var absolute := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var file := FileAccess.open(absolute, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(payload, "\t"))
	return OK


func write_preview_sheet(path: String, drafts: Array, columns: int = 4) -> Error:
	var valid_drafts := []
	var max_w := 1
	var max_h := 1
	for draft in drafts:
		var data: Dictionary = draft
		var image := Image.new()
		if image.load(ProjectSettings.globalize_path(str(data.get("image_path", "")))) != OK:
			continue
		valid_drafts.append(data)
		max_w = maxi(max_w, image.get_width())
		max_h = maxi(max_h, image.get_height())
	if valid_drafts.is_empty():
		return ERR_DOES_NOT_EXIST
	columns = maxi(1, columns)
	var rows := int(ceil(float(valid_drafts.size()) / float(columns)))
	var panel_size := Vector2i(max_w * PREVIEW_SCALE + PREVIEW_MARGIN * 2, max_h * PREVIEW_SCALE + PREVIEW_MARGIN * 2)
	var sheet_size := Vector2i(
		columns * panel_size.x + (columns + 1) * PREVIEW_GAP,
		rows * panel_size.y + (rows + 1) * PREVIEW_GAP
	)
	var sheet := Image.create(sheet_size.x, sheet_size.y, false, Image.FORMAT_RGBA8)
	sheet.fill(PREVIEW_BACKGROUND)
	for i in range(valid_drafts.size()):
		var draft: Dictionary = valid_drafts[i]
		var image := Image.new()
		image.load(ProjectSettings.globalize_path(str(draft.get("image_path", ""))))
		var col := i % columns
		var row := i / columns
		var panel_origin := Vector2i(
			PREVIEW_GAP + col * (panel_size.x + PREVIEW_GAP),
			PREVIEW_GAP + row * (panel_size.y + PREVIEW_GAP)
		)
		_draw_panel(sheet, panel_origin, panel_size)
		var sprite_origin := panel_origin + Vector2i(PREVIEW_MARGIN, PREVIEW_MARGIN)
		_blit_scaled(sheet, image, sprite_origin, PREVIEW_SCALE)
		_draw_draft_overlay(sheet, draft, sprite_origin)
	var absolute := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	return sheet.save_png(absolute)


func _draw_panel(sheet: Image, origin: Vector2i, size: Vector2i) -> void:
	_fill_rect(sheet, Rect2i(origin, size), PREVIEW_PANEL)
	_draw_rect_outline(sheet, Rect2i(origin, size), Color(0.22, 0.22, 0.19, 1.0), 1)


func _draw_draft_overlay(sheet: Image, draft: Dictionary, origin: Vector2i) -> void:
	var sprite: Dictionary = draft.get("sprite", {})
	var visual_rect := _rect_from_payload(sprite.get("visual_bounds", {}))
	var foot := _vector_from_payload(sprite.get("foot_point", {}))
	_draw_rect_outline(sheet, _scale_rect(visual_rect, origin), VISUAL_COLOR, 2)
	_draw_cross(sheet, origin + Vector2i(roundi(foot.x * PREVIEW_SCALE), roundi(foot.y * PREVIEW_SCALE)), FOOT_COLOR, 8)
	var collision: Dictionary = draft.get("collision", {})
	if bool(collision.get("enabled", false)):
		var parts: Array = collision.get("parts", [])
		if not parts.is_empty():
			for part in parts:
				_draw_collision_shape(sheet, part, foot, origin, COLLISION_COLOR, COLLISION_FILL)
		else:
			_draw_collision_shape(sheet, collision, foot, origin, COLLISION_COLOR, COLLISION_FILL)
	var interaction: Dictionary = draft.get("interaction", {})
	if bool(interaction.get("enabled", false)):
		_draw_collision_shape(sheet, interaction, foot, origin, INTERACTION_COLOR, INTERACTION_FILL)


func _draw_collision_shape(sheet: Image, shape: Dictionary, foot: Vector2, origin: Vector2i, outline: Color, fill: Color) -> void:
	var offset := _vector_from_payload(shape.get("offset", {}))
	var center := foot + offset
	match str(shape.get("shape", "")):
		"circle":
			var radius := float(shape.get("radius", maxf(float(shape.get("size", {}).get("x", 0.0)), float(shape.get("size", {}).get("y", 0.0))) * 0.5))
			_draw_circle(sheet, origin + Vector2i(roundi(center.x * PREVIEW_SCALE), roundi(center.y * PREVIEW_SCALE)), roundi(radius * PREVIEW_SCALE), outline, fill)
		"capsule":
			var radius := float(shape.get("radius", 8.0))
			var height := float(shape.get("height", radius * 2.0))
			var rect: Rect2
			if str(shape.get("orientation", "vertical")) == "horizontal":
				rect = Rect2(center - Vector2(height * 0.5, radius), Vector2(height, radius * 2.0))
			else:
				rect = Rect2(center - Vector2(radius, height * 0.5), Vector2(radius * 2.0, height))
			_draw_rect(sheet, _scale_rect(rect, origin), outline, fill)
		"rect":
			var size := _size_from_payload(shape.get("size", {}))
			var rect := Rect2(center - size * 0.5, size)
			_draw_rect(sheet, _scale_rect(rect, origin), outline, fill)
		_:
			pass


func _blit_scaled(target: Image, source: Image, origin: Vector2i, scale: int) -> void:
	for y in range(source.get_height()):
		for x in range(source.get_width()):
			var color := source.get_pixel(x, y)
			if color.a <= 0.0:
				continue
			for yy in range(scale):
				for xx in range(scale):
					_blend_pixel(target, origin + Vector2i(x * scale + xx, y * scale + yy), color)


func _visible_bounds(image: Image) -> Rect2i:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > ALPHA_THRESHOLD:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func _foot_point_for_type(asset_type: String, visible: Rect2i) -> Vector2:
	var bottom := float(visible.position.y + visible.size.y)
	match asset_type:
		"character", "enemy":
			return Vector2(visible.position.x + visible.size.x * 0.5, bottom - visible.size.y * 0.05)
		"prop_tall", "entrance":
			return Vector2(visible.position.x + visible.size.x * 0.5, bottom - visible.size.y * 0.08)
		"barrier":
			return Vector2(visible.position.x + visible.size.x * 0.5, bottom - visible.size.y * 0.18)
		"decal", "ground_tile":
			return Vector2(visible.position.x + visible.size.x * 0.5, bottom)
		_:
			return Vector2(visible.position.x + visible.size.x * 0.5, bottom - visible.size.y * 0.10)


func _collision_for_type(asset_type: String, visible: Rect2i, foot: Vector2, orientation: String) -> Dictionary:
	var width := float(visible.size.x)
	var height := float(visible.size.y)
	match asset_type:
		"decal", "ground_tile":
			return _disabled_collision()
		"character", "enemy":
			var capsule_height := maxf(18.0, height * 0.26)
			var radius := maxf(7.0, width * 0.18)
			return _capsule_payload("vertical", radius, capsule_height, Vector2(0, -capsule_height * 0.5))
		"prop_tall":
			var size := Vector2(maxf(24.0, width * 0.36), maxf(18.0, height * 0.22))
			return _rect_collision(size, Vector2(0, -size.y * 0.5))
		"barrier":
			if orientation == "vertical":
				var size_v := Vector2(maxf(18.0, width * 0.34), maxf(48.0, height * 0.82))
				return _capsule_payload("vertical", maxf(8.0, size_v.x * 0.5), size_v.y, Vector2(0, -size_v.y * 0.5))
			var size_h := Vector2(maxf(48.0, width * 0.88), maxf(16.0, height * 0.28))
			return _capsule_payload("horizontal", maxf(8.0, size_h.y * 0.5), size_h.x, Vector2(0, -size_h.y * 0.5))
		"entrance":
			return _entrance_collision(visible, foot)
		"interactable":
			var size_i := Vector2(maxf(24.0, width * 0.70), maxf(18.0, height * 0.30))
			return _rect_collision(size_i, Vector2(0, -size_i.y * 0.5))
		_:
			var size := Vector2(maxf(22.0, width * 0.72), maxf(16.0, height * 0.32))
			return _rect_collision(size, Vector2(0, -size.y * 0.5))


func _interaction_for_type(asset_type: String, visible: Rect2i, foot: Vector2, collision: Dictionary) -> Dictionary:
	match asset_type:
		"interactable":
			var size := Vector2(maxf(80.0, visible.size.x * 1.30), maxf(70.0, visible.size.y * 0.95))
			return {
				"enabled": true,
				"shape": "circle",
				"size": _size_payload(size),
				"radius": snappedf(maxf(size.x, size.y) * 0.5, 0.01),
				"offset": _vector_payload(Vector2(0, -size.y * 0.32)),
			}
		"entrance":
			var size := Vector2(maxf(96.0, visible.size.x * 0.56), maxf(70.0, visible.size.y * 0.46))
			return {
				"enabled": true,
				"shape": "rect",
				"size": _size_payload(size),
				"radius": 0,
				"offset": _vector_payload(Vector2(0, -size.y * 0.5)),
			}
		_:
			return {"enabled": false, "shape": "none", "size": {"x": 0, "y": 0}, "offset": {"x": 0, "y": 0}}


func _entrance_collision(visible: Rect2i, foot: Vector2) -> Dictionary:
	var total_w := float(visible.size.x)
	var total_h := float(visible.size.y)
	var part_w := maxf(18.0, total_w * 0.24)
	var part_h := maxf(22.0, total_h * 0.36)
	var opening_w := maxf(28.0, total_w * 0.36)
	var y_offset := -part_h * 0.5
	return {
		"enabled": true,
		"shape": "parts",
		"orientation": "horizontal",
		"size": _size_payload(Vector2(total_w, part_h)),
		"radius": 0,
		"offset": _vector_payload(Vector2.ZERO),
		"opening": {
			"center": _vector_payload(Vector2.ZERO),
			"size": _size_payload(Vector2(opening_w, part_h)),
		},
		"parts": [
			_rect_collision(Vector2(part_w, part_h), Vector2(-opening_w * 0.5 - part_w * 0.5, y_offset)).merged({"id": "left_blocker"}, true),
			_rect_collision(Vector2(part_w, part_h), Vector2(opening_w * 0.5 + part_w * 0.5, y_offset)).merged({"id": "right_blocker"}, true),
		],
	}


func _rect_collision(size: Vector2, offset: Vector2) -> Dictionary:
	return {
		"enabled": true,
		"shape": "rect",
		"orientation": "horizontal",
		"size": _size_payload(size),
		"radius": 0,
		"offset": _vector_payload(offset),
		"parts": [],
	}


func _capsule_payload(orientation: String, radius: float, height: float, offset: Vector2) -> Dictionary:
	return {
		"enabled": true,
		"shape": "capsule",
		"orientation": orientation,
		"size": _size_payload(Vector2(height if orientation == "horizontal" else radius * 2.0, radius * 2.0 if orientation == "horizontal" else height)),
		"radius": snappedf(radius, 0.01),
		"height": snappedf(height, 0.01),
		"offset": _vector_payload(offset),
		"parts": [],
	}


func _disabled_collision() -> Dictionary:
	return {
		"enabled": false,
		"shape": "none",
		"orientation": "none",
		"size": {"x": 0, "y": 0},
		"radius": 0,
		"offset": {"x": 0, "y": 0},
		"parts": [],
	}


func _confidence_for_type(asset_type: String, visible: Rect2i, image_size: Vector2i) -> float:
	if ["decal", "ground_tile"].has(asset_type):
		return 0.92
	var coverage := float(visible.size.x * visible.size.y) / maxf(1.0, float(image_size.x * image_size.y))
	var base := 0.74 + clampf(coverage, 0.08, 0.72) * 0.22
	if ["entrance", "barrier"].has(asset_type):
		base -= 0.08
	return clampf(base, 0.45, 0.92)


func _reason_for_type(asset_type: String) -> String:
	match asset_type:
		"character", "enemy":
			return "uses a small foot capsule near the lower visible body"
		"prop_tall":
			return "uses the lower support band, avoiding tall visual canopy/top"
		"prop_low":
			return "uses the lower visible band as a broad footprint"
		"barrier":
			return "uses orientation-aware continuous blocker footprint"
		"entrance":
			return "uses two side blockers and preserves a central opening"
		"interactable":
			return "separates physical footprint from larger interaction area"
		"decal", "ground_tile":
			return "decorative or ground asset defaults to no collision"
	return "uses generic lower-band footprint"


func _default_orientation(asset_type: String, visible: Rect2i) -> String:
	if asset_type == "barrier":
		return "vertical" if visible.size.y > visible.size.x else "horizontal"
	return "horizontal"


func _error_draft(image_path: String, asset_type: String, reason: String) -> Dictionary:
	return {
		"asset_id": image_path.get_file().get_basename(),
		"image_path": image_path,
		"asset_type": asset_type,
		"image_size": {"w": 0, "h": 0},
		"sprite": {"visual_bounds": {"x": 0, "y": 0, "w": 0, "h": 0}, "foot_point": {"x": 0, "y": 0}, "sprite_offset": {"x": 0, "y": 0}, "sort_y_offset": 0},
		"collision": _disabled_collision(),
		"interaction": {"enabled": false, "shape": "none", "size": {"x": 0, "y": 0}, "offset": {"x": 0, "y": 0}},
		"analysis": {"confidence": 0.0, "needs_review": true, "reason": reason, "warnings": [reason]},
	}


func _rect_payload(value: Rect2) -> Dictionary:
	return {
		"x": snappedf(value.position.x, 0.01),
		"y": snappedf(value.position.y, 0.01),
		"w": snappedf(value.size.x, 0.01),
		"h": snappedf(value.size.y, 0.01),
	}


func _vector_payload(value: Vector2) -> Dictionary:
	return {"x": snappedf(value.x, 0.01), "y": snappedf(value.y, 0.01)}


func _size_payload(value: Vector2) -> Dictionary:
	return {"x": snappedf(value.x, 0.01), "y": snappedf(value.y, 0.01)}


func _image_size_payload(value: Vector2i) -> Dictionary:
	return {"w": value.x, "h": value.y}


func _rect_from_payload(value) -> Rect2:
	if not (value is Dictionary):
		return Rect2()
	var data: Dictionary = value
	return Rect2(float(data.get("x", 0.0)), float(data.get("y", 0.0)), float(data.get("w", 0.0)), float(data.get("h", 0.0)))


func _vector_from_payload(value) -> Vector2:
	if not (value is Dictionary):
		return Vector2.ZERO
	var data: Dictionary = value
	return Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))


func _size_from_payload(value) -> Vector2:
	if not (value is Dictionary):
		return Vector2.ZERO
	var data: Dictionary = value
	return Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))


func _scale_rect(rect: Rect2, origin: Vector2i) -> Rect2i:
	return Rect2i(
		origin + Vector2i(roundi(rect.position.x * PREVIEW_SCALE), roundi(rect.position.y * PREVIEW_SCALE)),
		Vector2i(roundi(rect.size.x * PREVIEW_SCALE), roundi(rect.size.y * PREVIEW_SCALE))
	)


func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	var clipped := rect.intersection(Rect2i(Vector2i.ZERO, Vector2i(image.get_width(), image.get_height())))
	for y in range(clipped.position.y, clipped.end.y):
		for x in range(clipped.position.x, clipped.end.x):
			_blend_pixel(image, Vector2i(x, y), color)


func _draw_rect(image: Image, rect: Rect2i, outline: Color, fill: Color) -> void:
	_fill_rect(image, rect, fill)
	_draw_rect_outline(image, rect, outline, 2)


func _draw_rect_outline(image: Image, rect: Rect2i, color: Color, thickness: int) -> void:
	_fill_rect(image, Rect2i(rect.position, Vector2i(rect.size.x, thickness)), color)
	_fill_rect(image, Rect2i(Vector2i(rect.position.x, rect.end.y - thickness), Vector2i(rect.size.x, thickness)), color)
	_fill_rect(image, Rect2i(rect.position, Vector2i(thickness, rect.size.y)), color)
	_fill_rect(image, Rect2i(Vector2i(rect.end.x - thickness, rect.position.y), Vector2i(thickness, rect.size.y)), color)


func _draw_circle(image: Image, center: Vector2i, radius: int, outline: Color, fill: Color) -> void:
	var r2 := radius * radius
	var inner := maxi(0, radius - 2)
	var inner2 := inner * inner
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var d2 := (x - center.x) * (x - center.x) + (y - center.y) * (y - center.y)
			if d2 <= r2:
				_blend_pixel(image, Vector2i(x, y), outline if d2 >= inner2 else fill)


func _draw_cross(image: Image, center: Vector2i, color: Color, radius: int) -> void:
	_fill_rect(image, Rect2i(Vector2i(center.x - radius, center.y - 1), Vector2i(radius * 2 + 1, 3)), color)
	_fill_rect(image, Rect2i(Vector2i(center.x - 1, center.y - radius), Vector2i(3, radius * 2 + 1)), color)


func _blend_pixel(image: Image, position: Vector2i, color: Color) -> void:
	if position.x < 0 or position.y < 0 or position.x >= image.get_width() or position.y >= image.get_height():
		return
	var base := image.get_pixelv(position)
	var alpha := color.a
	var out := Color(
		color.r * alpha + base.r * (1.0 - alpha),
		color.g * alpha + base.g * (1.0 - alpha),
		color.b * alpha + base.b * (1.0 - alpha),
		maxf(base.a, alpha)
	)
	image.set_pixelv(position, out)
