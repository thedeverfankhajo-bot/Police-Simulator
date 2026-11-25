class_name CityDistrictDefinition
extends Resource

@export var district_id: String = ""
@export var display_name_fa: String = ""
@export var display_name_en: String = ""
@export var center: Vector3 = Vector3.ZERO
@export var half_extents: Vector2 = Vector2(20.0, 20.0)
@export_range(0, 100, 1) var priority: int = 0

func contains_world_position(position: Vector3) -> bool:
	return absf(position.x-center.x) <= half_extents.x and absf(position.z-center.z) <= half_extents.y

func display_name_for_language(language_code: String) -> String:
	return display_name_en if language_code == "en" else display_name_fa
