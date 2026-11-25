class_name CityManager
extends Node3D

signal district_changed(previous_id: String, current_id: String, display_name: String)

const DISTRICTS: Array[CityDistrictDefinition] = [
	preload("res://data/city/districts/police_headquarters.tres"),
	preload("res://data/city/districts/public_park.tres"),
	preload("res://data/city/districts/civic_services.tres"),
	preload("res://data/city/districts/downtown.tres"),
	preload("res://data/city/districts/residential.tres"),
	preload("res://data/city/districts/commercial.tres"),
	preload("res://data/city/districts/industrial.tres")
]
var _current_id := ""

func get_district_count() -> int:
	return DISTRICTS.size()

func get_district_at(position: Vector3) -> CityDistrictDefinition:
	for district in DISTRICTS:
		if district.contains_world_position(position):
			return district
	return null

func get_district_id_at(position: Vector3) -> String:
	var district := get_district_at(position)
	return district.district_id if district != null else ""

func get_district_label_at(position: Vector3, language_code: String) -> String:
	var district := get_district_at(position)
	if district == null:
		return "North District" if language_code == "en" else "ناحیه شمالی"
	return district.display_name_for_language(language_code)

func update_player_position(position: Vector3, language_code: String) -> void:
	var district := get_district_at(position)
	var next_id := district.district_id if district != null else "north_district"
	if next_id == _current_id:
		return
	var previous_id := _current_id
	_current_id = next_id
	district_changed.emit(previous_id, next_id, get_district_label_at(position, language_code))
