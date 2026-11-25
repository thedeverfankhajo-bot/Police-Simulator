class_name CityManager
extends Node3D

signal district_changed(previous_id: String, current_id: String, display_name: String)

@export var district_catalog: CityDistrictCatalog

var _districts: Array[CityDistrictDefinition] = []
var _current_id := ""

func _ready() -> void:
	_load_districts()

func _load_districts() -> void:
	_districts.clear()
	if district_catalog == null:
		push_error("City district catalog is not assigned.")
		return

	var seen_ids: Dictionary = {}
	for candidate in district_catalog.districts:
		var district := candidate as CityDistrictDefinition
		if district == null:
			push_warning("Skipping a null or incompatible city district resource.")
			continue
		if not district.is_valid_definition():
			push_warning("Skipping invalid city district resource: %s" % district.district_id)
			continue
		if seen_ids.has(district.district_id):
			push_warning("Skipping duplicate city district id: %s" % district.district_id)
			continue

		seen_ids[district.district_id] = true
		_districts.append(district)

	_districts.sort_custom(_district_precedes)
	if _districts.is_empty():
		push_error("City district catalog contains no valid districts.")

func _district_precedes(a: CityDistrictDefinition, b: CityDistrictDefinition) -> bool:
	if a.priority != b.priority:
		return a.priority > b.priority
	return a.district_id < b.district_id

func get_district_count() -> int:
	return _districts.size()

func get_district_at(position: Vector3) -> CityDistrictDefinition:
	for district in _districts:
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
	var label := district.display_name_for_language(language_code) if district != null else ("North District" if language_code == "en" else "ناحیه شمالی")
	district_changed.emit(previous_id, next_id, label)
