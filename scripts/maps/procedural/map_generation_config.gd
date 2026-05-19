extends RefCounted
class_name MapGenerationConfig

const DEFAULT_MAP_ID := "procedural_outdoor_core"
const DEFAULT_MAP_NAME := "Procedural Outdoor Core"

var map_id := DEFAULT_MAP_ID
var map_name := DEFAULT_MAP_NAME
var map_size := Vector2(3200.0, 3200.0)
var map_offset := Vector2.ZERO
var map_margin := 260.0
var corridor_width := 220.0
var main_path_min_zones := 4
var main_path_max_zones := 6
var optional_pocket_chance := 0.65
var branch_distance_range := Vector2(760.0, 1040.0)
var branch_y_offset_range := Vector2(-180.0, 260.0)
var route_x_jitter := 420.0
var zone_padding := 64.0

var zone_base_sizes := {
	"start": Vector2(700.0, 380.0),
	"first_contact": Vector2(620.0, 420.0),
	"road": Vector2(560.0, 380.0),
	"fork": Vector2(660.0, 450.0),
	"elite_pressure": Vector2(640.0, 430.0),
	"required_exit": Vector2(700.0, 430.0),
	"required_branch": Vector2(620.0, 430.0),
	"optional_pocket": Vector2(560.0, 360.0),
}

var zone_labels := {
	"start": "Camp / player spawn",
	"first_contact": "First Contact / weak monster pack",
	"road": "Road field / roaming pack",
	"fork": "Fork / route decision",
	"elite_pressure": "Elite pressure / mini fight",
	"required_exit": "Next area hook / demo exit",
	"required_branch": "Dungeon hook branch",
	"optional_pocket": "Optional loot pocket / shrine",
}

var template_variations := {
	"start": ["camp_a", "camp_b"],
	"first_contact": ["first_contact_a", "first_contact_b"],
	"road": ["road_a", "road_b"],
	"fork": ["fork_a", "fork_b"],
	"elite_pressure": ["elite_pressure_a", "elite_pressure_b"],
	"required_exit": ["exit_a", "exit_b"],
	"required_branch": ["branch_entrance_a", "branch_entrance_b"],
	"optional_pocket": ["pocket_loot_a", "pocket_shrine_b"],
}


static func from_json_file(path: String) -> MapGenerationConfig:
	var config := MapGenerationConfig.new()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("MapGenerationConfig missing config file: %s" % path)
		return config
	var text := file.get_as_text()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("MapGenerationConfig invalid JSON dictionary: %s" % path)
		return config
	config.apply_dictionary(parsed)
	return config


func apply_dictionary(data: Dictionary) -> void:
	map_id = str(data.get("map_id", map_id))
	map_name = str(data.get("map_name", map_name))
	map_size = _read_vector2(data.get("map_size", {}), map_size)
	map_offset = _read_vector2(data.get("map_offset", {}), map_offset)

	var generator: Dictionary = data.get("generator", {})
	map_margin = float(generator.get("map_margin", map_margin))
	corridor_width = float(generator.get("corridor_width", corridor_width))
	main_path_min_zones = int(generator.get("main_path_min_zones", main_path_min_zones))
	main_path_max_zones = int(generator.get("main_path_max_zones", main_path_max_zones))
	optional_pocket_chance = float(generator.get("optional_pocket_chance", optional_pocket_chance))
	branch_distance_range = _read_min_max(generator.get("branch_distance_range", {}), branch_distance_range)
	branch_y_offset_range = _read_min_max(generator.get("branch_y_offset_range", {}), branch_y_offset_range)
	route_x_jitter = float(generator.get("route_x_jitter", route_x_jitter))
	zone_padding = float(generator.get("zone_padding", zone_padding))

	var zone_types: Dictionary = data.get("zone_types", {})
	for zone_type in zone_types.keys():
		var definition: Dictionary = zone_types[zone_type]
		var key := str(zone_type)
		zone_labels[key] = str(definition.get("label", zone_labels.get(key, key)))
		if definition.has("base_size"):
			zone_base_sizes[key] = _read_size(definition.get("base_size", {}), zone_base_sizes.get(key, Vector2(560.0, 400.0)))
		if definition.has("templates"):
			template_variations[key] = Array(definition.get("templates", [])).duplicate()


func get_template_id(zone_type: String, rng: RandomNumberGenerator) -> String:
	var choices: Array = template_variations.get(zone_type, ["default"])
	if choices.is_empty():
		return "default"
	return str(choices[rng.randi_range(0, choices.size() - 1)])


func get_zone_label(zone_type: String) -> String:
	return str(zone_labels.get(zone_type, zone_type))


func get_zone_size(zone_type: String, rng: RandomNumberGenerator) -> Vector2:
	var base_size: Vector2 = zone_base_sizes.get(zone_type, Vector2(560.0, 400.0))
	var width := base_size.x + rng.randf_range(-56.0, 72.0)
	var height := base_size.y + rng.randf_range(-42.0, 54.0)
	return Vector2(width, height)


func _read_vector2(value, fallback: Vector2) -> Vector2:
	if typeof(value) != TYPE_DICTIONARY:
		return fallback
	var data: Dictionary = value
	return Vector2(float(data.get("x", fallback.x)), float(data.get("y", fallback.y)))


func _read_size(value, fallback: Vector2) -> Vector2:
	if typeof(value) != TYPE_DICTIONARY:
		return fallback
	var data: Dictionary = value
	return Vector2(float(data.get("w", fallback.x)), float(data.get("h", fallback.y)))


func _read_min_max(value, fallback: Vector2) -> Vector2:
	if typeof(value) != TYPE_DICTIONARY:
		return fallback
	var data: Dictionary = value
	return Vector2(float(data.get("min", fallback.x)), float(data.get("max", fallback.y)))
