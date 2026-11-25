class_name CityBlockManager
extends Node3D

const BUILDING_SCENE: PackedScene = preload("res://scenes/city/city_building.tscn")

@export var block_catalog: CityBlockCatalog
@export_range(32.0, 512.0, 1.0) var load_radius: float = 112.0
@export_range(32.0, 640.0, 1.0) var unload_radius: float = 140.0

var _definitions: Array[CityBlockDefinition] = []
var _loaded_blocks: Dictionary = {}
var _building_count: int = 0
var _district_building_counts: Dictionary = {}
var _catalog_ready: bool = false
var _has_stream_position: bool = false
var _last_stream_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	if unload_radius <= load_radius:
		push_warning("City block unload_radius must exceed load_radius; applying a safe margin.")
		unload_radius = load_radius + 16.0
	_load_catalog()

func _load_catalog() -> void:
	_definitions.clear()
	_loaded_blocks.clear()
	_building_count = 0
	_district_building_counts.clear()
	if block_catalog == null:
		push_error("City block catalog is not assigned.")
		return

	var seen_block_ids: Dictionary = {}
	for definition: CityBlockDefinition in block_catalog.blocks:
		if definition == null or not definition.is_valid_definition():
			push_warning("Skipping an invalid city block definition.")
			continue
		if seen_block_ids.has(definition.block_id):
			push_warning("Skipping duplicate city block id: %s" % definition.block_id)
			continue
		seen_block_ids[definition.block_id] = true
		_definitions.append(definition)

	if _definitions.is_empty():
		push_error("City block catalog contains no valid definitions.")
		return
	_catalog_ready = true

func update_player_position(position: Vector3) -> void:
	if not _catalog_ready:
		return
	if not is_finite(position.x) or not is_finite(position.y) or not is_finite(position.z):
		push_warning("Ignoring a non-finite player position for city streaming.")
		return

	var player_xz := Vector2(position.x, position.z)
	if _has_stream_position and player_xz.distance_squared_to(_last_stream_position) < 16.0:
		return
	_has_stream_position = true
	_last_stream_position = player_xz

	for definition: CityBlockDefinition in _definitions:
		var distance_to_block := _distance_to_block(definition, player_xz)
		if _loaded_blocks.has(definition.block_id):
			if distance_to_block > unload_radius:
				_unload_block(definition.block_id)
		elif distance_to_block <= load_radius:
			_spawn_block(definition)

func _distance_to_block(definition: CityBlockDefinition, player_xz: Vector2) -> float:
	var nearest_distance := INF
	var half_footprint := definition.footprint * 0.5
	for building_position: Vector3 in definition.building_positions:
		var building_xz := Vector2(building_position.x, building_position.z)
		var offset := player_xz - building_xz
		var outside_x := maxf(absf(offset.x) - half_footprint.x, 0.0)
		var outside_z := maxf(absf(offset.y) - half_footprint.y, 0.0)
		var distance_to_footprint := Vector2(outside_x, outside_z).length()
		nearest_distance = minf(nearest_distance, distance_to_footprint)
	return nearest_distance

func _spawn_block(definition: CityBlockDefinition) -> void:
	if _loaded_blocks.has(definition.block_id):
		return

	var generator := RandomNumberGenerator.new()
	generator.seed = definition.random_seed
	var block_root := Node3D.new()
	block_root.name = definition.block_id
	var spawned_in_block := 0

	for index in range(definition.building_positions.size()):
		var building := BUILDING_SCENE.instantiate() as CityBuilding
		if building == null:
			push_error("City building scene could not be instantiated for block %s." % definition.block_id)
			continue
		var height := generator.randf_range(definition.minimum_height, definition.maximum_height)
		var palette_index := generator.randi_range(0, definition.facade_palette.size() - 1)
		var variant := generator.randi_range(0, 2)
		building.name = "%s_Building_%02d" % [definition.block_id, index + 1]
		building.position = definition.building_positions[index]
		building.configure(
			Vector3(definition.footprint.x, height, definition.footprint.y),
			definition.facade_palette[palette_index],
			definition.district_id,
			variant
		)
		block_root.add_child(building)
		spawned_in_block += 1

	if spawned_in_block == 0:
		block_root.free()
		return

	add_child(block_root)
	_loaded_blocks[definition.block_id] = {
		"root": block_root,
		"district_id": definition.district_id,
		"building_count": spawned_in_block
	}
	_building_count += spawned_in_block
	_district_building_counts[definition.district_id] = (
		int(_district_building_counts.get(definition.district_id, 0)) + spawned_in_block
	)

func _unload_block(block_id: String) -> void:
	if not _loaded_blocks.has(block_id):
		return
	var entry: Dictionary = _loaded_blocks[block_id]
	var block_root := entry.get("root") as Node3D
	var district_id := str(entry.get("district_id", ""))
	var removed_buildings := int(entry.get("building_count", 0))
	if is_instance_valid(block_root):
		block_root.queue_free()
	_loaded_blocks.erase(block_id)
	_building_count = maxi(0, _building_count - removed_buildings)
	var remaining_district_count := int(_district_building_counts.get(district_id, 0)) - removed_buildings
	if remaining_district_count > 0:
		_district_building_counts[district_id] = remaining_district_count
	else:
		_district_building_counts.erase(district_id)

func get_definition_count() -> int:
	return _definitions.size()

func get_block_count() -> int:
	return _loaded_blocks.size()

func get_building_count() -> int:
	return _building_count

func get_district_building_count(district_id: String) -> int:
	return int(_district_building_counts.get(district_id, 0))

func is_block_loaded(block_id: String) -> bool:
	return _loaded_blocks.has(block_id)
