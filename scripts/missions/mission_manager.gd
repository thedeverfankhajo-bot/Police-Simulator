extends Node

signal mission_changed(mission: Dictionary)
signal mission_completed(mission: Dictionary, report: Dictionary)

var catalogue: Array[Dictionary] = []
var next_index: int = 0
var active_mission: Dictionary = {}
var active: bool = false

func _ready() -> void:
	_load_catalogue()

func _load_catalogue() -> void:
	catalogue.clear()
	var file := FileAccess.open("res://data/missions/missions.json", FileAccess.READ)
	if file == null:
		push_error("Mission data could not be opened.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		push_error("Mission catalogue is invalid.")
		return
	if int(parsed.get("schema_version", -1)) != 1:
		push_error("Unsupported mission catalogue schema version.")
		return
	var entries: Variant = parsed.get("missions", [])
	if not entries is Array:
		push_error("Mission catalogue entries must be an Array.")
		return
	var seen_ids: Dictionary = {}
	for item: Variant in entries:
		if not item is Dictionary:
			push_warning("Skipping a mission entry that is not a Dictionary.")
			continue
		var mission: Dictionary = item
		if not is_valid_mission_data(mission):
			push_warning("Skipping invalid mission entry: %s" % str(mission.get("id", "<missing id>")))
			continue
		var mission_id := str(mission.get("id", "")).strip_edges()
		if seen_ids.has(mission_id):
			push_warning("Skipping duplicate mission id: %s" % mission_id)
			continue
		seen_ids[mission_id] = true
		catalogue.append(mission.duplicate(true))
	if catalogue.is_empty():
		push_warning("Mission catalogue contains no valid entries.")

func is_valid_mission_data(mission: Dictionary) -> bool:
	var id_value: Variant = mission.get("id", null)
	var type_value: Variant = mission.get("type", null)
	if not id_value is String or not type_value is String:
		return false
	if id_value.strip_edges().is_empty() or id_value != id_value.strip_edges():
		return false
	if type_value.strip_edges().is_empty() or type_value != type_value.strip_edges():
		return false

	var required_text_fields: Array[String] = [
		"title_fa",
		"title_en",
		"description_fa",
		"description_en",
		"priority",
		"target_label"
	]
	for field_name: String in required_text_fields:
		var field_value: Variant = mission.get(field_name, null)
		if not field_value is String or field_value.strip_edges().is_empty():
			return false

	var location: Variant = mission.get("location", null)
	if not location is Array or location.size() != 3:
		return false
	for coordinate: Variant in location:
		if not (coordinate is int or coordinate is float):
			return false
		if not is_finite(float(coordinate)):
			return false

	var reward_value: Variant = mission.get("reward", null)
	if not (reward_value is int or reward_value is float):
		return false
	if not is_finite(float(reward_value)) or float(reward_value) < 0.0:
		return false

	var trust_value: Variant = mission.get("trust", null)
	if not (trust_value is int or trust_value is float):
		return false
	if not is_finite(float(trust_value)) or float(trust_value) < -100.0 or float(trust_value) > 100.0:
		return false
	return true

func get_next_mission() -> Dictionary:
	if next_index >= catalogue.size():
		return {}
	return catalogue[next_index].duplicate(true)

func accept_next_mission() -> bool:
	if active:
		return false
	var mission := get_next_mission()
	if mission.is_empty():
		return false
	next_index += 1
	active_mission = mission
	active_mission["accepted_at"] = Time.get_datetime_string_from_system()
	active_mission["status"] = "active"
	active = true
	GameState.current_mission = active_mission.duplicate(true)
	GameState.mission_index = next_index
	mission_changed.emit(active_mission)
	return true

func is_near_objective(position: Vector3, radius: float = 4.0) -> bool:
	if not active:
		return false
	var location: Array = active_mission.get("location", [0.0, 0.0, 0.0])
	var target := Vector3(float(location[0]), float(location[1]), float(location[2]))
	return Vector2(position.x - target.x, position.z - target.z).length() <= radius

func complete_active_mission(position: Vector3) -> Dictionary:
	if not active or not is_near_objective(position):
		return {}
	active_mission["status"] = "completed"
	active_mission["completed_at"] = Time.get_datetime_string_from_system()
	var report := {
		"case_id": "CITY-%06d" % (GameState.reports.size() + 1),
		"event_type": str(active_mission.get("type", "city_service")),
		"location": active_mission.get("location", []),
		"description": str(active_mission.get("description_fa", "")),
		"actions": ["مراجعه به محل", "تعامل محترمانه", "ثبت نتیجه"],
		"result": "resolved",
		"mission_id": active_mission.get("id", ""),
		"timestamp": active_mission.get("completed_at", "")
	}
	GameState.add_report(report)
	GameState.add_mission_result(int(active_mission.get("reward", 100)), int(active_mission.get("trust", 2)))
	active = false
	GameState.current_mission.clear()
	var finished := active_mission.duplicate(true)
	mission_completed.emit(finished, report)
	active_mission.clear()
	return report
