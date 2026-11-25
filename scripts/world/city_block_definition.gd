class_name CityBlockDefinition
extends Resource

@export var block_id: String = ""
@export var district_id: String = ""
@export var building_positions: PackedVector3Array = PackedVector3Array()
@export var footprint: Vector2 = Vector2(14.0, 14.0)
@export_range(7.0, 48.0, 0.5) var minimum_height: float = 8.0
@export_range(7.0, 48.0, 0.5) var maximum_height: float = 14.0
@export var facade_palette: Array[Color] = []
@export var random_seed: int = 1

func is_valid_definition() -> bool:
	if block_id.is_empty() or block_id != block_id.strip_edges():
		return false
	if district_id.is_empty() or district_id != district_id.strip_edges():
		return false
	if building_positions.is_empty() or building_positions.size() > 64:
		return false
	if not is_finite(footprint.x) or not is_finite(footprint.y):
		return false
	if footprint.x < 6.0 or footprint.y < 6.0:
		return false
	if not is_finite(minimum_height) or not is_finite(maximum_height):
		return false
	if minimum_height < 7.0 or maximum_height > 48.0 or minimum_height > maximum_height:
		return false
	if facade_palette.is_empty() or facade_palette.size() > 16:
		return false
	for position: Vector3 in building_positions:
		if not is_finite(position.x) or not is_finite(position.y) or not is_finite(position.z):
			return false
	for color: Color in facade_palette:
		if not is_finite(color.r) or not is_finite(color.g) or not is_finite(color.b) or not is_finite(color.a):
			return false
	return true
