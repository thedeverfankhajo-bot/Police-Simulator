class_name CityBlockManager
extends Node3D

const BUILDING_SCENE: PackedScene = preload("res://scenes/city/city_building.tscn")

@export var block_catalog: CityBlockCatalog

var _block_count: int = 0
var _building_count: int = 0
var _district_building_counts: Dictionary = {}

func _ready() -> void:
	_build_catalog()

func _build_catalog() -> void:
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
		_spawn_block(definition)

func _spawn_block(definition: CityBlockDefinition) -> void:
	var generator := RandomNumberGenerator.new()
	generator.seed = definition.random_seed
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
		add_child(building)
		spawned_in_block += 1
		_building_count += 1
	if spawned_in_block > 0:
		_block_count += 1
		_district_building_counts[definition.district_id] = (
			int(_district_building_counts.get(definition.district_id, 0)) + spawned_in_block
		)

func get_block_count() -> int:
	return _block_count

func get_building_count() -> int:
	return _building_count

func get_district_building_count(district_id: String) -> int:
	return int(_district_building_counts.get(district_id, 0))
